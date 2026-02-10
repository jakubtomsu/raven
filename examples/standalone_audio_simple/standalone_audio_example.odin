package raven_simple_audio_example

import "core:time"
import "../../audio"
import "../../base/ufmt"

state: audio.State

main :: proc() {
    audio_ok := audio.init(&state)
    assert(audio_ok)
    defer audio.shutdown()

    res, res_ok := audio.create_resource_encoded(#load("../data/snake_death_sound.wav"))
    assert(res_ok)

    for i in 0..<10 {
        audio.update()

        sound, sound_ok := audio.create_sound(res)
        assert(sound_ok)
        ufmt.eprintfln("Iter %i : %v", i, sound)
        audio.set_sound_playing(sound, true)
        audio.set_sound_pitch(sound, 0.5 + f32(i) * 0.2)

        for audio.get_sound_time(sound, .Percentage) < 0.5 {
            time.sleep(time.Millisecond)
        }
    }
}