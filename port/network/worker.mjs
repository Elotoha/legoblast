const seats = 4;
const grace = 25_000;
const invitationLifetime = 120_000;
const keyPattern = /^[0-9a-f-]{36}$/;
const codePattern = /^[A-Z0-9]{6}$/;

export default {
    async fetch(request, env) {
        const path = new URL(request.url).pathname;
        if (path === "/") return new Response("LegoBlast réseau v1");
        if (path !== "/v1/socket") return new Response("Not found", { status: 404 });
        if (request.headers.get("Upgrade")?.toLowerCase() !== "websocket")
            return new Response("WebSocket required", { status: 426 });
        return env.LOBBY.get(env.LOBBY.idFromName("public-v1")).fetch(request);
    },
};

export class LegoBlastLobby {
    constructor(ctx) {
        this.ctx = ctx;
        this.rooms = {};
        ctx.blockConcurrencyWhile(async () => {
            this.rooms = (await ctx.storage.get("rooms")) ?? {};
        });
    }

    sockets(key) {
        return this.ctx.getWebSockets().filter(ws => {
            const member = ws.deserializeAttachment();
            return member && (!key || member.key === key);
        });
    }

    send(ws, message) {
        try { ws.send(message); } catch { /* The close handler will handle a dropped peer. */ }
    }

    sendMember(key, message) {
        for (const ws of this.sockets(key)) this.send(ws, message);
    }

    current(key) {
        return Object.values(this.rooms).find(room => room.places.some(place => place.key === key));
    }

    publicState(room) {
        for (const place of room.places.filter(place => place.kind === "H")) {
            const index = room.places.indexOf(place);
            this.sendMember(place.key, `ROOM ${room.code} ${place.key === room.host ? 1 : 0} ${index} ${room.places.map(p => p.kind).join("")} ${room.started ? 1 : 0}`);
        }
    }

    async save() {
        await this.ctx.storage.put("rooms", this.rooms);
        const expiries = Object.values(this.rooms).flatMap(room => [
            ...(room.started ? [] : [room.expireAt]), ...Object.values(room.offline),
        ]);
        if (expiries.length) await this.ctx.storage.setAlarm(Math.min(...expiries));
    }

    async fetch() {
        const [client, server] = Object.values(new WebSocketPair());
        this.ctx.acceptWebSocket(server);
        return new Response(null, { status: 101, webSocket: client });
    }

    async hello(ws, oldKey) {
        const key = keyPattern.test(oldKey ?? "") ? oldKey : crypto.randomUUID();
        const room = this.current(key);
        for (const other of this.sockets(key)) {
            other.serializeAttachment(null);
            other.close(1000, "Connexion remplacee");
        }
        ws.serializeAttachment({ key });
        this.send(ws, `HELLO ${key}`);
        if (room) {
            delete room.offline[key];
            if (room.started) { await this.save(); this.publicState(room); }
            else await this.ready(room);
            if (room.started) this.sendMember(room.host, `RESET ${room.places.findIndex(p => p.key === key)}`);
        } else {
            this.send(ws, "LOBBY");
            for (const offer of Object.values(this.rooms))
                if (!offer.started && offer.expireAt > Date.now())
                    this.send(ws, `INVITE ${offer.code}`);
        }
    }

