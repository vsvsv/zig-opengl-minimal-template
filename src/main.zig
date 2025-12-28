const std = @import("std");
const c = @cImport({
    @cInclude("glad/gl.h");
    @cInclude("GLFW/glfw3.h");
});

pub fn initWindow(width: u32, height: u32, title: []const u8) !*c.GLFWwindow {
    const log = std.log.scoped(.initWindow);

    if (c.glfwInit() != c.GLFW_TRUE) {
        log.err("Cannot initialize GLFW", .{});
        return error.cannotInitGlfw;
    }

    _ = c.glfwSetErrorCallback(struct {
        pub fn callback(error_code: c_int, description: [*c]const u8) callconv(.c) void {
            std.log.err("GLFW: {}: {s}\n", .{ error_code, description });
        }
    }.callback);

    // Latest OpenGL version supported on MacOS
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 4);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 1);

    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
    c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GLFW_TRUE);

    const window = c.glfwCreateWindow(@intCast(width), @intCast(height), title.ptr, null, null) orelse {
        c.glfwTerminate();
        log.err("Cannot create GLFW window", .{});
        return error.cannotCreateGlfwWindow;
    };

    c.glfwMakeContextCurrent(window);
    c.glfwSwapInterval(1);

    _ = c.gladLoadGL(c.glfwGetProcAddress);

    return window;
}

pub fn main() !void {
    const window = try initWindow(640, 480, "Zig OpenGL Example");
    defer c.glfwTerminate();
    defer c.glfwDestroyWindow(window);

    c.glClearColor(0.0, 0.0, 1.0, 1.0);

    while (c.glfwWindowShouldClose(window) != c.GLFW_TRUE) {
        c.glClear(c.GL_COLOR_BUFFER_BIT);
        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}
