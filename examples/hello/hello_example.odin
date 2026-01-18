package raven_example_hello

import "core:terminal/ansi"
import "core:reflect"
import "base:runtime"
import "core:log"
import "core:math"
import "core:fmt"
import rv "../.."
import "../../gpu"
import "../../platform"
import "../../audio"


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
        rv.init("Raven Hello Example")
        state = new(State)
        state.raven = rv.get_state_ptr()

        print_member_sizes(rv.State)
        print_member_sizes(audio.State)
        print_member_sizes(gpu.State)
    }

    // fmt.printfln("size_of(rv.State) = %M", size_of(rv.State))
    // fmt.printfln("size_of(gpu.State) = %M", size_of(gpu.State))
    // fmt.printfln("size_of(platform.State) = %M", size_of(platform.State))
    // fmt.printfln("size_of(audio.State) = %M", size_of(audio.State))

    rv.set_state_ptr(state.raven)

    log.info("new frame")

    if !rv.new_frame() {
        if !gpu._state.fully_initialized {
            return state
        }
        return nil
    }

    rv.set_layer_params(0, rv.make_screen_camera())
    rv.set_layer_params(1, rv.make_screen_camera())

    rv.bind_depth_test(true)
    rv.bind_depth_write(true)
    rv.bind_texture("thick")

    center := rv.get_viewport() * {0.5, 0.5, 0}
    for i in 0..<3 {
        t := f32(i) / 2
        rv.draw_text("Hello World!",
            center + {
                0,
                math.sin_f32(rv.get_time() - t * 0.5) * 100,
                f32(i) * 0.1,
            },
            anchor = 0.5,
            spacing = 1,
            scale = 4,
            col = i == 0 ? rv.WHITE : rv.BLUE,
        )
    }

    rv.bind_layer(1)
    rv.bind_blend(.Add)
    rv.draw_text("Hello World!",
        {100, 100, 0},
        anchor = 0,
        spacing = 1,
        scale = 4,
        col = rv.RED * rv.fade(0.5),
    )

    state.num += 1

    rv.upload_gpu_layers()

    rv.render_gpu_layer(0, rv.DEFAULT_RENDER_TEXTURE,
        clear_color = rv.Vec3{0, 0, 0.5},
        clear_depth = true,
    )

    rv.render_gpu_layer(1, rv.DEFAULT_RENDER_TEXTURE,
        clear_color = nil,
        clear_depth = false,
    )

    return state
}

print_member_sizes :: proc($T: typeid) {
    fmt.printfln("total = %M", size_of(T))
    for field in reflect.struct_fields_zipped(T) {
        col := ansi.RESET
        factor := f64(field.type.size) / f64(size_of(T))
        if factor > 0.2 {
            col = ansi.FG_RED
        } else if factor > 0.1 {
            col = ansi.FG_YELLOW
        } else if factor < 0.01 {
            col = ansi.FG_GREEN
        }

        fmt.print(ansi.CSI)
        fmt.print(col)
        fmt.print(ansi.SGR)
        fmt.printfln("  %s = %M (%.1f%%)", field.name, field.type.size, 100 * factor)
        fmt.print(ansi.CSI + ansi.RESET + ansi.SGR)
    }
}