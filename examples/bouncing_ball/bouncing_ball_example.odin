/*
    Raven Bouncing Ball Example
    Credit: Example originally created by Ramon Santamaria (@raysan5) for Raylib
*/

package raven_bouncing_ball_example

import rv "../.."

state: ^State

State :: struct {
    ball: Ball,
    ball_texture: rv.Texture_Handle,

    paused: bool,
}

Ball :: struct {
    position: rv.Vec3,
    speed: rv.Vec2,
    radius: f32,
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
    rv.init_window("Raven Bouncing Ball Example")

    state.ball_texture = rv.create_texture_from_encoded_data(
        "circle",
        #load("../data/circle.png"),
    ) or_else panic("Failed to load ball texture")

    screen := rv.get_screen_size()
    state.ball = {
        position = {screen.x / 2, screen.y / 2, 0},
        speed = {5.0, 4.0},
        radius = 60,
    }

    return state
}

_shutdown :: proc(prev_state: ^State) {
    free(prev_state)
}

_update :: proc(prev_state: ^State) -> ^State {
    state = prev_state
    ball := &state.ball
    screen := rv.get_screen_size()

    if rv.key_pressed(.Escape) do return nil
    if rv.key_pressed(.Space) do state.paused = !state.paused

    if !state.paused {
        ball.position.x += ball.speed.x
        ball.position.y += ball.speed.y

        // Check wall collisions for bouncing
        if ball.position.x >= (screen.x - ball.radius) || ball.position.x <= ball.radius {
            ball.speed.x *= -1.0
        }
        if ball.position.y >= (screen.y - ball.radius) || ball.position.y <= ball.radius {
            ball.speed.y *= -1.0
        }
    }

    rv.set_layer_params(0, rv.make_screen_camera())

    rv.bind_sprite_scaling(.Absolute)
    rv.bind_texture("circle")
    rv.draw_sprite(
        pos = state.ball.position,
        scale = {ball.radius * 2, ball.radius * 2},
        col = {1.0, 0.0, 0.0, 1.0},
    )

    rv.bind_sprite_scaling(.Pixel)
    rv.bind_texture("thick")
    rv.bind_blend(.Alpha)
    rv.draw_text("PRESS SPACE to PAUSE BALL MOVEMENT", {20, 20, 0}, scale = 4, col = {0, 0, 0, 1})

    rv.upload_gpu_layers()
    rv.render_gpu_layer(0, rv.DEFAULT_RENDER_TEXTURE, clear_color = rv.Vec3{.98, .98, .98}, clear_depth = true)

    return state
}