// Dummy backend which doesn't produce any audio output.
package raven_audio

BACKEND_NONE :: "None"

when BACKEND == BACKEND_NONE {
    _State :: struct {}

    @(require_results)
    _init :: proc() {}
    _shutdown :: proc() {}
    _update_output_buffer :: proc() {}
}