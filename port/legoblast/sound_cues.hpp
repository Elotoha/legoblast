#pragma once

namespace legoblast {
enum class SoundCue : unsigned {
    Bonus, Death, Explosion, Teleport, BombImpact, Plant, Alarm, ClosingBlock,
    Victory, Draw, Crowd, Hot, VeryHot, DiseaseEnd, Nuclear, Rebound, Bumper,
    MatchVictory, Camera, DontMove, Count
};

struct SoundRequest {
    SoundCue cue;
    int priority;
    unsigned repetitions{1};
};
}
