// Simple program to check all the examples and run tests
package ravn_build_check

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"

ODIN_EXE :: "odin"
RUN_TIMEOUT :: 1

Task :: struct {
    platforms: bit_set[runtime.Odin_OS_Type],
    args:      []string,
}

_tasks := []Task {
    {{.Windows, .Linux}, {"check", "build"}},
    {{.Windows, .Linux}, {"check", "build", "-debug"}},
    {{.Windows, .Linux}, {"check", "build/check"}},
    {{.Windows, .Linux}, {"check", "build/cheatsheet"}},
    {{.Windows, .Linux}, {"check", "examples/hello"}},
    {{.Windows, .Linux}, {"check", "examples/hello", "-debug"}},
    {{.Windows, .Linux}, {"check", "examples/hello", "-define:RELEASE=true"}},
    {{.Windows, .Linux}, {"check", "examples/hello", "-define:AUDIO_BACKEND=None"}},
    {{.Windows},         {"check", "examples/hello", "-define:AUDIO_BACKEND=WASAPI"}},
    {{.Windows, .Linux}, {"check", "examples/hello", "-define:AUDIO_BACKEND=miniaudio"}},
    {{.Windows, .Linux}, {"check", "examples/hello", "-define:AUDIO_BACKEND=SDL3"}},
    {{.Windows, .Linux}, {"check", "examples/hello", "-define:GPU_BACKEND=Dummy"}},
    {{.Windows},         {"check", "examples/hello", "-define:GPU_BACKEND=D3D11"}},
    {{.Windows, .Linux}, {"check", "examples/hello", "-define:GPU_BACKEND=WGPU"}},
    {{.Windows, .Linux}, {"check", "examples/hello", "-define:GPU_BACKEND=WGPU", "-target:js_wasm32"}},
    {{.Windows, .Linux}, {"check", "examples/hello", "-define:PLATFORM_BACKEND=Dummy"}},
    {{.Windows},         {"check", "examples/hello", "-define:PLATFORM_BACKEND=Windows"}},
    {{.Windows, .Linux}, {"check", "examples/hello", "-define:PLATFORM_BACKEND=JS", "-target:js_wasm32"}},
    {{.Windows, .Linux}, {"check", "examples/hello", "-define:PLATFORM_BACKEND=SDL3"}},
    {{.Windows, .Linux}, {"check", "examples/hello_minimal"}},
    {{.Windows, .Linux}, {"check", "examples/audio_viewer"}},
    {{.Windows, .Linux}, {"check", "examples/geometry"}},
    {{.Windows, .Linux}, {"check", "examples/collision"}},
    {{.Windows, .Linux}, {"check", "examples/stress_test_3d"}},
    {{.Windows, .Linux}, {"check", "examples/spatial_audio"}},
    {{.Windows, .Linux}, {"check", "examples/fps"}},
    {{.Windows, .Linux}, {"check", "examples/gpu_compute"}},
    {{.Windows, .Linux}, {"check", "examples/draw_2d"}},
    {{.Windows, .Linux}, {"check", "examples/draw_3d"}},
    {{.Windows, .Linux}, {"check", "examples/render_texture"}},
    {{.Windows, .Linux}, {"check", "examples/snake_planet"}},
    {{.Windows, .Linux}, {"check", "examples/standalone_audio_simple"}},
    {{.Windows, .Linux}, {"check", "examples/standalone_gpu_sdl3_triangle"}},
    {{.Windows},         {"check", "examples/standalone_platform_d3d11"}},

    {{.Windows, .Linux}, {"test", ".", "-debug"}},
    {{.Windows, .Linux}, {"test", "entities", "-debug"}},
    {{.Windows, .Linux}, {"test", "bvh", "-debug"}},

    {{.Windows, .Linux}, {"run", "examples/hello"}},
    {{.Windows, .Linux}, {"run", "examples/hello", "-debug"}},
    {{.Windows, .Linux}, {"run", "examples/hello", "-define:RELEASE=true"}},
    {{.Windows, .Linux}, {"run", "examples/hello", "-define:AUDIO_BACKEND=None"}},
    {{.Windows},         {"run", "examples/hello", "-define:AUDIO_BACKEND=WASAPI"}},
    {{.Windows, .Linux}, {"run", "examples/hello", "-define:AUDIO_BACKEND=miniaudio"}},
    {{.Windows, .Linux}, {"run", "examples/hello", "-define:AUDIO_BACKEND=SDL3"}},
    {{.Windows},         {"run", "examples/hello", "-define:GPU_BACKEND=D3D11"}},
    {{.Windows, .Linux}, {"run", "examples/hello", "-define:GPU_BACKEND=WGPU"}},
    {{.Windows},         {"run", "examples/hello", "-define:PLATFORM_BACKEND=Windows"}},
    {{.Windows, .Linux}, {"run", "examples/hello", "-define:PLATFORM_BACKEND=SDL3"}},
    {{.Windows, .Linux}, {"run", "examples/hello_minimal"}},
    {{.Windows, .Linux}, {"run", "examples/geometry"}},
    {{.Windows, .Linux}, {"run", "examples/collision"}},
    {{.Windows, .Linux}, {"run", "examples/stress_test_3d"}},
    {{.Windows, .Linux}, {"run", "examples/spatial_audio"}},
    {{.Windows, .Linux}, {"run", "examples/fps"}},
    {{.Windows},         {"run", "examples/gpu_compute"}},
    {{.Windows, .Linux}, {"run", "examples/draw_2d"}},
    {{.Windows},         {"run", "examples/draw_3d"}},
    {{.Windows, .Linux}, {"run", "examples/render_texture"}},
    {{.Windows, .Linux}, {"run", "examples/snake_planet"}},
    {{.Windows, .Linux}, {"run", "examples/standalone_audio_simple"}},
    {{.Windows},         {"run", "examples/standalone_gpu_sdl3_triangle"}},
    {{.Windows},         {"run", "examples/standalone_platform_d3d11"}},
    {{.Windows, .Linux}, {"run", "examples/audio_viewer"}},
}

