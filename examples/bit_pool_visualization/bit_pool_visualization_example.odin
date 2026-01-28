package raven_example_hello

import "core:log"
import rv "../.."
import "../../gpu"
import "core:math/rand"
import "core:math/linalg"
import "core:fmt"

state: ^State

State :: struct {
    // Using the GPU bit pool. A datastructure package for users might get added later.
    pool:   gpu.Bit_Pool(4096),
    parts:  [4096]Particle,
}

Particle :: struct {
    pos:    rv.Vec2,
    vel:    rv.Vec2,
    timer:  f32,
    dur:    f32,
}

main :: proc() {
    rv.run_main_loop(_module_api())
}

@export _module_api :: proc "contextless" () -> (result: rv.Module_API) {
    result = {
        state_size = size_of(State),
        init = transmute(rv.Init_Proc)_init,
        shutdown = transmute(rv.Shutdown_Proc)_shutdown,
        update = transmute(rv.Update_Proc)_update,
    }
    return result
}

_init :: proc() -> ^State {
    state = new(State)
    rv.init_window("Raven Hello Example")
    return state
}

_shutdown :: proc(prev_state: ^State) {
    free(prev_state)
}

_update :: proc(prev_state: ^State) -> ^State {
    state = prev_state
    delta := rv.get_delta_time()

    if rv.key_pressed(.Escape) {
        return nil
    }

    rv.set_layer_params(0, rv.make_screen_camera())
    rv.bind_texture("thick")
    rv.bind_blend(.Alpha)

    if rv.mouse_down(.Left) {
        num := 32
        vel: f32 = 200
        if rv.mouse_pressed(.Left) {
            num *= 10
            vel *= 2
        }

        for i in 0..<num {
            p: Particle = {
                pos = rv.mouse_pos() + 5 * {
                    rand.float32() * 2.0 - 1.0,
                    rand.float32() * 2.0 - 1.0,
                },
                vel = vel * rand.float32() * linalg.normalize0(rv.Vec2{
                    rand.float32() * 2.0 - 1.0,
                    rand.float32() * 2.0 - 1.0,
                }),
                timer = rand.float32_range(1, 4),
            }

            index, index_ok := gpu.bit_pool_find_0(state.pool)
            if index_ok {
                gpu.bit_pool_set_1(&state.pool, index)
                state.parts[index] = p
            } else {
                log.error("Pool full!")
            }
        }
    }


    for &p, index in state.parts {
        if !gpu.bit_pool_check_1(state.pool, index) {
            continue
        }

        if p.timer < 0 {
            gpu.bit_pool_set_0(&state.pool, index)
            continue
        }

        p.timer -= delta
        p.vel = rv.lexp(p.vel, 0, delta)
        p.pos += p.vel * delta

        rv.draw_sprite(
            {p.pos.x, p.pos.y, 0.5},
            rv.font_slot('+'),
            col = rv.fade(rv.smoothstep(0, 1, p.timer)),
        )
    }

    solid := rv.font_slot(0)
    rv.bind_sprite_scaling(.Absolute)

    for i in 0..<64 {
        block_full := (state.pool.l0[0] & (1 << uint(i))) != 0
        block := state.pool.l1[i]

        if block_full {
            assert(~block == 0)
        }

        base_pos := rv.Vec3{
            64 + f32(i % 8) * (64 + 4),
            64 + f32(i / 8) * (64 + 4),
            0.1,
        }

        rv.draw_sprite(
            base_pos,
            solid,
            scale = {64, 64},
            col = block_full ? rv.RED : rv.BLACK,
        )

        for i_local in 0..<64 {
            local_pos := base_pos + rv.Vec3{
                f32(i_local % 8) * 8 - 32,
                f32(i_local / 8) * 8 - 32,
                -0.05,
            }

            local_full := (block & (1 << uint(i_local))) != 0

            if local_full {
                rv.draw_sprite(
                    local_pos,
                    solid,
                    scale = {3, 3},
                )
            }

            // rv.draw_sprite()
        }

    }

    rv.bind_sprite_scaling(.Pixel)

    rv.draw_text("LMB to spawn particles", {10, 10, 0}, scale = 2)
    rv.draw_text(fmt.tprintf("Mouse Pos: %v\nMouse Delta: %v", rv.mouse_pos(), rv.mouse_delta()), {10, 100, 0}, scale = 2)

    rv.upload_gpu_layers()
    rv.render_gpu_layer(0, rv.DEFAULT_RENDER_TEXTURE, clear_color = rv.Vec3{0, 0, 0.5}, clear_depth = true)

    return state
}