    async webSocketMessage(ws, message) {
        const key = ws.deserializeAttachment()?.key;
        if (typeof message === "string" && message.length <= 256 && message.startsWith("HELLO ")) {
            if (!key) await this.hello(ws, message.slice(6));
            return;
        }
        if (!key) return ws.close(1008, "Identification requise");
        let room = this.current(key);
        if (message instanceof ArrayBuffer) {
            if (room?.started && room.host === key && message.byteLength >= 8 && message.byteLength <= 300_000)
                for (const place of room.places)
                    if (place.kind === "H" && place.key !== key) this.sendMember(place.key, message);
            return;
        }
        if (typeof message !== "string" || message.length > 96) return;
        const [command, arg, extra] = message.split(" ");
        if (extra !== undefined) return;
        if (command === "CREATE" && !room) {
            if (Object.keys(this.rooms).length >= 32) return this.send(ws, "ERROR SALONS PLEINS");
            const code = crypto.randomUUID().replaceAll("-", "").slice(0, 6).toUpperCase();
            if (this.rooms[code]) return this.send(ws, "ERROR REESSAYER");
            room = this.rooms[code] = {
                code, host: key, places: [{ key, kind: "H" }], started: false,
                expireAt: Date.now() + invitationLifetime, offline: {},
            };
            await this.save();
            this.publicState(room);
            for (const client of this.sockets()) {
                const other = client.deserializeAttachment().key;
                if (other !== key && !this.current(other)) this.send(client, `INVITE ${code}`);
            }
        } else if (command === "JOIN" && !room && codePattern.test(arg ?? "")) {
            room = this.rooms[arg];
            if (!room || room.started || room.places.length >= seats || room.expireAt <= Date.now())
                return this.send(ws, "ERROR SALON FERME");
            room.places.push({ key, kind: "H" });
            await this.ready(room);
        } else if (command === "ADD" && room && !room.started && room.places.length < seats && ["L", "M"].includes(arg)) {
            room.places.push({ key, kind: arg });
            await this.ready(room);
        } else if (command === "REMOVE" && room && !room.started) {
            const index = room.places.findLastIndex(place => place.key === key && place.kind !== "H");
            if (index >= 0) {
                room.places.splice(index, 1);
                await this.save();
                this.publicState(room);
            }
        } else if (command === "LEAVE" && room) {
            await this.leave(room, key);
        } else if (command === "I" && room?.started && /^(?:[0-9]|[12][0-9]|3[01])$/.test(arg ?? "")) {
            const index = room.places.findIndex(p => p.key === key && p.kind === "H");
            this.sendMember(room.host, `I ${index} ${arg}`);
        } else if (command === "C" && room?.started &&
                   /^(?:PREV|NEXT|REPLAY|PAUSE|PODIUM|SKIP|M[0-7])$/.test(arg ?? "")) {
            this.sendMember(room.host, `C ${arg}`);
        }
    }

    async ready(room) {
        room.started = room.places.length === seats && !Object.keys(room.offline).length;
        await this.save();
        this.publicState(room);
        if (room.started) this.removeOffer(room.code);
    }

    removeOffer(code) {
        for (const ws of this.sockets()) this.send(ws, `CANCEL ${code}`);
    }

    async leave(room, key) {
        if (room.host === key || room.started) {
            delete this.rooms[room.code];
            this.removeOffer(room.code);
            for (const place of room.places.filter(p => p.kind === "H"))
                this.sendMember(place.key, "END SALON FERME");
        } else {
            room.places = room.places.filter(place => place.key !== key);
            delete room.offline[key];
            this.sendMember(key, "END SALON QUITTE");
            this.publicState(room);
        }
        await this.save();
    }

    async webSocketClose(ws) {
        const key = ws.deserializeAttachment()?.key;
        if (!key) return;
        ws.serializeAttachment(null);
        if (this.sockets(key).length) return;
        const room = this.current(key);
        if (!room) return;
        room.offline[key] = Date.now() + grace;
        if (room.started) {
            const index = room.places.findIndex(p => p.key === key && p.kind === "H");
            this.sendMember(room.host, `I ${index} 0`);
        }
        await this.save();
    }

    async webSocketError(ws) { await this.webSocketClose(ws); }

    async alarm() {
        const now = Date.now();
        for (const room of Object.values(this.rooms)) {
            if (!room.started && room.expireAt <= now) {
                await this.leave(room, room.host);
                continue;
            }
            for (const [key, deadline] of Object.entries(room.offline)) {
                if (deadline <= now && this.rooms[room.code]) await this.leave(room, key);
            }
        }
        await this.save();
    }
}
