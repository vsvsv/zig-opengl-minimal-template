<h1 align="center">
  Zig Minimal OpenGL Template
</h1>

<h4 align="center">Minimalist cross-platform window with OpenGL context in Zig</h4>
<br>

* Depends only on [GLFW](https://github.com/glfw/glfw) and [glad](https://github.com/Dav1dde/glad)
* Tested on Zig version ```0.14.0-dev.1710+8ee52f99c``` (see other branches for different Zig versions)
* Cross-platform compilation for Linux, MacOS and Windows
* Suitable for following OpenGL tutorials on [LearnOpenGL.com](https://learnopengl.com/Getting-started/Creating-a-window)

## Supported Zig versions

The ```master``` branch tries to support the most recent [Zig](https://github.com/ziglang/zig) version from ```master``` branch.


There are other branches named ```zig-%vesion%``` which has support for different older Zig versions.

## How To Use

> **Note**
> If you're building on Linux, ensure you have installed all required packages for GLFW. Please check "Dependencies for Wayland and X11" on [Compiling GLFW Guide](https://www.glfw.org/docs/latest/compile.html).

```bash
# Clone this repository
git clone https://github.com/vsvsv/zig-opengl-minimal-template

# Go into the repository
cd zig-opengl-minimal-template

# Fetch GLFW as submodule
git submodule update --init

# Build program
zig build run
```


## License

MIT
