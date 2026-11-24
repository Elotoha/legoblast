"""Desktop LegoBlast client with Pygame input, window and audio."""

import argparse
import os
from pathlib import Path
import sys
from tempfile import TemporaryDirectory

os.environ.setdefault("PYGAME_HIDE_SUPPORT_PROMPT", "1")
import pygame

from audio import Audio
from engine import Engine, find_library

WIDTH, HEIGHT = 320, 258
MENU, LOCAL, HOST, GUEST = range(4)
MENU_KEYS = {pygame.K_UP: 0, pygame.K_DOWN: 1, pygame.K_LEFT: 2, pygame.K_RIGHT: 3,
             pygame.K_RETURN: 4, pygame.K_KP_ENTER: 4, pygame.K_RALT: 4, pygame.K_ESCAPE: 5}
SHORTCUTS = {pygame.K_F1: "PREV", pygame.K_F2: "NEXT", pygame.K_HOME: "REPLAY", pygame.K_p: "PAUSE",
             pygame.K_BACKSLASH: "PODIUM", pygame.K_ESCAPE: "BACK",
             **{pygame.K_F3 + i: f"M{(i + 1) % 8}" for i in range(8)}}
VOLUMES = {pygame.K_MINUS: (0, -1), pygame.K_KP_MINUS: (0, -1), pygame.K_EQUALS: (0, 1),
           pygame.K_KP_PLUS: (0, 1), pygame.K_KP_DIVIDE: (1, -1), pygame.K_KP_MULTIPLY: (1, 1)}
NETWORK_BADGE = pygame.Rect(235, 54, 67, 28)
PANEL = pygame.Rect(14, 40, 292, 176)


def decode(value):
    return value.decode("utf-8", errors="replace")


def inputs_for(keys, joysticks, shared):
    def pack(left, right, up, down, fire):
        return left | right << 1 | up << 2 | down << 3 | fire << 4

    def key(*codes):
        return any(code in keys for code in codes)

    inputs = [0] * 8
    for index, pad in enumerate(list(joysticks.values())[:4]):
        try:
            x, y = (pad.get_axis(0), pad.get_axis(1)) if pad.get_numaxes() >= 2 else (0, 0)
            tx, ty = pad.get_hat(0) if pad.get_numhats() else (0, 0)
            inputs[index] = pack(x < -0.42 or tx < 0, x > 0.42 or tx > 0, y < -0.42 or ty > 0,
                                 y > 0.42 or ty < 0, bool(pad.get_numbuttons() and pad.get_button(0)))
        except pygame.error:
            continue
    inputs[4] = pack(key(pygame.K_LEFT), key(pygame.K_RIGHT), key(pygame.K_UP), key(pygame.K_DOWN),
                     not shared and key(pygame.K_RETURN, pygame.K_KP_ENTER, pygame.K_RALT))
    inputs[5] = pack(key(pygame.K_z, pygame.K_w), key(pygame.K_r), key(pygame.K_3, pygame.K_4),
                     key(pygame.K_e), shared and key(pygame.K_SPACE))
    inputs[6] = pack(key(pygame.K_KP7), key(pygame.K_KP9), key(pygame.K_KP5), key(pygame.K_KP8),
                     shared and key(pygame.K_RIGHT))
    inputs[7] = int(key(pygame.K_BACKSPACE)) << 4
    return inputs


