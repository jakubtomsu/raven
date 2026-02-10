#+feature dynamic-literals
package shaderprep

import "core:slice"
import "core:strings"
import "core:fmt"
import "core:flags"
import "../platform"

Flags :: struct {
    paths:  string `args:"pos=0,required" usage:"Which file to compile"`,
    target: Target `args:"required" usage:"Target shader language"`,
}

_platform_state: platform.State

main :: proc() {
    init()
    platform.init(&_platform_state)
    defer platform.shutdown()

    args := platform.get_commandline_args(context.allocator)
    flg: Flags
    flags.parse_or_exit(&flg, args)

    fmt.println(flg)

    start := platform.get_time_ns()

    defer {
        dur := platform.get_time_ns() - start
        fmt.printfln("Finished in %f ms", f32(dur / 1e3) / 1e3)
    }

    root := flg.paths
    pattern := fmt.aprintf("%s" + platform.SEPARATOR + "*", flg.paths)

    input_files: map[string]Input_File

    iter: platform.Directory_Iter
    for path in platform.iter_directory(&iter, pattern) {
        if !strings.has_suffix(path, EXT) {
            continue
        }

        full_path := fmt.aprintf("%s" + platform.SEPARATOR + "%s", root, path)
        include_name := path[:len(path) - len(EXT)]

        fmt.println(include_name, ":", full_path)

        data, data_ok := platform.read_file_by_path(full_path)

        if !data_ok {
            fmt.printfln("Error: failed to open file '%s'", full_path)
        }

        input_files[include_name] = Input_File{
            full_path = full_path,
            code = string(data),
        }
    }

    opts: Options = {
        target = flg.target,
        whitespace = true,
    }

    unit := process_unit(
        input_files = input_files,
        opts = opts,
    )

    output_names: [dynamic]string

    for name in unit.output {
        append(&output_names, name)
    }

    slice.sort(output_names[:])

    for name in output_names {
        out := unit.output[name]
        if out.stage == .None {
            continue
        }

        fmt.printfln("{} {}:\nBEGIN<<<{}>>>END", name, out.stage, out.code)
    }

    // data, data_ok := platform.read_file_by_path(flg.path)

    // if !data_ok {
    //     fmt.printfln("Error: failed to open file '%s'", flg.path)
    // }

    // // 2 stages - process include files, then process shader files

    // // NOTE: when processing many files we could use a single arena

    // res_code := process_file(
    //     filename = flg.path,
    //     code = string(data),
    //     opts = {
    //         target = .HLSL,
    //     },
    // )

    // fmt.printfln("RESULT CODE:\n<<<{}>>>", res_code)
}