package raven_example_hello

import "core:log"
import rv "../.."
import "../../base"
import "core:math/rand"
import "core:math/linalg"
import "core:fmt"

state: ^State

State :: struct {
    // Using the GPU bit pool. A datastructure package for users might get added later.
    pool:   base.Bit_Pool(4096),
    parts:  [4096]Particle,
}

Particle :: struct {
    pos:    rv.Vec2,
    vel:    rv.Vec2,
    timer:  f32,
    dur:    f32,
}

@export _module_desc := rv.Module_Desc {
    state_size = size_of(State),
    init = _init,
    shutdown = _shutdown,
    update = _update,
}

main :: proc() {
    rv.run_main_loop(_module_desc)
}

_init :: proc() {
    state = new(State)
}

_shutdown :: proc() {
    free(state)
}

_update :: proc(hot_state: rawptr) -> rawptr {
    if hot_state != nil {
        state = cast(^State)hot_state
    }

    if rv.key_pressed(.Escape) {
        rv.request_shutdown()
    }

    delta := rv.get_delta_time()

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
                timer = rand.float32_range(2, 4),
            }

            index, index_ok := base.bit_pool_find_0(state.pool)
            if index_ok {
                base.bit_pool_set_1(&state.pool, index)
                state.parts[index] = p
            } else {
                log.error("Pool full!")
            }
        }
    }


    for &p, index in state.parts {
        if !base.bit_pool_check_1(state.pool, index) {
            continue
        }

        if p.timer < 0 {
            base.bit_pool_set_0(&state.pool, index)
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

    for i in 0..<64 {
        block_full := (state.pool.l0[0] & (1 << uint(i))) != 0
        block := state.pool.l1[i]

        if block_full {
            assert(~block == 0)
        }

        base_pos := rv.Vec3{
            64 + f32(i % 8) * (32 + 4),
            64 + f32(i / 8) * (32 + 4),
            0.1,
        }

        rv.draw_sprite(
            base_pos,
            solid,
            scale = {32, 32},
            col = block_full ? rv.RED : rv.BLACK,
            scaling = .Absolute,
        )

        for i_local in 0..<64 {
            local_pos := base_pos + rv.Vec3{
                f32(i_local % 8) * 4 - 14,
                f32(i_local / 8) * 4 - 14,
                -0.05,
            }

            local_full := (block & (1 << uint(i_local))) != 0

            if local_full {
                rv.draw_sprite(
                    local_pos,
                    solid,
                    scale = {2, 2},
                    scaling = .Absolute,
                )
            }

            // rv.draw_sprite()
        }
    }

    rv.draw_text("LMB to spawn particles", {10, 10, 0}, scale = 2)

    rv.upload_gpu_layers()
    rv.render_gpu_layer(0, rv.DEFAULT_RENDER_TEXTURE, clear_color = rv.Vec3{0, 0, 0.5}, clear_depth = true)

    return state
}