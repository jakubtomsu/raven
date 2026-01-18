#+vet explicit-allocators shadowing unused
package raven

import "core:math"
import "core:math/linalg"
import "base:intrinsics"

// TODO: non ugly colors?
WHITE       :: Vec4{1, 1, 1, 1}
BLACK       :: Vec4{0, 0, 0, 1}
TRANSPARENT :: Vec4{1, 1, 1, 0}
GRAY        :: Vec4{0.5, 0.5, 0.5, 1}
DARK_GRAY   :: Vec4{0.25, 0.25, 0.25, 1}
LIGHT_GRAY  :: Vec4{0.75, 0.75, 0.75, 1}
RED         :: Vec4{1, 0, 0, 1}
GREEN       :: Vec4{0, 1, 0, 1}
BLUE        :: Vec4{0, 0, 1, 1}
YELLOW      :: Vec4{1, 1, 0, 1}
CYAN        :: Vec4{0, 1, 1, 1}
PINK        :: Vec4{1, 0, 1, 1}
ORANGE      :: Vec4{1, 0.5, 0, 1}
PURPLE      :: Vec4{0.5, 0, 1, 1}

@(require_results)
deg :: proc "contextless" (degrees: f32) -> f32 {
    return degrees * math.RAD_PER_DEG
}

@(require_results)
lerp :: proc "contextless" (a, b: $T, t: f32) -> T where !intrinsics.type_is_quaternion(T) {
    return a * (1 - t) + b * t
}

// Exponential lerp. Multiply rate by delta to get frame rate independent interpolation
@(require_results)
lexp :: proc "contextless" (a, b: $T, rate: f32) -> T {
    return lerp(b, a, math.exp_f32(-rate))
}

@(require_results)
nlerp :: proc "contextless" (a, b: $T, t: f32) -> T {
    return linalg.normalize0(lerp(a, b, t))
}

@(require_results)
nlexp :: proc "contextless" (a, b: $T, rate: f32) -> T {
    return nlerp(b, a, math.exp_f32(-rate))
}

@(require_results)
fade :: #force_inline proc "contextless" (alpha: f32) -> Vec4 {
    return {1, 1, 1, alpha}
}

@(require_results)
gray :: #force_inline proc "contextless" (val: f32) -> Vec4 {
    return {val, val, val, 1}
}

@(require_results)
addz :: #force_inline proc "contextless" (v: Vec2, z: f32 = 0.0) -> Vec3 {
    return {v.x, v.y, z}
}

@(require_results)
nsin :: proc "contextless" (x: f32) -> f32 {
    return 0.5 + 0.5 * math.sin_f32(x * math.PI * 2)
}

@(require_results)
vcast :: proc "contextless" ($T: typeid, v: [$N]$E) -> (result: [N]T)
    where intrinsics.type_is_integer(E) || intrinsics.type_is_float(E)
{
    for elem, i in v {
        result[i] = cast(T)elem
    }
    return result
}

// Counter-clockwise. Negate to do clockwise.
@(require_results)
rot90 :: #force_inline proc "contextless" (v: [2]$T) -> [2]T {
    return {-v.y, v.x}
}


// Returns value in 0..1 range.
// Same as remap(t, a, b, 0, 1)
@(require_results)
unlerp :: proc "contextless" (a, b: $T, t: f32) -> T {
    return (t - a) / (b - a)
}

// Linearly transform x from range a0..a1 to b0..b1
@(require_results)
remap :: proc "contextless" (x, a0, a1, b0, b1: f32) -> f32 {
    return ((x - a0) / (a1 - a0)) * (b1 - b0) + b0
}

@(require_results)
remap_clamped :: #force_inline proc "contextless" (x, a0, a1, b0, b1: f32) -> f32 {
    return remap(clamp(x, a0, a1), a0, a1, b0, b1)
}

@(require_results)
smoothstep :: proc "contextless" (edge0, edge1, x: f32) -> f32 {
    t := clamp((x - edge0) / (edge1 - edge0), 0.0, 1)
    return t * t * (3.0 - 2.0 * t)
}

@(require_results)
luminance :: proc "contextless" (rgb: Vec3) -> f32 {
    return linalg.dot(rgb, Vec3{0.2126, 0.7152, 0.0722})
}

// RGB only!
@(require_results)
hex_color :: proc "contextless" (hex: u32) -> Vec4 {
    bytes := transmute([4]u8)hex

    return {
        f32(bytes[2]) / 255.0,
        f32(bytes[1]) / 255.0,
        f32(bytes[0]) / 255.0,
        1.0,
    }
}

// Oklab lerp - Better color gradients than regular lerp()
@(require_results)
oklerp :: proc "contextless" (a, b: Vec4, t: f32) -> (result: Vec4) {
    // https://bottosson.github.io/posts/oklab
    // https://www.shadertoy.com/view/ttcyRS
    CONE_TO_LMS :: Mat3{0.4121656120, 0.2118591070, 0.0883097947, 0.5362752080, 0.6807189584, 0.2818474174, 0.0514575653, 0.1074065790, 0.6302613616}
    LMS_TO_CONE :: Mat3{4.0767245293, -1.2681437731, -0.0041119885, -3.3072168827, 2.6093323231, -0.7034763098, 0.2307590544, -0.3411344290, 1.7068625689}

    // rgb to cone (arg of pow can't be negative)
    lms_a := linalg.pow(CONE_TO_LMS * a.rgb, 1 / 3.0)
    lms_b := linalg.pow(CONE_TO_LMS * b.rgb, 1 / 3.0)
    lms := lerp(lms_a, lms_b, t)
    // gain in the middle (no oaklab anymore, but looks better?)
    // lms *= 1+0.2*h*(1-h);
    // cone to rgb
    result.rgb = LMS_TO_CONE * (lms * lms * lms)
    result.a = lerp(a.a, b.a, t)
    return result
}

// 0 -> Red, 0.5 -> Blue, 1 -> Green
@(require_results)
heatmap_color :: proc(val: f32) -> (result: Vec4) {
    result.g = smoothstep(0.5, 0.8, val)
    if (val > 0.5) {
        result.b = smoothstep(1, 0.5, val)
    } else {
        result.b = smoothstep(0.0, 0.5, val)
    }
    result.r = smoothstep(1, 0.0, val)
    result.a = 1
    return result
}


