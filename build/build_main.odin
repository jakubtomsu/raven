#+vet unused style shadowing
package raven_build

import "../platform"
import "../base"

import "core:flags"
import "core:strings"

ODIN_EXE :: "odin"

Command :: enum {
    export,
    export_web,
    run_hot,
    build_hot,
}

Flags :: struct {
    cmd:    Command `args:"pos=0,required" usage:"Only build, don't run"`,
    pkg:    string `args:"pos=1,required" usage:"The Odin package name to run/build"`,
}

main :: proc() {
    context.logger = base.create_logger()

    args := platform.get_commandline_args(context.allocator)

    fl: Flags
    flags.parse_or_exit(&fl, args, allocator = context.allocator)

    pkg_name := fl.pkg[find_last_slash(fl.pkg)+1:]

    switch fl.cmd {
    case .export:
        unimplemented()

    case .export_web:
        export_web(strings.concatenate({pkg_name, "-web-export"}), pkg_name, fl.pkg)

    case .run_hot:
        clean_hot(pkg_name)
        compile_hot(fl.pkg, pkg_name = pkg_name, index = 0)
        hotreload_run(pkg_name, fl.pkg)
        clean_hot(pkg_name)

    case .build_hot:
        latest, _ := hotreload_find_latest_dll(pkg_name)
        base.log_info("Building %i", latest.index + 1)
        compile_hot(fl.pkg, pkg_name = pkg_name, index = latest.index + 1)
    }
}
