import assert from "node:assert/strict";

const url = process.argv[2];
if (!url) throw new Error("Usage: node check.mjs wss://HOST/v1/socket");
const sockets = [];

async function peer(token = "-") {
    const ws = new WebSocket(url);
    ws.binaryType = "arraybuffer";
    sockets.push(ws);
    const messages = [];
    ws.addEventListener("message", event => messages.push(event.data));
    await new Promise((resolve, reject) => {
        const timer = setTimeout(() => reject(new Error("WebSocket handshake timed out")), 9000);
        ws.addEventListener("open", () => { clearTimeout(timer); resolve(); }, { once: true });
        ws.addEventListener("error", event => { clearTimeout(timer); reject(event.error ?? new Error("WebSocket error")); }, { once: true });
    });
    const next = async predicate => {
        for (let i = 0; i < 200; ++i) {
            const index = messages.findIndex(predicate);
            if (index >= 0) return messages.splice(index, 1)[0];
            await new Promise(resolve => setTimeout(resolve, 40));
        }
        throw new Error("No matching message: " + messages.map(s => typeof s === "string" ? s.split(" ")[0] : "binary").join(","));
    };
    ws.send(`HELLO ${token}`);
    const hello = await next(s => typeof s === "string" && s.startsWith("HELLO "));
    return { ws, next, token: hello.split(" ")[1] };
}

const starts = prefix => s => typeof s === "string" && s.startsWith(prefix);
let host;
try {
    host = await peer();
    let guest = await peer();
    const watcher = await peer();
    host.ws.send("CREATE");
    const first = await host.next(starts("ROOM "));
    const code = first.split(" ")[1];
    assert.match(first, /^ROOM [A-Z0-9]{6} 1 0 H 0$/);
    assert.equal(await guest.next(starts("INVITE " + code)), "INVITE " + code);
    assert.equal(await watcher.next(starts("INVITE " + code)), "INVITE " + code);
    guest.ws.send("JOIN " + code);
    await guest.next(starts(`ROOM ${code} 0 1 HH 0`));
    guest.ws.send("ADD M");
    await host.next(starts(`ROOM ${code} 1 0 HHM 0`));
    host.ws.send("ADD L");
    await host.next(starts(`ROOM ${code} 1 0 HHML 1`));
    await guest.next(starts(`ROOM ${code} 0 1 HHML 1`));
    await watcher.next(starts("CANCEL " + code));
    watcher.ws.send("JOIN " + code);
    await watcher.next(starts("ERROR SALON FERME"));

    guest.ws.send("I 18");
    assert.equal(await host.next(starts("I 1 ")), "I 1 18");
    guest.ws.send("C NEXT");
    assert.equal(await host.next(starts("C ")), "C NEXT");
    guest.ws.send("C M2");
    assert.equal(await host.next(starts("C ")), "C M2");
    const frame = Uint8Array.from([76, 66, 1, 0, 1, 0, 0, 0]);
    host.ws.send(frame);
    const received = await guest.next(packet => packet instanceof ArrayBuffer);
    assert.deepEqual(new Uint8Array(received), frame);

    guest.ws.close();
    assert.equal(await host.next(starts("I 1 0")), "I 1 0");
    guest = await peer(guest.token);
    await guest.next(starts(`ROOM ${code} 0 1 HHML 1`));
    await host.next(starts("RESET 1"));
    host.ws.send(frame);
    assert.deepEqual(new Uint8Array(await guest.next(packet => packet instanceof ArrayBuffer)), frame);
    console.log("Invitations, quatre places, commandes, images et reconnexion vérifiées.");
} finally {
    if (host?.ws.readyState === WebSocket.OPEN) {
        host.ws.send("LEAVE");
        await host.next(starts("END ")).catch(() => {});
    }
    for (const ws of sockets) ws.close();
}