main :: proc() {
    failed: [dynamic]Task
    for task in _tasks {
        if ODIN_OS not_in task.platforms {
            continue
        }

        ok: bool
        if task.args[0] == "run" {
            ok = execute_odin_run(task)
        } else {
            ok = execute_odin(task.args, os.TIMEOUT_INFINITE)
        }

        if !ok {
            append(&failed, task)
        }
    }

    fmt.printfln("\nDone, %i/%i tasks finished successfully.", len(_tasks) - len(failed), len(_tasks))

    if len(failed) != len(_tasks) {
        fmt.eprintln("Failed tasks:")
        for task in failed {
            fmt.printfln("\t%s", strings.join(task.args, " "))
        }
        os.exit(1)
    }
}

execute_odin :: proc(args: []string, timeout: time.Duration) -> bool {
    cmd := make([dynamic]string, context.temp_allocator)
    append(&cmd, ODIN_EXE)
    append(&cmd, ..args)

    fmt.printfln("Running '%s'", strings.join(cmd[:], " ", context.temp_allocator))

    process, start_err := os.process_start(os.Process_Desc{
        command = cmd[:],
        stdout  = nil,
        stderr  = nil,
        stdin   = nil,
    })

    if start_err != nil {
        fmt.eprintln("\nProcess failed to start", start_err)
        return false
    }

    return wait_process(process, timeout)
}

execute_odin_run :: proc(task: Task) -> bool {
    when ODIN_OS == .Windows {
        OUT :: "check_run.exe"
        EXE :: "check_run.exe"
    } else {
        OUT :: "check_run"
        EXE :: "./check_run"
    }

    build_args := make([dynamic]string, context.temp_allocator)
    append(&build_args, "build")
    append(&build_args, ..task.args[1:])
    append(&build_args, "-out:" + OUT)

    if !execute_odin(build_args[:], os.TIMEOUT_INFINITE) {
        return false
    }

    defer {
        os.remove(OUT)
        when ODIN_OS == .Windows {
            os.remove(".check_run.pdb")
        }
    }

    fmt.printfln("Running '%s'", EXE)
    process, start_err := os.process_start(os.Process_Desc{
        command = {EXE},
        stdout  = nil,
        stderr  = nil,
        stdin   = nil,
    })

    if start_err != nil {
        fmt.eprintln("\tProcess failed to start", start_err)
        return false
    }

    return wait_process(process, RUN_TIMEOUT * time.Second)
}

wait_process :: proc(process: os.Process, timeout: time.Duration) -> bool {
    state, wait_err := os.process_wait(process, timeout)
    if v, ok := wait_err.(os.General_Error); ok && v == .Timeout {
        _ = os.process_kill(process)
        _, _ = os.process_wait(process)
        return true
    }
    if wait_err != nil {
        fmt.eprintln("\tProcess wait failed:", wait_err)
        return false
    }
    if state.exit_code != 0 {
        fmt.eprintln("\tProcess failed with exit code:", state.exit_code)
        return false
    }
    return true
}
