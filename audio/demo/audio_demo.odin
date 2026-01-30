package raven_audio_demo

import "core:log"
import "core:fmt"
import "core:time"
import ".."

main :: proc() {
    context.logger = log.create_console_logger()

    audio.init()
    defer audio.shutdown()

    g := audio.create_group(delay = 0.1)

    for j in 0..<10 {
        audio.set_group_delay_decay(g, j == 0 ? 0.1 : 0.8)

        for i in 0..<12 {
            audio.update()

            s := audio.play_sound("68443__pinkyfinger__piano-e.wav", group = g)
            fmt.println(s)
            audio.set_sound_pitch(s, 1 - 0.5 * f32(i) / 12)
            // audio.set_sound_pan(s, f32(i) / 12)
            audio.set_sound_volume(s, 0.5 + f32(i %% 2))

            audio.set_sound_position(s, {0, 0, f32(i) * 0.5})

            for audio.get_sound_progress(s) < 0.1 {
                time.sleep(time.Millisecond * 30)
            }
        }
    }
}