class NetworkPanel:
    def __init__(self, game):
        self.game = game
        self.open = False
        self.selection = 0

    def visible(self, state):
        return self.open or bool(state.offer) or bool(state.room and state.mode < HOST)

    def buttons(self, state):
        if state.offer and not state.room:
            return [(pygame.Rect(30, 140, 124, 28), "Rejoindre", "JOIN"),
                    (pygame.Rect(166, 140, 124, 28), "Refuser", "DECLINE")]
        if state.room and state.mode < HOST:
            return [(pygame.Rect(30, 136, 78, 27), "+ Lia", "ADD L"),
                    (pygame.Rect(120, 136, 78, 27), "+ Micro", "ADD M"),
                    (pygame.Rect(210, 136, 80, 27), "Retirer bot", "REMOVE"),
                    (pygame.Rect(30, 172, 128, 27), "Quitter le salon", "LEAVE")]
        if state.mode >= HOST:
            return [(pygame.Rect(30, 140, 124, 28), "Quitter", "LEAVE"),
                    (pygame.Rect(166, 140, 124, 28), "Retour", "BACK")]
        choices = [(pygame.Rect(30, 94, 260, 27), "Inviter", "CREATE")] if state.connected else []
        choices.append((pygame.Rect(30, 129, 260, 27),
                        "Couper les invitations" if state.networkEnabled else "Activer les invitations", "TOGGLE"))
        choices.append((pygame.Rect(30, 164, 260, 27), "Retour", "BACK"))
        return choices

    def action(self, command):
        self.selection = 0
        if command in ("BACK", "DECLINE", "LEAVE"):
            self.open = False
        if command != "BACK":
            self.game.call("network", command.encode())

    def handle(self, event, state, position):
        if event.type == pygame.KEYDOWN and event.key == pygame.K_F11:
            self.open = not self.open
            self.selection = 0
            return True
        if not self.visible(state):
            if state.mode == MENU and position and NETWORK_BADGE.collidepoint(position):
                self.open = True
                self.selection = 0
                return True
            return False
        buttons = self.buttons(state)
        if position:
            for box, _, command in buttons:
                if box.collidepoint(position):
                    self.action(command)
                    break
        elif event.type == pygame.KEYDOWN:
            if event.key in (pygame.K_UP, pygame.K_DOWN):
                self.selection = (self.selection + (1 if event.key == pygame.K_DOWN else -1)) % len(buttons)
            elif event.key in (pygame.K_RETURN, pygame.K_KP_ENTER):
                self.action(buttons[self.selection % len(buttons)][2])
            elif event.key == pygame.K_ESCAPE:
                self.action("DECLINE" if state.offer else "LEAVE" if state.room and state.mode < HOST else "BACK")
        return True

    def draw(self, canvas, state, font):
        def line(value, x, y):
            canvas.blit(font.render(value, False, (224, 233, 245)), (x, y))

        if not self.visible(state):
            if state.mode == MENU:
                pygame.draw.rect(canvas, (35, 50, 70), NETWORK_BADGE)
                pygame.draw.rect(canvas, (163, 191, 215), NETWORK_BADGE, 1)
                pygame.draw.line(canvas, (240, 205, 51), (253, 60), (283, 60))
                for x in (250, 280):
                    pygame.draw.rect(canvas, (240, 205, 51), (x, 57, 6, 6))
                    pygame.draw.rect(canvas, (240, 205, 51), (x + 1, 56, 4, 1))
                line("RÉSEAU", 244, 65)
            return
        pygame.draw.rect(canvas, (19, 29, 44), PANEL)
        pygame.draw.rect(canvas, (178, 210, 228), PANEL, 1)
        if state.offer and not state.room:
            line("Invitation réseau", 30, 55)
            line(f"Rejoindre le salon {decode(state.offer)} ?", 30, 86)
        elif state.room:
            roster = decode(state.roster).ljust(4, "-")
            line(f"Salon {decode(state.room)}   {len(state.roster)}/4", 30, 55)
            for i, kind in enumerate(roster):
                label = "Moi" if i == state.seat else {"H": "Joueur", "L": "Lia", "M": "Micro", "-": "Libre"}[kind]
                line(f"{i + 1}  {label}", 30 + (i % 2) * 132, 81 + (i // 2) * 22)
        else:
            line("Réseau", 30, 52)
            line(decode(state.notice) or ("Invitations actives" if state.connected else "Jeu local"), 30, 72)
        buttons = self.buttons(state)
        for index, (box, caption, _) in enumerate(buttons):
            pygame.draw.rect(canvas, (61, 82, 111) if index == self.selection % len(buttons) else (37, 52, 74), box)
            pygame.draw.rect(canvas, (146, 181, 200), box, 1)
            label = font.render(caption, False, (230, 239, 251))
            canvas.blit(label, label.get_rect(center=box.center))


def fit(window):
    w, h = window.get_size()
    factor = min(w / WIDTH, h / HEIGHT)
    if factor >= 1:
        factor = int(factor)
    result = pygame.Rect(0, 0, max(1, int(WIDTH * factor)), max(1, int(HEIGHT * factor)))
    result.center = window.get_rect().center
    return result


def draw(window, canvas, game, state, scene, ticks, panel, font):
    image, size = game.frame(scene, ticks)
    picture = pygame.image.frombuffer(image, size, "RGB")
    if size[0] != WIDTH:
        picture = pygame.transform.scale(picture, (WIDTH, size[1]))
    canvas.fill((14, 19, 29))
    canvas.blit(picture, (0, 0))
    if state.message and state.mode and not state.flags & 4:
        label = font.render(decode(state.message), False, (255, 255, 255))
        canvas.blit(label, label.get_rect(center=(WIDTH // 2, 249)))
    panel.draw(canvas, state, font)
    window.fill((10, 14, 23))
    target = fit(window)
    window.blit(pygame.transform.scale(canvas, target.size), target)
    pygame.display.flip()


def play(game, audio, window):
    clock = pygame.time.Clock()
    canvas = pygame.Surface((WIDTH, HEIGHT))
    font = pygame.font.Font(None, 19)
    panel = NetworkPanel(game)
    joysticks = {}

    def connect(device):
        try:
            pad = pygame.joystick.Joystick(device)
            joysticks[pad.get_instance_id()] = pad
        except pygame.error:
            pass

    for device in range(pygame.joystick.get_count()):
        connect(device)

    held, pressed = set(), set()
    summons = elapsed = idle = frame_number = 0
    scene, scene_tick = (1, 0) if game.state().mode == MENU else (0, 0)
    previous = game.state().mode
    previous_pad = 0
    playing = True
    while playing:
        elapsed += min(clock.tick(100), 100)
        game.call("poll", pygame.time.get_ticks())
        state = game.state()
        if state.mode != previous:
            scene = scene_tick = idle = 0
            held.clear()
            pressed.clear()
            if state.mode >= HOST:
                panel.open = False
            previous = state.mode

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                playing = False
                continue
            if event.type == pygame.WINDOWFOCUSLOST:
                held.clear()
                pressed.clear()
            if event.type == pygame.KEYUP:
                held.discard(event.key)
            elif event.type == pygame.JOYDEVICEADDED:
                connect(event.device_index)
            elif event.type == pygame.JOYDEVICEREMOVED:
                joysticks.pop(event.instance_id, None)
            position = None
            if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                area = fit(window)
                if area.collidepoint(event.pos):
                    position = ((event.pos[0] - area.x) * WIDTH / area.w,
                                (event.pos[1] - area.y) * HEIGHT / area.h)
            if panel.handle(event, state, position) or event.type != pygame.KEYDOWN:
                continue
            first = event.key not in held
            held.add(event.key)
            if first:
                pressed.add(event.key)
            if state.mode == MENU:
                idle = 0
                if scene == 1:
                    scene = scene_tick = 0
                elif event.key == pygame.K_SPACE and state.mainPage:
                    scene = {0: 2, 2: 3, 3: 0}[scene]
                    scene_tick = 0
                elif scene:
                    scene = scene_tick = 0
                elif state.mainPage and pygame.K_F1 <= event.key <= pygame.K_F4:
                    game.call("voices", event.key - pygame.K_F1 + 1)
                elif event.key in MENU_KEYS and game.call("menu", MENU_KEYS[event.key]):
                    playing = False
            else:
                if event.key in SHORTCUTS and first:
                    game.call("command", SHORTCUTS[event.key].encode())
                elif event.key == pygame.K_l and first:
                    summons = min(summons + 1, 6)
                elif event.key in VOLUMES:
                    game.call("volume", *VOLUMES[event.key])
        while elapsed >= 20:
            elapsed -= 20
            state = game.state()
            frame_number += 1
            if state.mode == MENU:
                scene_tick += 1
                idle += 1
                if scene == 1 and scene_tick >= 290:
                    scene = scene_tick = 0
                elif scene in (2, 3) and scene_tick >= 1000:
                    scene = 3 if scene == 2 else 0
                    scene_tick = idle = 0
                elif scene == 0 and idle >= 1000 and state.mainPage and not panel.visible(state):
                    scene, scene_tick, idle = 2, 0, 0
                pad = inputs_for(set(), joysticks, False)
                mask = pad[0] | pad[1] | pad[2] | pad[3]
                if not panel.visible(state):
                    for bit, key in ((1, 2), (2, 3), (4, 0), (8, 1), (16, 4)):
                        if mask & bit and not previous_pad & bit:
                            idle = 0
                            if scene:
                                scene = scene_tick = 0
                            elif game.call("menu", key):
                                playing = False
                previous_pad = mask
            else:
                inputs = [] if panel.visible(state) else inputs_for(held | pressed, joysticks, state.sharedKeyboard)
                game.tick(inputs, summons if inputs else 0)
            pressed.clear()
            summons = 0
        state = game.state()
        audio.update(state, game.sounds())
        draw(window, canvas, game, state, scene if state.mode == MENU else 0,
             scene_tick if scene else frame_number, panel, font)
    if game.state().room:
        game.call("network", b"LEAVE")
        for _ in range(5):
            game.call("poll", pygame.time.get_ticks())
            pygame.time.delay(10)


def smoke(game, audio, window):
    canvas = pygame.Surface((WIDTH, HEIGHT))
    font = pygame.font.Font(None, 19)
    panel = NetworkPanel(game)
    assert game.frame(1, 100)[1] == (640, 256)
    draw(window, canvas, game, game.state(), 0, 20, panel, font)
    audio.update(game.state(), game.sounds())
    game.call("start", 1)
    for _ in range(65):
        game.tick([16, 16])
    assert game.state().players == 2, "les deux joueurs ne sont pas apparus"
    for _ in range(345):
        game.tick([])
    game.tick([16])
    assert game.state().bombs > 0, "la pose de bombe a échoué"
    for _ in range(800):
        game.tick([])
        if game.state().phase == 3:
            break
    assert game.state().phase == 3 and game.state().players == 1, "résultat de manche incorrect"
    draw(window, canvas, game, game.state(), 0, 0, panel, font)
    game.call("command", b"M2")
    assert game.state().track == 2
    audio.update(game.state(), game.sounds())
    print("LegoBlast Python : rendu, audio, deux joueurs, bombe et résultat vérifiés.")


def main():
    base = Path(sys.executable).parent if getattr(sys, "frozen", False) else Path(__file__).resolve().parent
    user = Path(os.environ.get("APPDATA") or os.environ.get("XDG_DATA_HOME") or Path.home() / ".local/share")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--data", type=Path, default=base / "data")
    parser.add_argument("--library", type=Path, default=find_library())
    parser.add_argument("--settings", type=Path, default=user / "Gogo/LegoBlastPython")
    parser.add_argument("--network-url", default="wss://legoblast.elom75.workers.dev/v1/socket")
    parser.add_argument("--level", type=int)
    parser.add_argument("--smoke", action="store_true")
    args = parser.parse_args()
    pygame.mixer.pre_init(48000, -16, 2, 1024)
    pygame.init()
    try:
        window = pygame.display.set_mode((WIDTH * 3, HEIGHT * 3), pygame.RESIZABLE)
        pygame.display.set_caption("LegoBlast · Python")
        if args.smoke:
            with TemporaryDirectory() as settings:
                game = Engine(args.library, args.data, Path(settings), args.network_url)
                try:
                    smoke(game, Audio(args.data), window)
                finally:
                    game.close()
        else:
            game = Engine(args.library, args.data, args.settings, args.network_url)
            try:
                if args.level:
                    game.call("start", args.level)
                play(game, Audio(args.data), window)
            finally:
                game.close()
    finally:
        pygame.quit()


if __name__ == "__main__":
    main()
