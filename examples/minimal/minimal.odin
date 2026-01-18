package raven_example_minimal

import "core:log"
import "base:runtime"
import rv "../.."

state: ^State
State :: struct {
    num:    i32,
    raven:  ^rv.State,
}

main :: proc() {
    rv.run_main_loop(cast(rv.Step_Proc)_step)
}

@export _step :: proc "contextless" (prev_state: ^State) -> ^State {
    context = rv.default_context()
    // THIS LEAKS THE LOGGER FUCK
    context.logger = log.create_console_logger()

    state = prev_state
    if state == nil {
        rv.init("Minimal Example")
        state = new(State)
        state.raven = rv.get_state_ptr()
    }

    rv.set_state_ptr(state.raven)

    if !rv.new_frame() {
        return nil
    }

    if rv.key_pressed(.Space) {
        assert(false)
    }

    rv.set_layer_params(0, rv.make_screen_camera())

    rv.bind_texture("thin")
    rv.bind_depth_test(false)
    rv.bind_fill(.All)
    rv.draw_sprite(
        {64, 64 + f32(state.num/2 % 1000), 0.0},
    )

    state.num += 1

    rv.upload_gpu_layers()

    rv.render_gpu_layer(0, rv.DEFAULT_RENDER_TEXTURE,
        clear_color = rv.Vec3{0, 0, 0.5},
        clear_depth = true,
    )

    return state
}
