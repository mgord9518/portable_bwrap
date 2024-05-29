const std = @import("std");
const builtin = @import("builtin");

var option_list: std.StringHashMap(bool) = undefined;

pub fn build(b: *std.Build) !void {
    const options = .{
        .{ "strip", "remove debug info", false },
    };

    option_list = std.StringHashMap(bool).init(b.allocator);

    const lib_options = b.addOptions();
    inline for (options) |option| {
        const opt = b.option(
            bool,
            option[0],
            option[1],
        ) orelse option[2];

        // TODO: There's probably a much better way to do this
        try option_list.put(option[0], opt);

        lib_options.addOption(bool, option[0], opt);
    }

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "bwrap",
        .target = target,
        .optimize = optimize,
        .strip = option_list.get("strip").?,
    });

    const bwrap_dep = b.dependency("bwrap", .{
        .target = target,
        .optimize = optimize,
    });

    exe.addIncludePath(.{ .path = "bubblewrap_include" });

    exe.addCSourceFiles(.{
        .root = bwrap_dep.path("."),
        .files = &.{
            "bubblewrap.c",
            "bind-mount.c",
            "network.c",
            "utils.c",
        },
        .flags = &.{
            "-D_GNU_SOURCE",
        },
    });

    {
        const libcap = try buildLibcap(b, .{
            .name = "cap",
            .target = target,
            .optimize = optimize,
            .strip = option_list.get("strip").?,
        });

        b.installArtifact(libcap);
        exe.linkLibrary(libcap);
    }

    const libcap_dep = b.dependency("libcap", .{
        .target = target,
        .optimize = optimize,
    });

    exe.addIncludePath(libcap_dep.path("libcap-2.70/libcap/include"));

    exe.linkLibC();

    const lib = b.addStaticLibrary(.{
        .name = "bwrap",
        .target = target,
        .optimize = optimize,
        .strip = option_list.get("strip").?,
    });

    lib.addIncludePath(.{ .path = "bubblewrap_include" });
    lib.addIncludePath(libcap_dep.path("libcap-2.70/libcap/include"));
    lib.addIncludePath(bwrap_dep.path("."));

    lib.addCSourceFiles(.{
        .root = bwrap_dep.path("."),
        .files = &.{
            "bind-mount.c",
            "network.c",
            "utils.c",
        },
        .flags = &.{
            "-D_GNU_SOURCE",
        },
    });

    lib.addCSourceFile(.{
        .file = .{ .path = "bubblewrap_include/bubblewrap.c" },
        .flags = &.{
            "-D_GNU_SOURCE",
        },
    });

    lib.linkLibC();

    b.installArtifact(exe);
    b.installArtifact(lib);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

pub fn buildLibcap(
    b: *std.Build,
    options: std.Build.ExecutableOptions,
) !*std.Build.Step.Compile {
    const lib = b.addStaticLibrary(.{
        .name = "cap",
        .target = options.target,
        .optimize = options.optimize,
        .strip = options.strip orelse false,
    });

    const libcap_dep = b.dependency("libcap", .{
        .target = options.target,
        .optimize = options.optimize,
    });

    lib.addIncludePath(libcap_dep.path("libcap-2.70/libcap/include"));
    lib.addIncludePath(.{ .path = "libcap_include" });

    lib.addCSourceFiles(.{
        .root = libcap_dep.path("."),
        .files = &.{
            "libcap-2.70/libcap/cap_alloc.c",
            "libcap-2.70/libcap/cap_extint.c",
            "libcap-2.70/libcap/cap_file.c",
            "libcap-2.70/libcap/cap_flag.c",
            "libcap-2.70/libcap/cap_proc.c",
            "libcap-2.70/libcap/cap_text.c",
        },
    });

    lib.linkLibC();

    return lib;
}
