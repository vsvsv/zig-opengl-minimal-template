const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const glfw = GlfwBuilder("./libs/glfw").init(b, target, optimize);
    exe_module.addCMacro("GLFW_INCLUDE_NONE", "1");
    exe_module.addIncludePath(b.path(glfw.include_path));
    exe_module.linkLibrary(glfw.lib);

    const glad = GladBuilder("./libs/glad").init(b, target, optimize);
    exe_module.addIncludePath(b.path(glad.include_path));
    exe_module.linkLibrary(glad.lib);

    const exe = b.addExecutable(.{
        .name = "ZigOpenGLExample",
        .root_module = exe_module,
    });
    addRunStep(b, exe);
    addTests(b, exe);
}

fn addRunStep(b: *std.Build, exe: *std.Build.Step.Compile) void {
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

fn addTests(
    b: *std.Build,
    exe: *std.Build.Step.Compile,
) void {
    const exe_unit_tests = b.addTest(.{ .root_module = exe.root_module });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}

pub fn GladBuilder(comptime glad_path: []const u8) type {
    const path = blk: {
        if (glad_path[glad_path.len - 1] == '/') {
            break :blk glad_path;
        }
        break :blk glad_path ++ "/";
    };
    return struct {
        const Self = @This();

        lib: *std.Build.Step.Compile,
        include_path: []const u8,

        pub fn init(
            b: *std.Build,
            target: std.Build.ResolvedTarget,
            optimize: std.builtin.OptimizeMode,
        ) Self {
            const lib_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
            });

            const include_path = path ++ "include";
            lib_module.addIncludePath(b.path(include_path));
            lib_module.link_libc = true;

            var flags = std.array_list.Managed([]const u8).init(b.allocator);
            flags.append("-Isrc") catch unreachable;
            if (optimize != .Debug) {
                flags.append("-Ofast") catch unreachable;
                flags.append("-ffast-math") catch unreachable;
            }

            lib_module.addCSourceFiles(.{ .files = &[_][]const u8{path ++ "src/gl.c"}, .flags = flags.items });

            return Self{
                .lib = std.Build.Step.Compile.create(b, .{
                    .name = "glad",
                    .kind = .lib,
                    .linkage = .static,
                    .root_module = lib_module,
                }),
                .include_path = include_path,
            };
        }
    };
}

pub fn GlfwBuilder(comptime glfw_path: []const u8) type {
    const path = blk: {
        if (glfw_path[glfw_path.len - 1] == '/') {
            break :blk glfw_path;
        }
        break :blk glfw_path ++ "/";
    };
    return struct {
        const Self = @This();

        lib: *std.Build.Step.Compile,
        include_path: []const u8,

        pub fn init(
            b: *std.Build,
            target: std.Build.ResolvedTarget,
            optimize: std.builtin.OptimizeMode,
        ) Self {
            const lib_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
            });

            const include_path = path ++ "include";
            lib_module.addIncludePath(b.path(include_path));
            lib_module.link_libc = true;

            var flags = std.array_list.Managed([]const u8).init(b.allocator);
            flags.append("-Isrc") catch unreachable;
            if (optimize != .Debug) {
                flags.append("-Ofast") catch unreachable;
                flags.append("-ffast-math") catch unreachable;
            }

            const SOURCES = Self.getSources();

            if (target.result.isDarwinLibC()) {
                lib_module.addCMacro("__kernel_ptr_semantics", "");

                flags.append("-D_GLFW_COCOA") catch unreachable;
                lib_module.addCSourceFiles(.{
                    .files = &SOURCES.macos,
                    .flags = flags.items,
                });

                lib_module.linkSystemLibrary("objc", .{});
                lib_module.linkFramework("IOKit", .{});
                lib_module.linkFramework("CoreFoundation", .{});
                lib_module.linkFramework("AppKit", .{});
                lib_module.linkFramework("CoreGraphics", .{});
                lib_module.linkFramework("Foundation", .{});
                lib_module.linkFramework("QuartzCore", .{});
            } else if (target.result.os.tag == .windows) {
                flags.append("-D_GLFW_WIN32") catch unreachable;

                lib_module.addCSourceFiles(.{
                    .files = &SOURCES.windows,
                    .flags = flags.items,
                });

                lib_module.linkSystemLibrary("gdi32", .{});
                lib_module.linkSystemLibrary("user32", .{});
                lib_module.linkSystemLibrary("shell32", .{});
            } else { // All others are considered Linux-like
                flags.append("-D_GLFW_X11") catch unreachable;
                lib_module.addCSourceFiles(.{
                    .files = &SOURCES.linux,
                    .flags = flags.items,
                });
                lib_module.linkSystemLibrary("X11", .{});
            }

            return Self{
                .lib = std.Build.Step.Compile.create(b, .{
                    .name = "glfw",
                    .kind = .lib,
                    .linkage = .static,
                    .root_module = lib_module,
                }),
                .include_path = include_path,
            };
        }

        pub fn getSources() type {
            const sources = blk: {
                const sources_common = [_][]const u8{
                    path ++ "src/context.c",
                    path ++ "src/egl_context.c",
                    path ++ "src/init.c",
                    path ++ "src/input.c",
                    path ++ "src/monitor.c",
                    path ++ "src/null_init.c",
                    path ++ "src/null_joystick.c",
                    path ++ "src/null_monitor.c",
                    path ++ "src/null_window.c",
                    path ++ "src/osmesa_context.c",
                    path ++ "src/platform.c",
                    path ++ "src/vulkan.c",
                    path ++ "src/window.c",
                };
                const sources_macos = [_][]const u8{
                    path ++ "src/cocoa_time.c",
                    path ++ "src/posix_module.c",
                    path ++ "src/posix_thread.c",

                    path ++ "src/cocoa_init.m",
                    path ++ "src/cocoa_joystick.m",
                    path ++ "src/cocoa_monitor.m",
                    path ++ "src/cocoa_window.m",
                    path ++ "src/nsgl_context.m",
                };
                const sources_linux = [_][]const u8{
                    path ++ "src/linux_joystick.c",
                    path ++ "src/posix_module.c",
                    path ++ "src/posix_poll.c",
                    path ++ "src/posix_thread.c",
                    path ++ "src/posix_time.c",
                    path ++ "src/xkb_unicode.c",
                    // X11 headers
                    path ++ "src/x11_init.c",
                    path ++ "src/x11_monitor.c",
                    path ++ "src/x11_window.c",
                    path ++ "src/glx_context.c",
                };
                const sources_windows = [_][]const u8{
                    path ++ "src/wgl_context.c",
                    path ++ "src/win32_init.c",
                    path ++ "src/win32_joystick.c",
                    path ++ "src/win32_module.c",
                    path ++ "src/win32_monitor.c",
                    path ++ "src/win32_thread.c",
                    path ++ "src/win32_time.c",
                    path ++ "src/win32_window.c",
                };

                break :blk struct {
                    const macos = sources_common ++ sources_macos;
                    const linux = sources_common ++ sources_linux;
                    const windows = sources_common ++ sources_windows;
                };
            };
            return sources;
        }
    };
}
