package raven_planet_snake_example

import "core:math/rand"
import "core:log"
import "core:math/linalg"
import "core:math"
import rv "../.."
import "../../platform"
import "../../ufmt"

state: ^State

State :: struct {
    cam_pos:        rv.Vec3,
    cam_rot:        rv.Quat,
    cam_fov:        f32,

    obsts:          [64]Obstacle,
    num_obsts:      i32,

    berry:          Berry,
    berry_timer:    f32,

    snake:          Snake,
}

Obstacle :: struct {
    pos:    rv.Vec3,
}

Berry :: struct {
    pos:    rv.Vec3,
}

MAX_SEGMENTS :: 512

Snake :: struct {
    dir:            rv.Vec2,
    pos:            rv.Vec3,
    segments:       [MAX_SEGMENTS]Segment,
    num_segments:   i32,
    segment_timer:  f32,
}

Segment :: struct {
    pos:    rv.Vec3,
}

main :: proc() {
    rv.run_main_loop(_module_api())
}

@export _module_api :: proc "contextless" () -> (rv.Module_API) {
    return {
        state_size = size_of(State),
        init = transmute(rv.Init_Proc)_init,
        shutdown = transmute(rv.Shutdown_Proc)_shutdown,
        update = transmute(rv.Update_Proc)_update,
    }
}

_init :: proc() -> ^State {
    state = new(State)

    rv.init_window("Simple 3D Example")
    platform.set_mouse_relative(rv._state.window, true)
    platform.set_mouse_visible(false)

    new_game()

    return state
}

_shutdown :: proc(prev: ^State) {
    free(prev)
}

new_game :: proc() {
    state.cam_pos = {0, 0, -10}
    state.cam_rot = 1
    state.cam_fov = rv.deg(90)
    state.berry_timer = 100
    state.snake = {
        pos = {0, 0, -1},
        dir = {0, 1},
        num_segments = 30,
        segments = {
            0 = {
                pos = {1, 0, 0},
            },
        },
    }

    state.num_obsts = 5
    for i in 0..<state.num_obsts {
        state.obsts[i] = {
            pos = rand_dir()
        }
    }

    state.berry = {
        pos = rand_dir(),
    }
}

rand_dir :: proc() -> rv.Vec3 {
    return linalg.normalize0(rv.Vec3{
        rand.float32() * 2.0 - 1.0,
        rand.float32() * 2.0 - 1.0,
        rand.float32() * 2.0 - 1.0,
    })
}

_update :: proc(prev: ^State) -> ^State {
    if rv.key_pressed(.Escape) {
        return nil
    }

    delta := rv.get_delta_time()

    snake := &state.snake

    mat := linalg.matrix3_from_quaternion_f32(state.cam_rot)

    move_inp: rv.Vec2
    if rv.key_down(.D) do move_inp.x += 1
    if rv.key_down(.A) do move_inp.x -= 1
    if rv.key_down(.W) do move_inp.y += 1
    if rv.key_down(.S) do move_inp.y -= 1

    // move_dir := move_inp.x * rv.Vec3{1, 0, 0} + mat[1] * rv.Vec3{0, 1, 0}

    if linalg.length2(move_inp) > 0.1 {
        move_inp = linalg.normalize0(move_inp)
    }

    snake.dir += move_inp * delta * 8
    snake.dir = linalg.normalize0(snake.dir)

    world_dir := mat[0] * snake.dir.x + mat[1] * snake.dir.y

    speed: f32 = 0.7 + f32(snake.num_segments / 5) * 0.15
    speed *= rv.remap_clamped(state.berry_timer, 0, 2, 2, 1)

    snake.pos += world_dir * delta * speed
    snake.pos = linalg.normalize0(snake.pos)

    state.berry_timer += delta

    if linalg.distance(state.berry.pos, snake.pos) < 0.2 {
        state.berry = {
            rand_dir()
        }

        snake.segments[snake.num_segments] = {
            pos = snake.num_segments > 0 ? snake.segments[snake.num_segments - 1].pos : snake.pos,
        }
        snake.num_segments += 1
        state.berry_timer = 0
    }

    for &seg, i in snake.segments[:snake.num_segments] {
        prev := i == 0 ? snake.pos : snake.segments[i - 1].pos

        seg.pos = prev + linalg.normalize0(seg.pos - prev) * 0.1
    }

    for &seg in snake.segments[:snake.num_segments] {
        seg.pos = linalg.normalize0(seg.pos)
    }

    state.cam_pos = rv.lexp(state.cam_pos + world_dir * 0.05, snake.pos * 2.5, delta * 6)

    target_rot := linalg.quaternion_from_forward_and_up_f32(
        state.cam_pos,
        mat[1],
    )
    state.cam_rot = target_rot
    state.cam_fov = rv.lexp(state.cam_fov, rv.deg(65), delta * 5)

    rv.set_layer_params(0, rv.make_3d_perspective_camera(state.cam_pos, state.cam_rot, state.cam_fov))
    rv.set_layer_params(1, rv.make_screen_camera())

    rv.bind_depth_test(true)
    rv.bind_depth_write(true)
    rv.bind_texture("default")

    sph := rv.get_mesh("Icosphere")

    rv.draw_mesh_by_handle(sph, 0, col = {0.15, 0.7, 0.25, 1.0})

    rv.draw_mesh_by_handle(sph, snake.pos, scale = 0.05, col = rv.ORANGE)
    rv.draw_mesh_by_handle(sph, snake.pos + world_dir * 0.2, scale = 0.01, col = rv.RED)

    for seg in snake.segments[:snake.num_segments] {
        rv.draw_mesh_by_handle(sph, seg.pos, scale = 0.05, col = rv.ORANGE)
    }

    for obst in state.obsts[:state.num_obsts] {
        rv.draw_mesh_by_handle(sph, obst.pos, scale = 0.1, col = {0.15, 0.5, 0.2, 1})
    }

    rv.draw_mesh_by_handle(sph, state.berry.pos, scale = 0.1, col = rv.RED)
    rv.draw_mesh_by_handle(sph, state.berry.pos * 1.1, scale = 0.1, col = rv.RED)
    rv.draw_mesh_by_handle(sph, state.berry.pos * 1.2, scale = 0.1, col = rv.RED)
    rv.draw_mesh_by_handle(sph, state.berry.pos * 1.3, scale = 0.1, col = rv.RED)

    rv.bind_layer(1)
    rv.bind_texture("thick")
    rv.bind_depth_test(true)
    rv.bind_depth_write(true)

    screen := rv.get_viewport()

    rv.draw_text("Use WASD to move", {screen.x * 0.5, 14, 0.1}, anchor = 0.5, scale = 2)
    rv.draw_text(ufmt.tprintf("SCORE %i", snake.num_segments), {screen.x * 0.5, screen.y - 30, 0.1}, anchor = 0.5,
        scale = rv.remap_clamped(state.berry_timer, 0, 0.2, 3, 2))

    rv.draw_counter(.CPU_Frame_Ns, {10, 10, 0.1}, scale = 2, unit = 1e-6, col = rv.GREEN)

    rv.upload_gpu_layers()
    rv.render_gpu_layer(0, rv.DEFAULT_RENDER_TEXTURE, rv.Vec3{0.05, 0.1, 0.2}, true)
    rv.render_gpu_layer(1, rv.DEFAULT_RENDER_TEXTURE, nil, false)

    return state
}