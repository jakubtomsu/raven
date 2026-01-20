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
import "../../ufmt"

state: ^State

State :: struct {
    num:    i32,
}

main :: proc() {
    fmt.println("Hello")
    rv.run_module_loop(_module_api())
}

@export _module_api :: proc "contextless" () -> (result: rv.Module_API) {
    runtime.print_string("MODULE API\n")
    result = {
        state_size = size_of(State),
        init = transmute(rv.Init_Proc)_init,
        shutdown = transmute(rv.Shutdown_Proc)_shutdown,
        update = transmute(rv.Update_Proc)_update,
    }
    return result
}

_init :: proc() -> ^State {
    log.info("Init")
    state = new(State)

    rv.init_window("Raven Hello Example")

    return state
}

_shutdown :: proc(prev_state: ^State) {
    log.info("Shutdown")

    state = prev_state

    free(state)
}

_update :: proc(prev_state: ^State) -> ^State {
    // log.info("Update")

    state = prev_state

    if rv.key_pressed(.Escape) {
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