#+vet explicit-allocators unused style shadowing
package raven_builder

import "core:log"
import "core:flags"
import "core:fmt"
import "../platform"

ODIN_EXE :: "odin"

Command :: enum {
    export,
}

Flags :: struct {
    command: Command `args:"pos=0,required"`,
    pkg: string `args:"pos=1,required" usage:"Package name"`,
}

exec :: proc(str: string) {
    res := platform.run_shell_command(str)
    if 0 != res {
        fmt.printfln("Error: Command '%s' failed with exit code %i", str, res)
    }
}

export_release :: proc(export_name: string, name: string, data: []string) {
    STYLE_FLAGS :: "-strict-style -vet -vet-cast -vet-style -warnings-as-errors -strict-target-features"
    PERF_FLAGS :: "-o:speed -microarch:native -no-bounds-check -disable-assert"
    exec(fmt.tprintf("%s build %s -out:%s.exe -debug %s %s", ODIN_EXE, name, name, STYLE_FLAGS, PERF_FLAGS))
}

main :: proc() {
    context.logger = log.create_console_logger(allocator = context.allocator)

    cmd_args := platform.get_commandline_args(context.allocator)

    args: Flags
    flags.parse_or_exit(&args, cmd_args, allocator = context.allocator)

    switch args.command {
    case .export:
    }
}
