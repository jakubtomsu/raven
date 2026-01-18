#+vet explicit-allocators shadowing unused
package raven_audio

import "core:math"

volume_linear_to_db :: proc(factor: f32) -> f32 {
    return 20 * math.log10_f32(factor)
}

volume_db_to_linear :: proc(gain: f32) -> f32 {
    return math.pow_f32(10, gain / 20.0)
}

// Returns frequency in Hz for a given midi note.
note :: proc(#any_int midi_n: i32) -> f32 {
    return 440 * math.pow_f32(2, f32(midi_n - 69) * (1.0 / 12.0))
}