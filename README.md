<div align="center">

# RAVEN
A toolkit for making stylized 2D and 3D games in Odin

***WARNING: EARLY ALPHA VERSION***
Do NOT use for anything serious yet.

[Discord](https://discord.com/invite/wn5jMMMYe4)

</div>

## Goal
A game library made specifically for small indie teams and fast iteration times.
Something *simple* you can prototype in, but also *stable* enough to make polishing a full game straightforward.

Batteries-included toolkit for the entire code and asset pipeline.

Inspired by Raylib, Sokol and PICO8.

## Features
- First-class 3D support
- Hotreloading by default
    - code, textures, models, even custom files
- Modular architecture
    - the `platform`, `gpu` and `audio` packages can be used independently from the Raven engine
- Minimal dependencies
    - the core of the engine is implemented fully from scratch, see `platform` and `gpu`

#### In-progress
- Shader Transpiler

## Prequisities
Install [Odin](https://github.com/odin-lang/Odin) and make sure it's in your path. Check the [Official Install docs](https://odin-lang.org/docs/install/) for more info.

There are no additional dependencies.

## Examples

You can run demos from the [examples/](examples) directory with something like the following command:
```
odin run examples\hello
```

Alternatively you can run them in hot-reload mode:
```
odin run build -- run_hot examples\hello
```


## Hot-reload

All assets are hotreloaded automatically, just pass `watch = true` flag when loading an asset directory.

Code can be hot


## Contributing
For info about bug reports and contributing, see [CONTRIBUTING](CONTRIBUTING.md)



# Docs

TODO - minimal example


## Engine Structure
```
raven
├─ platform
│  ├─ win32
│  ├─ js
├─ gpu
│  ├─ d3d11
│  ├─ wgpu
├─ audio
│  ├─ miniaudio
```

There's also additional tooling like the `build` package.


## Cheatsheet

TODO - list most common functions in an easily searchable way

### Utils
```odin
deg(degrees: f32) -> f32                    // Convert degrees to radians
lerp(a, b: $T, t: f32) -> T                 // Linearly interpolate between A and B
lexp(a, b: $T, rate: f32) -> T              // Exponential lerp for things like 'a = lexp(a, target, delta*10)'
fade(alpha: f32) -> Vec4                    // Make a white color with a given alpha value
gray(val: f32) -> Vec4                      // Value = 0 means black, = 1 means white
vcast($T: typeid, v: [$N]$E) -> [N]T        // Cast from one type of vector to another
rot90(v: [2]$T) -> [2]T                     // Rotate a 2D vector 90 degrees counter-clockwise
unlerp(a, b: f32, x: f32) -> T              // Map x from range a..b to 0..1
remap(x, a0, a1, b0, b1: f32) -> f32        // Map x from range a0..a1 to b0..b1
smoothstep(edge0, edge1, x: f32) -> f32     // Generates a smooth curve from x in range edge0..edge1
oklerp(a, b: Vec4, t: f32) -> Vec4          // Interpolate colors with OKLAB
```

### Assets

```odin
load_asset_directory(path: string, watch: bool)
load_constant_asset_directory(#load_directory(path: string))
```

### Drawing

```odin
draw_sprite(...)
draw_mesh(...)
draw_triangle(...)
draw_line(...)
draw_text(...)
```

### Input

```odin
mouse_pos() -> [2]f32
mouse_delta() -> [2]f32
scroll_delta() -> [2]f32
key_down(key: Key) -> bool
key_down_time(key: Key) -> f32
key_pressed(key: Key, buf: f32 = 0) -> bool
key_repeated(key: Key) -> bool
key_released(key: Key) -> bool
mouse_down(button: Mouse_Button) -> bool
mouse_down_time(button: Mouse_Button) -> f32
mouse_pressed(button: Mouse_Button, buf: f32 = 0) -> bool
mouse_repeated(button: Mouse_Button) -> bool
mouse_released(button: Mouse_Button) -> bool
```