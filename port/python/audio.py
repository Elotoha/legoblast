"""Play the exported sound banks through Pygame's threaded SDL mixer."""

import pygame


class Audio:
    def __init__(self, data):
        self.available = bool(pygame.mixer.get_init())
        self.folder = data / "audio"
        self.revision = None
        self.menu = []
        self.active_music = False
        self.playing_menu = False
        self.effects = []
        self.priorities = [0] * 4
        if self.available:
            pygame.mixer.set_num_channels(8)
            self.effects = [pygame.mixer.Sound(str(self.folder / f"sample-{i:02}.wav")) for i in range(20)]
            self.menu = [pygame.mixer.Sound(str(self.folder / f"Mod_Menu_Voice{i}.flac")) for i in range(1, 5)]

    def update(self, state, events):
        if not self.available:
            return
        new_revision = (state.mode, state.revision)
        if new_revision != self.revision:
            self.revision = new_revision
            pygame.mixer.music.stop()
            for i in range(4, 8):
                pygame.mixer.Channel(i).stop()
            self.playing_menu = state.track == 9
            self.active_music = False
            if self.playing_menu:
                for i, sound in enumerate(self.menu, 4):
                    pygame.mixer.Channel(i).play(sound, loops=-1)
            elif 1 <= state.track <= 7:
                song = self.folder / f"Mod_Game{state.track}.flac"
                if song.is_file():
                    pygame.mixer.music.load(str(song))
                    if state.musicMs:
                        # SDL_mixer's FLAC driver seeks in seconds. Wrap at
                        # the duration when a late guest joins a loop.
                        try:
                            length = pygame.mixer.Sound(str(song)).get_length()
                            pygame.mixer.music.play(-1, start=(state.musicMs / 1000) % length)
                        except (pygame.error, ZeroDivisionError):
                            pygame.mixer.music.play(-1)
                    else:
                        pygame.mixer.music.play(-1)
                    self.active_music = True

        cap = 5 if state.flags & 1 else 20 if state.flags & 2 else 64
        music_gain = min(state.musicVolume, cap) / 64
        pygame.mixer.music.set_volume(0 if state.flags & 4 else music_gain)
        if self.playing_menu:
            for i in range(4):
                pygame.mixer.Channel(i + 4).set_volume(music_gain if i < state.voices else 0)
        effect_gain = state.effectsVolume / 128
        voices = 1 if self.active_music and not state.flags & 4 else 4
        for i in range(4):
            pygame.mixer.Channel(i).set_volume(effect_gain)
        for cue, priority, repetitions in events:
            if not 0 <= cue < len(self.effects) or repetitions < 1:
                continue
            available = [i for i in range(voices) if not pygame.mixer.Channel(i).get_busy()]
            channel = available[0] if available else min(range(voices), key=self.priorities.__getitem__)
            if available or self.priorities[channel] <= priority:
                self.priorities[channel] = priority
                pygame.mixer.Channel(channel).play(self.effects[cue], loops=repetitions - 1)
