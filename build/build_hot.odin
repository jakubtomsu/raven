// https://github.com/karl-zylinski/odin-raylib-hot-reload-game-template/blob/main/source/main_hot_reload/main_hot_reload.odin

#+private=file
package raven_build

import "core:flags"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:log"
import "base:runtime"
import "../platform"

when ODIN_OS == .Windows {
    DLL_EXT :: ".dll"
} else when ODIN_OS == .Darwin {
    DLL_EXT :: ".dylib"
} else {
    DLL_EXT :: ".so"
}

Hotreload_Module :: struct {
    mod:            platform.Module,
    callback:       proc "contextless" (rawptr) -> rawptr,
}

Hotreload_File :: struct {
    path:       string,
    index:      int,
}

exec :: proc(str: string) -> bool {
    res := platform.run_shell_command(str)
    if 0 != res {
        fmt.printfln("Error: Command '%s' failed with exit code %i", str, res)
        return false
    }
    return true
}

get_package_name_from_path :: proc() {

}

compile_hot :: proc(pkg: string, pkg_name: string, index: int) {
    path := fmt.tprintf("%s%i" + DLL_EXT, pkg_name, index)
    exec(fmt.tprintf("%s build %s -out:%s -debug -build-mode:dll", ODIN_EXE, pkg, path))
}

find_last_slash :: proc(str: string) -> int {
    a := strings.last_index_byte(str,'\\')
    b := strings.last_index_byte(str,'/')
    return max(a, b)
}

clean_hot :: proc(pkg: string) {
    remove_all(fmt.tprintf("%s*.dll", pkg))
    remove_all(fmt.tprintf("%s*.pdb", pkg))
    remove_all(fmt.tprintf("%s*.exp", pkg))
    remove_all(fmt.tprintf("%s*.lib", pkg))
    remove_all(fmt.tprintf("%s*.rdi", pkg))
}

remove_all :: proc(pattern: string) {
    log.infof("Removing all '%s'", pattern)

    iter: platform.Directory_Iter
    for path in platform.iter_directory(&iter, pattern, context.temp_allocator) {
        log.infof("removing '%s'", path)
        platform.delete_file(path)
    }
}

hotreload_find_latest_dll :: proc(pkg_name: string) -> (result: Hotreload_File, ok: bool) {
    pattern := fmt.tprintf("%s*" + DLL_EXT, pkg_name)

    max_index: int = -1

    iter: platform.Directory_Iter
    for path in platform.iter_directory(&iter, pattern, context.temp_allocator) {
        if !strings.starts_with(path, pkg_name) {
            continue
        }

        if !strings.has_suffix(path, DLL_EXT) {
            continue
        }

        index_str := path[len(pkg_name) : len(path) - len(DLL_EXT)]

        digits: int
        index, _ := strconv.parse_int(index_str, 10, &digits)

        if digits == 0 {
            continue
        }

        if index > max_index {
            max_index = index
            result = {
                path    = path,
                index   = index,
            }
            ok = true
        }
    }

    return result, ok
}

hotreload_run :: proc(pkg: string, pkg_path: string) -> bool {
    initial, initial_ok := hotreload_find_latest_dll(pkg)

    if !initial_ok {
        fmt.println("Hotreload Error: Couldn't find inital DLL for package:", pkg)
        return false
    }

    fmt.printfln("Hotreload: Loading initial module %s ...", initial.path)

    module, module_ok := load_hotreload_module(initial.path)

    if !module_ok {
        fmt.println("Hotreload Error: Failed to load initial DLL")
        return false
    }

    modules_to_unload: [dynamic]platform.Module
    append(&modules_to_unload, module.mod)

    curr_index := initial.index

    prev_data: rawptr

    watcher: platform.File_Watcher
    platform.init_file_watcher(&watcher, pkg_path)

    any_changes := false

    for {
        prev_data = module.callback(prev_data)

        if prev_data == nil {
            break
        }

        prev_any_changes := any_changes

        changes := platform.watch_file_changes(&watcher)
        for change in changes {
            log.info("Hotreload: file changed:", change)
            if strings.ends_with(change, ".odin") {
                any_changes = true
            }
        }

        if prev_any_changes && any_changes {
            any_changes = false

            // EXPERIMENTAL
            // Sometimes fails with:
            // Syntax Error: Failed to parse file: something.odin; invalid file or cannot be found
            // log.info("HOTRELOADAUTO RECOMPILING")
            // compile_hot(pkg_path, pkg, curr_index + 1)
        }

        new_file, new_ok := hotreload_find_latest_dll(pkg)
        if !new_ok {
            continue
        }


        if new_file.index > curr_index {
            // NOTE: this is expected to fail a few times while the module is compiling.
            new_module, new_module_ok := load_hotreload_module(new_file.path)
            if !new_module_ok {
                platform.sleep_ms(50)
                continue
            }

            fmt.printfln("Hotreload: Loaded %s", new_file.path)

            append(&modules_to_unload, new_module.mod)

            module = new_module
            curr_index = new_file.index
        }

        free_all(context.temp_allocator)
    }

    for lib, i in modules_to_unload {
        platform.unload_module(lib)
    }

    return true
}

load_hotreload_module :: proc(path: string) -> (result: Hotreload_Module, ok: bool) {
    module, module_ok := platform.load_module(path)
    if !module_ok {
        fmt.println("Hotreload: Failed to load library:", path)
        return {}, false
    }

    result.callback = auto_cast(platform.module_symbol_address(module, "_step"))

    if result.callback == nil {
        return {}, false
    }

    return result, true
}