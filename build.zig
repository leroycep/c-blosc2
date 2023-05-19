const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const optimize = b.standardOptimizeOption(.{});

    const libblosc2_static = b.addStaticLibrary(.{
        .name = "blosc2",
        .target = target,
        .optimize = optimize,
    });
    libblosc2_static.addCSourceFiles(&.{
        "blosc/b2nd.c",
        "blosc/b2nd_utils.c",
        "blosc/bitshuffle-altivec.c",
        "blosc/bitshuffle-avx2.c",
        "blosc/bitshuffle-generic.c",
        "blosc/bitshuffle-neon.c",
        "blosc/bitshuffle-sse2.c",
        "blosc/blosc2-stdio.c",
        "blosc/blosc2.c",
        "blosc/blosclz.c",
        "blosc/delta.c",
        "blosc/directories.c",
        "blosc/fastcopy.c",
        "blosc/frame.c",
        "blosc/schunk.c",
        "blosc/sframe.c",
        "blosc/shuffle-altivec.c",
        "blosc/shuffle-avx2.c",
        "blosc/shuffle-generic.c",
        "blosc/shuffle-neon.c",
        "blosc/shuffle-sse2.c",
        "blosc/shuffle.c",
        "blosc/stune.c",
        "blosc/timestamp.c",
        "blosc/trunc-prec.c",
    }, &.{});
    libblosc2_static.defineCMacro("BLOSC_STRICT_ALIGN", "1");
    libblosc2_static.addIncludePath("include");
    libblosc2_static.linkLibC();
    libblosc2_static.linkSystemLibrary("lz4");
    libblosc2_static.installHeader("include/blosc2.h", "blosc2.h");
    libblosc2_static.installHeader("include/b2nd.h", "b2nd.h");
    libblosc2_static.installHeadersDirectory("include/blosc2", "blosc2");
    b.installArtifact(libblosc2_static);

    // Examples
    const example_b2nd_serialize_exe = b.addExecutable(.{
        .name = "b2nd-serialize",
    });
    example_b2nd_serialize_exe.addCSourceFile("examples/b2nd/example_serialize.c", &.{});
    example_b2nd_serialize_exe.linkLibrary(libblosc2_static);
    b.installArtifact(example_b2nd_serialize_exe);
}
