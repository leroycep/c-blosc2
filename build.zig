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

    const build_plugins = b.option(bool, "build-plugins", "Build plugins") orelse false;
    const deactivate_zstd = b.option(bool, "DEACTIVATE_ZSTD", "deactivate support for zstd") orelse false;

    const lz4 = b.dependency("lz4", .{
        .target = target,
        .optimize = optimize,
    });
    const zstd = b.dependency("zstd", .{
        .target = target,
        .optimize = optimize,
    });
    const zfp = b.dependency("zfp", .{
        .target = target,
        .optimize = optimize,
    });

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
    libblosc2_static.addIncludePath("blosc");
    libblosc2_static.addIncludePath("include");
    libblosc2_static.linkLibC();
    libblosc2_static.linkLibrary(lz4.artifact("lz4hc"));
    libblosc2_static.installHeader("include/blosc2.h", "blosc2.h");
    libblosc2_static.installHeader("include/b2nd.h", "b2nd.h");
    libblosc2_static.installHeadersDirectory("include/blosc2", "blosc2");
    if (!deactivate_zstd) {
        libblosc2_static.defineCMacro("HAVE_ZSTD", "1");
        libblosc2_static.linkLibrary(zstd.artifact("zstd"));
    }
    if (build_plugins) {
        libblosc2_static.defineCMacro("HAVE_PLUGINS", "1");
        libblosc2_static.addCSourceFiles(&.{
            "plugins/plugin_utils.c",

            "plugins/filters/filters-registry.c",
            "plugins/filters/bytedelta/bytedelta.c",
            "plugins/filters/ndcell/ndcell.c",
            "plugins/filters/ndmean/ndmean.c",

            "plugins/codecs/codecs-registry.c",
            "plugins/codecs/ndlz/ndlz.c",
            "plugins/codecs/ndlz/ndlz4x4.c",
            "plugins/codecs/ndlz/ndlz8x8.c",
            "plugins/codecs/ndlz/xxhash.c",
            "plugins/codecs/zfp/blosc2-zfp.c",

            "plugins/tuners/tuners-registry.c",
        }, &.{});
        libblosc2_static.linkLibrary(zfp.artifact("zfp"));
    }
    b.installArtifact(libblosc2_static);

    // Examples
    const example_zstd_dict = b.addExecutable(.{
        .name = "example_zstd_dict",
    });
    example_zstd_dict.addCSourceFile("examples/zstd_dict.c", &.{});
    example_zstd_dict.linkLibrary(libblosc2_static);
    b.installArtifact(example_zstd_dict);

    const example_b2nd_empty_shape_exe = b.addExecutable(.{
        .name = "b2nd-example_empty_shape",
    });
    example_b2nd_empty_shape_exe.addCSourceFile("examples/b2nd/example_empty_shape.c", &.{});
    example_b2nd_empty_shape_exe.linkLibrary(libblosc2_static);
    b.installArtifact(example_b2nd_empty_shape_exe);

    const example_b2nd_frame_generator_exe = b.addExecutable(.{
        .name = "b2nd-example_frame_generator",
    });
    example_b2nd_frame_generator_exe.addCSourceFile("examples/b2nd/example_frame_generator.c", &.{});
    example_b2nd_frame_generator_exe.linkLibrary(libblosc2_static);
    b.installArtifact(example_b2nd_frame_generator_exe);

    const example_b2nd_oindex_exe = b.addExecutable(.{
        .name = "b2nd-example_oindex",
    });
    example_b2nd_oindex_exe.addCSourceFile("examples/b2nd/example_oindex.c", &.{});
    example_b2nd_oindex_exe.linkLibrary(libblosc2_static);
    b.installArtifact(example_b2nd_oindex_exe);

    const example_b2nd_plainbuffer_exe = b.addExecutable(.{
        .name = "b2nd-example_plainbuffer",
    });
    example_b2nd_plainbuffer_exe.addCSourceFile("examples/b2nd/example_plainbuffer.c", &.{});
    example_b2nd_plainbuffer_exe.linkLibrary(libblosc2_static);
    b.installArtifact(example_b2nd_plainbuffer_exe);

    if (build_plugins) {
        const example_b2nd_plugins_codecs_exe = b.addExecutable(.{
            .name = "b2nd-example_plugins_codecs",
        });
        example_b2nd_plugins_codecs_exe.addCSourceFile("examples/b2nd/example_plugins_codecs.c", &.{});
        example_b2nd_plugins_codecs_exe.linkLibrary(libblosc2_static);
        example_b2nd_plugins_codecs_exe.addIncludePath("blosc");
        b.installArtifact(example_b2nd_plugins_codecs_exe);
    }

    const example_b2nd_print_meta_exe = b.addExecutable(.{
        .name = "b2nd-example_print_meta",
    });
    example_b2nd_print_meta_exe.addCSourceFile("examples/b2nd/example_print_meta.c", &.{});
    example_b2nd_print_meta_exe.linkLibrary(libblosc2_static);
    b.installArtifact(example_b2nd_print_meta_exe);

    const example_b2nd_serialize_exe = b.addExecutable(.{
        .name = "b2nd-example_serialize",
    });
    example_b2nd_serialize_exe.addCSourceFile("examples/b2nd/example_serialize.c", &.{});
    example_b2nd_serialize_exe.linkLibrary(libblosc2_static);
    b.installArtifact(example_b2nd_serialize_exe);

    // tests
    const run_tests_step = b.step("test", "Run all tests");

    const test_compress_roundtrip_exe = b.addExecutable(.{
        .name = "test_compress_roundtrip",
    });
    test_compress_roundtrip_exe.addCSourceFile("tests/test_compress_roundtrip.c", &.{});
    test_compress_roundtrip_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_compress_roundtrip_exe);

    const test_compress_roundtrip_csv = try b.build_root.handle.readFileAlloc(b.allocator, "tests/test_compress_roundtrip.csv", 50_000);
    var test_compress_roundtrip_csv_line_iter = std.mem.tokenize(u8, test_compress_roundtrip_csv, "\n");
    _ = test_compress_roundtrip_csv_line_iter.next(); // skip csv headers
    while (test_compress_roundtrip_csv_line_iter.next()) |line| {
        const test_compress_roundtrip_run = b.addRunArtifact(test_compress_roundtrip_exe);

        var value_iter = std.mem.split(u8, line, ",");
        while (value_iter.next()) |value| {
            test_compress_roundtrip_run.addArg(value);
        }

        run_tests_step.dependOn(&test_compress_roundtrip_run.step);
    }

    const test_compressor_exe = b.addExecutable(.{
        .name = "test_compressor",
    });
    test_compressor_exe.addCSourceFile("tests/test_compressor.c", &.{});
    test_compressor_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_compressor_exe);
    const test_compressor_run = b.addRunArtifact(test_compressor_exe);
    run_tests_step.dependOn(&test_compressor_run.step);

    const test_contexts_exe = b.addExecutable(.{
        .name = "test_contexts",
    });
    test_contexts_exe.addCSourceFile("tests/test_contexts.c", &.{});
    test_contexts_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_contexts_exe);
    const test_contexts_run = b.addRunArtifact(test_contexts_exe);
    run_tests_step.dependOn(&test_contexts_run.step);

    const test_copy_exe = b.addExecutable(.{
        .name = "test_copy",
    });
    test_copy_exe.addCSourceFile("tests/test_copy.c", &.{});
    test_copy_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_copy_exe);
    const test_copy_run = b.addRunArtifact(test_copy_exe);
    run_tests_step.dependOn(&test_copy_run.step);

    const test_delete_chunk_exe = b.addExecutable(.{
        .name = "test_delete_chunk",
    });
    test_delete_chunk_exe.addCSourceFile("tests/test_delete_chunk.c", &.{});
    test_delete_chunk_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_delete_chunk_exe);
    const test_delete_chunk_run = b.addRunArtifact(test_delete_chunk_exe);
    run_tests_step.dependOn(&test_delete_chunk_run.step);

    const test_delta_exe = b.addExecutable(.{
        .name = "test_delta",
    });
    test_delta_exe.addCSourceFile("tests/test_delta.c", &.{});
    test_delta_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_delta_exe);
    const test_delta_run = b.addRunArtifact(test_delta_exe);
    run_tests_step.dependOn(&test_delta_run.step);

    const test_delta_schunk_exe = b.addExecutable(.{
        .name = "test_delta_schunk",
    });
    test_delta_schunk_exe.addCSourceFile("tests/test_delta_schunk.c", &.{});
    test_delta_schunk_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_delta_schunk_exe);
    const test_delta_schunk_run = b.addRunArtifact(test_delta_schunk_exe);
    run_tests_step.dependOn(&test_delta_schunk_run.step);

    const test_dict_schunk_exe = b.addExecutable(.{
        .name = "test_dict_schunk",
    });
    test_dict_schunk_exe.addCSourceFile("tests/test_dict_schunk.c", &.{});
    test_dict_schunk_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_dict_schunk_exe);
    const test_dict_schunk_run = b.addRunArtifact(test_dict_schunk_exe);
    run_tests_step.dependOn(&test_dict_schunk_run.step);

    const test_empty_buffer_exe = b.addExecutable(.{
        .name = "test_empty_buffer",
    });
    test_empty_buffer_exe.addCSourceFile("tests/test_empty_buffer.c", &.{});
    test_empty_buffer_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_empty_buffer_exe);
    const test_empty_buffer_run = b.addRunArtifact(test_empty_buffer_exe);
    run_tests_step.dependOn(&test_empty_buffer_run.step);

    const test_fill_special_exe = b.addExecutable(.{
        .name = "test_fill_special",
    });
    test_fill_special_exe.addCSourceFile("tests/test_fill_special.c", &.{});
    test_fill_special_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_fill_special_exe);
    const test_fill_special_run = b.addRunArtifact(test_fill_special_exe);
    run_tests_step.dependOn(&test_fill_special_run.step);

    const test_frame_exe = b.addExecutable(.{
        .name = "test_frame",
    });
    test_frame_exe.addIncludePath("blosc");
    test_frame_exe.addCSourceFile("tests/test_frame.c", &.{});
    test_frame_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_frame_exe);
    const test_frame_run = b.addRunArtifact(test_frame_exe);
    run_tests_step.dependOn(&test_frame_run.step);

    const test_frame_get_offsets_exe = b.addExecutable(.{
        .name = "test_frame_get_offsets",
    });
    test_frame_get_offsets_exe.addCSourceFile("tests/test_frame_get_offsets.c", &.{});
    test_frame_get_offsets_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_frame_get_offsets_exe);
    const test_frame_get_offsets_run = b.addRunArtifact(test_frame_get_offsets_exe);
    run_tests_step.dependOn(&test_frame_get_offsets_run.step);

    const test_frame_offset_exe = b.addExecutable(.{
        .name = "test_frame_offset",
    });
    test_frame_offset_exe.addCSourceFile("tests/test_frame_offset.c", &.{});
    test_frame_offset_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_frame_offset_exe);
    const test_frame_offset_run = b.addRunArtifact(test_frame_offset_exe);
    run_tests_step.dependOn(&test_frame_offset_run.step);

    const test_get_slice_buffer_exe = b.addExecutable(.{
        .name = "test_get_slice_buffer",
    });
    test_get_slice_buffer_exe.addCSourceFile("tests/test_get_slice_buffer.c", &.{});
    test_get_slice_buffer_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_get_slice_buffer_exe);
    const test_get_slice_buffer_run = b.addRunArtifact(test_get_slice_buffer_exe);
    run_tests_step.dependOn(&test_get_slice_buffer_run.step);

    const test_getitem_exe = b.addExecutable(.{
        .name = "test_getitem",
    });
    test_getitem_exe.addCSourceFile("tests/test_getitem.c", &.{});
    test_getitem_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_getitem_exe);

    const test_getitem = b.step("test-getitem", "Run the test_getitem tests");
    const test_getitem_csv = try b.build_root.handle.readFileAlloc(b.allocator, "tests/test_getitem.csv", 50_000);
    var test_getitem_csv_line_iter = std.mem.tokenize(u8, test_getitem_csv, "\n");
    _ = test_getitem_csv_line_iter.next(); // skip csv headers
    while (test_getitem_csv_line_iter.next()) |line| {
        const test_getitem_run = b.addRunArtifact(test_getitem_exe);

        var value_iter = std.mem.split(u8, line, ",");
        while (value_iter.next()) |value| {
            test_getitem_run.addArg(value);
        }
        test_getitem.dependOn(&test_getitem_run.step);
    }
    // run_tests_step.dependOn(test_getitem);

    const test_getitem_delta_exe = b.addExecutable(.{
        .name = "test_getitem_delta",
    });
    test_getitem_delta_exe.addCSourceFile("tests/test_getitem_delta.c", &.{});
    test_getitem_delta_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_getitem_delta_exe);
    const test_getitem_delta_run = b.addRunArtifact(test_getitem_delta_exe);
    run_tests_step.dependOn(&test_getitem_delta_run.step);

    const test_insert_chunk_exe = b.addExecutable(.{
        .name = "test_insert_chunk",
    });
    test_insert_chunk_exe.addCSourceFile("tests/test_insert_chunk.c", &.{});
    test_insert_chunk_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_insert_chunk_exe);
    const test_insert_chunk_run = b.addRunArtifact(test_insert_chunk_exe);
    run_tests_step.dependOn(&test_insert_chunk_run.step);

    const test_lazychunk_exe = b.addExecutable(.{
        .name = "test_lazychunk",
    });
    test_lazychunk_exe.addCSourceFile("tests/test_lazychunk.c", &.{});
    test_lazychunk_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_lazychunk_exe);
    const test_lazychunk_run = b.addRunArtifact(test_lazychunk_exe);
    run_tests_step.dependOn(&test_lazychunk_run.step);

    const test_lazychunk_memcpyed_exe = b.addExecutable(.{
        .name = "test_lazychunk_memcpyed",
    });
    test_lazychunk_memcpyed_exe.addCSourceFile("tests/test_lazychunk_memcpyed.c", &.{});
    test_lazychunk_memcpyed_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_lazychunk_memcpyed_exe);
    const test_lazychunk_memcpyed_run = b.addRunArtifact(test_lazychunk_memcpyed_exe);
    run_tests_step.dependOn(&test_lazychunk_memcpyed_run.step);

    const test_maskout_exe = b.addExecutable(.{
        .name = "test_maskout",
    });
    test_maskout_exe.addCSourceFile("tests/test_maskout.c", &.{});
    test_maskout_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_maskout_exe);
    const test_maskout_run = b.addRunArtifact(test_maskout_exe);
    run_tests_step.dependOn(&test_maskout_run.step);

    const test_maxout_exe = b.addExecutable(.{
        .name = "test_maxout",
    });
    test_maxout_exe.addCSourceFile("tests/test_maxout.c", &.{});
    test_maxout_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_maxout_exe);
    const test_maxout_run = b.addRunArtifact(test_maxout_exe);
    run_tests_step.dependOn(&test_maxout_run.step);

    const test_noinit_exe = b.addExecutable(.{
        .name = "test_noinit",
    });
    test_noinit_exe.addCSourceFile("tests/test_noinit.c", &.{});
    test_noinit_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_noinit_exe);
    const test_noinit_run = b.addRunArtifact(test_noinit_exe);
    run_tests_step.dependOn(&test_noinit_run.step);

    const test_nolock_exe = b.addExecutable(.{
        .name = "test_nolock",
    });
    test_nolock_exe.addCSourceFile("tests/test_nolock.c", &.{});
    test_nolock_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_nolock_exe);
    const test_nolock_run = b.addRunArtifact(test_nolock_exe);
    run_tests_step.dependOn(&test_nolock_run.step);

    const test_nthreads_exe = b.addExecutable(.{
        .name = "test_nthreads",
    });
    test_nthreads_exe.addCSourceFile("tests/test_nthreads.c", &.{});
    test_nthreads_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_nthreads_exe);
    const test_nthreads_run = b.addRunArtifact(test_nthreads_exe);
    run_tests_step.dependOn(&test_nthreads_run.step);

    const test_postfilter_exe = b.addExecutable(.{
        .name = "test_postfilter",
    });
    test_postfilter_exe.addCSourceFile("tests/test_postfilter.c", &.{});
    test_postfilter_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_postfilter_exe);
    const test_postfilter_run = b.addRunArtifact(test_postfilter_exe);
    run_tests_step.dependOn(&test_postfilter_run.step);

    const test_prefilter_exe = b.addExecutable(.{
        .name = "test_prefilter",
    });
    test_prefilter_exe.addCSourceFile("tests/test_prefilter.c", &.{});
    test_prefilter_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_prefilter_exe);
    const test_prefilter_run = b.addRunArtifact(test_prefilter_exe);
    run_tests_step.dependOn(&test_prefilter_run.step);

    const test_reorder_offsets_exe = b.addExecutable(.{
        .name = "test_reorder_offsets",
    });
    test_reorder_offsets_exe.addCSourceFile("tests/test_reorder_offsets.c", &.{});
    test_reorder_offsets_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_reorder_offsets_exe);
    const test_reorder_offsets_run = b.addRunArtifact(test_reorder_offsets_exe);
    run_tests_step.dependOn(&test_reorder_offsets_run.step);

    const test_schunk_exe = b.addExecutable(.{
        .name = "test_schunk",
    });
    test_schunk_exe.addCSourceFile("tests/test_schunk.c", &.{});
    test_schunk_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_schunk_exe);
    const test_schunk_run = b.addRunArtifact(test_schunk_exe);
    run_tests_step.dependOn(&test_schunk_run.step);

    const test_schunk_frame_exe = b.addExecutable(.{
        .name = "test_schunk_frame",
    });
    test_schunk_frame_exe.addCSourceFile("tests/test_schunk_frame.c", &.{});
    test_schunk_frame_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_schunk_frame_exe);
    const test_schunk_frame_run = b.addRunArtifact(test_schunk_frame_exe);
    run_tests_step.dependOn(&test_schunk_frame_run.step);

    const test_schunk_header_exe = b.addExecutable(.{
        .name = "test_schunk_header",
    });
    test_schunk_header_exe.addCSourceFile("tests/test_schunk_header.c", &.{});
    test_schunk_header_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_schunk_header_exe);
    const test_schunk_header_run = b.addRunArtifact(test_schunk_header_exe);
    run_tests_step.dependOn(&test_schunk_header_run.step);

    const test_set_slice_buffer_exe = b.addExecutable(.{
        .name = "test_set_slice_buffer",
    });
    test_set_slice_buffer_exe.addCSourceFile("tests/test_set_slice_buffer.c", &.{});
    test_set_slice_buffer_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_set_slice_buffer_exe);
    const test_set_slice_buffer_run = b.addRunArtifact(test_set_slice_buffer_exe);
    run_tests_step.dependOn(&test_set_slice_buffer_run.step);

    const test_sframe_exe = b.addExecutable(.{
        .name = "test_sframe",
    });
    test_sframe_exe.addCSourceFile("tests/test_sframe.c", &.{});
    test_sframe_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_sframe_exe);
    const test_sframe_run = b.addRunArtifact(test_sframe_exe);
    run_tests_step.dependOn(&test_sframe_run.step);

    const test_sframe_lazychunk_exe = b.addExecutable(.{
        .name = "test_sframe_lazychunk",
    });
    test_sframe_lazychunk_exe.addCSourceFile("tests/test_sframe_lazychunk.c", &.{});
    test_sframe_lazychunk_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_sframe_lazychunk_exe);
    const test_sframe_lazychunk_run = b.addRunArtifact(test_sframe_lazychunk_exe);
    run_tests_step.dependOn(&test_sframe_lazychunk_run.step);

    const test_shuffle_roundtrip_altivec_exe = b.addExecutable(.{
        .name = "test_shuffle_roundtrip_altivec",
    });
    test_shuffle_roundtrip_altivec_exe.addCSourceFile("tests/test_shuffle_roundtrip_altivec.c", &.{});
    test_shuffle_roundtrip_altivec_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_shuffle_roundtrip_altivec_exe);

    const test_shuffle_roundtrip_altivec = b.step("test-shuffle-roundtrip-altivec", "Run the test_shuffle_roundtrip_altivec tests");

    const test_shuffle_roundtrip_altivec_csv = try b.build_root.handle.readFileAlloc(b.allocator, "tests/test_shuffle_roundtrip_altivec.csv", 50_000);
    var test_shuffle_roundtrip_altivec_csv_line_iter = std.mem.tokenize(u8, test_shuffle_roundtrip_altivec_csv, "\n");
    _ = test_shuffle_roundtrip_altivec_csv_line_iter.next(); // skip csv headers
    while (test_shuffle_roundtrip_altivec_csv_line_iter.next()) |line| {
        const test_shuffle_roundtrip_altivec_run = b.addRunArtifact(test_shuffle_roundtrip_altivec_exe);

        var value_iter = std.mem.split(u8, line, ",");
        while (value_iter.next()) |value| {
            test_shuffle_roundtrip_altivec_run.addArg(value);
        }

        test_shuffle_roundtrip_altivec.dependOn(&test_shuffle_roundtrip_altivec_run.step);
    }
    // run_tests_step.dependOn(test_shuffle_roundtrip_altivec);

    const test_shuffle_roundtrip_avx2_exe = b.addExecutable(.{
        .name = "test_shuffle_roundtrip_avx2",
    });
    test_shuffle_roundtrip_avx2_exe.addCSourceFile("tests/test_shuffle_roundtrip_avx2.c", &.{});
    test_shuffle_roundtrip_avx2_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_shuffle_roundtrip_avx2_exe);

    const test_shuffle_roundtrip_avx2 = b.step("test-shuffle-roundtrip-avx2", "Run the test_shuffle_roundtrip_avx2 tests");
    const test_shuffle_roundtrip_avx2_csv = try b.build_root.handle.readFileAlloc(b.allocator, "tests/test_shuffle_roundtrip_avx2.csv", 50_000);
    var test_shuffle_roundtrip_avx2_csv_line_iter = std.mem.tokenize(u8, test_shuffle_roundtrip_avx2_csv, "\n");
    _ = test_shuffle_roundtrip_avx2_csv_line_iter.next(); // skip csv headers
    while (test_shuffle_roundtrip_avx2_csv_line_iter.next()) |line| {
        const test_shuffle_roundtrip_avx2_run = b.addRunArtifact(test_shuffle_roundtrip_avx2_exe);

        var value_iter = std.mem.split(u8, line, ",");
        while (value_iter.next()) |value| {
            test_shuffle_roundtrip_avx2_run.addArg(value);
        }

        test_shuffle_roundtrip_avx2.dependOn(&test_shuffle_roundtrip_avx2_run.step);
    }
    // run_tests_step.dependOn(test_shuffle_roundtrip_avx2);

    const test_shuffle_roundtrip_generic_exe = b.addExecutable(.{
        .name = "test_shuffle_roundtrip_generic",
    });
    test_shuffle_roundtrip_generic_exe.addCSourceFile("tests/test_shuffle_roundtrip_generic.c", &.{});
    test_shuffle_roundtrip_generic_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_shuffle_roundtrip_generic_exe);

    const test_shuffle_roundtrip_generic = b.step("test-shuffle-roundtrip-generic", "Run the test_shuffle_roundtrip_generic tests");
    const test_shuffle_roundtrip_generic_csv = try b.build_root.handle.readFileAlloc(b.allocator, "tests/test_shuffle_roundtrip_generic.csv", 50_000);
    var test_shuffle_roundtrip_generic_csv_line_iter = std.mem.tokenize(u8, test_shuffle_roundtrip_generic_csv, "\n");
    _ = test_shuffle_roundtrip_generic_csv_line_iter.next(); // skip csv headers
    while (test_shuffle_roundtrip_generic_csv_line_iter.next()) |line| {
        const test_shuffle_roundtrip_generic_run = b.addRunArtifact(test_shuffle_roundtrip_generic_exe);

        var value_iter = std.mem.split(u8, line, ",");
        while (value_iter.next()) |value| {
            test_shuffle_roundtrip_generic_run.addArg(value);
        }

        test_shuffle_roundtrip_generic.dependOn(&test_shuffle_roundtrip_generic_run.step);
    }
    // run_tests_step.dependOn(test_shuffle_roundtrip_generic);

    const test_shuffle_roundtrip_neon_exe = b.addExecutable(.{
        .name = "test_shuffle_roundtrip_neon",
    });
    test_shuffle_roundtrip_neon_exe.addCSourceFile("tests/test_shuffle_roundtrip_neon.c", &.{});
    test_shuffle_roundtrip_neon_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_shuffle_roundtrip_neon_exe);

    const test_shuffle_roundtrip_neon = b.step("test-shuffle-roundtrip-neon", "Run the test_shuffle_roundtrip_neon tests");
    const test_shuffle_roundtrip_neon_csv = try b.build_root.handle.readFileAlloc(b.allocator, "tests/test_shuffle_roundtrip_neon.csv", 50_000);
    var test_shuffle_roundtrip_neon_csv_line_iter = std.mem.tokenize(u8, test_shuffle_roundtrip_neon_csv, "\n");
    _ = test_shuffle_roundtrip_neon_csv_line_iter.next(); // skip csv headers
    while (test_shuffle_roundtrip_neon_csv_line_iter.next()) |line| {
        const test_shuffle_roundtrip_neon_run = b.addRunArtifact(test_shuffle_roundtrip_neon_exe);

        var value_iter = std.mem.split(u8, line, ",");
        while (value_iter.next()) |value| {
            test_shuffle_roundtrip_neon_run.addArg(value);
        }

        test_shuffle_roundtrip_neon.dependOn(&test_shuffle_roundtrip_neon_run.step);
    }
    // run_tests_step.dependOn(test_shuffle_roundtrip_neon);

    const test_shuffle_roundtrip_sse2_exe = b.addExecutable(.{
        .name = "test_shuffle_roundtrip_sse2",
    });
    test_shuffle_roundtrip_sse2_exe.addCSourceFile("tests/test_shuffle_roundtrip_sse2.c", &.{});
    test_shuffle_roundtrip_sse2_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_shuffle_roundtrip_sse2_exe);

    const test_shuffle_roundtrip_sse2 = b.step("test-shuffle-roundtrip-sse2", "Run the test_shuffle_roundtrip_sse2 tests");
    const test_shuffle_roundtrip_sse2_csv = try b.build_root.handle.readFileAlloc(b.allocator, "tests/test_shuffle_roundtrip_sse2.csv", 50_000);
    var test_shuffle_roundtrip_sse2_csv_line_iter = std.mem.tokenize(u8, test_shuffle_roundtrip_sse2_csv, "\n");
    _ = test_shuffle_roundtrip_sse2_csv_line_iter.next(); // skip csv headers
    while (test_shuffle_roundtrip_sse2_csv_line_iter.next()) |line| {
        const test_shuffle_roundtrip_sse2_run = b.addRunArtifact(test_shuffle_roundtrip_sse2_exe);

        var value_iter = std.mem.split(u8, line, ",");
        while (value_iter.next()) |value| {
            test_shuffle_roundtrip_sse2_run.addArg(value);
        }

        test_shuffle_roundtrip_sse2.dependOn(&test_shuffle_roundtrip_sse2_run.step);
    }
    // run_tests_step.dependOn(test_shuffle_roundtrip_sse2);

    const test_small_chunks_exe = b.addExecutable(.{
        .name = "test_small_chunks",
    });
    test_small_chunks_exe.addCSourceFile("tests/test_small_chunks.c", &.{});
    test_small_chunks_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_small_chunks_exe);
    const test_small_chunks_run = b.addRunArtifact(test_small_chunks_exe);
    run_tests_step.dependOn(&test_small_chunks_run.step);

    const test_udio_exe = b.addExecutable(.{
        .name = "test_udio",
    });
    test_udio_exe.addCSourceFile("tests/test_udio.c", &.{});
    test_udio_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_udio_exe);
    const test_udio_run = b.addRunArtifact(test_udio_exe);
    run_tests_step.dependOn(&test_udio_run.step);

    const test_update_chunk_exe = b.addExecutable(.{
        .name = "test_update_chunk",
    });
    test_update_chunk_exe.addCSourceFile("tests/test_update_chunk.c", &.{});
    test_update_chunk_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_update_chunk_exe);
    const test_update_chunk_run = b.addRunArtifact(test_update_chunk_exe);
    run_tests_step.dependOn(&test_update_chunk_run.step);

    const test_urcodecs_exe = b.addExecutable(.{
        .name = "test_urcodecs",
    });
    test_urcodecs_exe.addCSourceFile("tests/test_urcodecs.c", &.{});
    test_urcodecs_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_urcodecs_exe);
    const test_urcodecs_run = b.addRunArtifact(test_urcodecs_exe);
    run_tests_step.dependOn(&test_urcodecs_run.step);

    const test_urfilters_exe = b.addExecutable(.{
        .name = "test_urfilters",
    });
    test_urfilters_exe.addCSourceFile("tests/test_urfilters.c", &.{});
    test_urfilters_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_urfilters_exe);
    const test_urfilters_run = b.addRunArtifact(test_urfilters_exe);
    run_tests_step.dependOn(&test_urfilters_run.step);

    const test_zero_runlen_exe = b.addExecutable(.{
        .name = "test_zero_runlen",
    });
    test_zero_runlen_exe.addCSourceFile("tests/test_zero_runlen.c", &.{});
    test_zero_runlen_exe.linkLibrary(libblosc2_static);
    b.installArtifact(test_zero_runlen_exe);
    const test_zero_runlen_run = b.addRunArtifact(test_zero_runlen_exe);
    run_tests_step.dependOn(&test_zero_runlen_run.step);
}
