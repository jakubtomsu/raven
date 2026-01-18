package raven_build

import "core:strconv"
import "core:strings"
import "core:fmt"
import "../platform"

WASM_PAGE_SIZE :: 65536

DEFAULT_INITIAL_MEM_PAGES :: 2000
DEFAULT_MAX_MEM_PAGES :: 65536

/*
REM NOTE: changing this requires changing the same values in the `web/index.html`.
echo off
del triangle.wasm

set INITIAL_MEMORY_PAGES=2000
set MAX_MEMORY_PAGES=65536

set PAGE_SIZE=65536
set /a INITIAL_MEMORY_BYTES=%INITIAL_MEMORY_PAGES% * %PAGE_SIZE%
set /a MAX_MEMORY_BYTES=%MAX_MEMORY_PAGES% * %PAGE_SIZE%

@REM set ODIN_ROOT="D:\Odin\"


call odin.exe build . -target:js_wasm32 -debug -out:web/triangle.wasm -o:size -extra-linker-flags:"--export-table --import-memory --initial-memory=%INITIAL_MEMORY_BYTES% --max-memory=%MAX_MEMORY_BYTES%"

@REM for /f "delims=" %%i in ('odin.exe root') do set "ODIN_ROOT=%%i"
copy "D:\Odin\vendor\wgpu\wgpu.js" "web\wgpu.js"
copy "D:\Odin\core\sys\wasm\js\odin.js" "web\odin.js"
*/

export_web :: proc(dst_dir: string, pkg_name: string, pkg_path: string) {
    remove_all(strings.concatenate({dst_dir, platform.SEPARATOR, "*"}))
    platform.create_directory(dst_dir)

    initial_mem_pages := DEFAULT_INITIAL_MEM_PAGES
    max_mem_pages := DEFAULT_MAX_MEM_PAGES

    fmt.println("Compiling WASM ...")

    if !compile_web(dst_dir,
        pkg_name = pkg_name,
        pkg_path = pkg_path,
        initial_mem_pages = initial_mem_pages,
        max_mem_pages = max_mem_pages,
    ) {
        fmt.println("Error: failed to compile to WASM")
        return
    }

    fmt.println("Generating HTML and JS files ...")

    html := generate_html(
        title = pkg_name,
        pkg_name = pkg_name,
        initial_mem_pages = initial_mem_pages,
        max_mem_pages = max_mem_pages,
    )

    fmt.println(html)

    platform.write_file_by_path(
        fmt.tprintf("%s/index.html", dst_dir),
        transmute([]byte)html,
    )

    clone_file(
        fmt.tprintf("%s/odin.js", dst_dir),
        fmt.tprintf("%score/sys/wasm/js/odin.js", ODIN_ROOT),
    )

    clone_file(
        fmt.tprintf("%s/wgpu.js", dst_dir),
        fmt.tprintf("%svendor/wgpu/wgpu.js", ODIN_ROOT),
    )
}

clone_file :: proc(dst, src: string) {
    fmt.printfln("Copying %s -> %s", src, dst)
    platform.clone_file(dst, src)
}

compile_web :: proc(dst_dir: string, pkg_name: string, pkg_path: string, initial_mem_pages: int, max_mem_pages: int) -> bool {
    OPT_FLAGS :: "-o:size -debug "

    FORMAT :: "%s build %s -target:js_wasm32 -out:%s/%s.wasm " +
        OPT_FLAGS +
        "-extra-linker-flags:\"--export-table --import-memory --initial-memory=%i --max-memory=%i\""

    return exec(fmt.tprintf(FORMAT, ODIN_EXE, pkg_path, dst_dir, pkg_name,
        initial_mem_pages * WASM_PAGE_SIZE,
        max_mem_pages * WASM_PAGE_SIZE,
    ))
}

generate_html :: proc(
    title:              string,
    pkg_name:           string,
    initial_mem_pages:  int,
    max_mem_pages:      int,
) -> string {
    html := HTML_TEMPLATE

    // hacky

    buf: [256]u8

    html, _ = strings.replace_all(html, "@pkg", pkg_name)
    html, _ = strings.replace_all(html, "@title", title)
    html, _ = strings.replace_all(html, "@initial_mem_pages", strconv.write_int(buf[:], i64(initial_mem_pages), 10))
    html, _ = strings.replace_all(html, "@max_mem_pages", strconv.write_int(buf[:], i64(max_mem_pages), 10))

    return html
}

HTML_TEMPLATE :: `
<!DOCTYPE html>
<html lang="en" style="height: 100%;">
	<head>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1">
		<title>@title</title>
	</head>
	<body id="body" style="height: 100%; padding: 0; margin: 0; overflow: hidden;">
		<canvas id="raven-canvas" style="height: 100%; width: 100%;"></canvas>

		<script type="text/javascript" src="odin.js"></script>
		<script type="text/javascript" src="wgpu.js"></script>
		<script type="text/javascript">
			const mem = new WebAssembly.Memory({ initial: @initial_mem_pages, maximum: @max_mem_pages, shared: false });
			const memInterface = new odin.WasmMemoryInterface();
			memInterface.setMemory(mem);

			const wgpuInterface = new odin.WebGPUInterface(memInterface);

			odin.runWasm("@pkg.wasm", null, { wgpu: wgpuInterface.getInterface() }, memInterface, /*intSize=8*/);
		</script>
	</body>
</html>
`