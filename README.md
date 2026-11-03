# BK Big Clock

A small native desktop clock for macOS and Windows. No browser, server, installed runtime, font download, or extra files needed to run it.

- Borderless black window with no title bar or visible controls.
- Local system time in `HH:MM:SS`, always 24-hour, including leading zeroes.
- Steady colons, equal-width seven-segment digits, and very faint inactive segments.
- Custom text color, remembered between launches.
- Drag the clock to move it; drag an edge or corner to resize at a fixed 3.04:1 ratio. Resize cursors indicate the available direction. A small inset L-shaped grip appears only at the hovered corner.
- Right-click (Control-click on Mac) for **Text Color…**, **Reset Color**, and **Quit BK Big Clock**.
- Reads the system clock each second and re-aligns the next update to the second boundary. No animation loop or network access.

## Download

Get the apps from [Releases](https://github.com/tv12bedehuskanalen/bk-simple-clock/releases/latest).

**Mac:** unzip `BK-Big-Clock-macOS.zip`, then double-click `BK Big Clock.app`. You can move it to Applications. The universal app supports Apple Silicon and Intel, macOS 11 or newer.

**Windows:** double-click `BK Big Clock.exe`. The x64 executable uses only libraries included with Windows; no installer or runtime download is needed.

These builds do not have paid Apple notarization or a Windows publisher certificate, so the operating system may ask you to approve the first launch. The release executable is built on Windows with a statically linked runtime. Interactive testing has been performed on macOS only.

## Build from source

Build tools are needed only to build, never to run the downloaded app.

### macOS

With Apple's Command Line Tools installed:

```sh
./scripts/build-mac.sh
```

Produces a universal `.app` and ZIP in `dist/`.

### Windows

From a Visual Studio Developer Command Prompt with the C++ desktop tools installed:

```bat
scripts\build-windows.bat
```

Produces `dist\BK Big Clock.exe` with the C++ runtime linked statically.

Alternatively, with Zig 0.13:

```sh
./scripts/build-windows-cross.sh /path/to/zig
```

### Checks

```sh
clang++ -std=c++17 -Wall -Wextra -Werror tests/clock-test.cpp -o /tmp/bk-clock-test
/tmp/bk-clock-test
```

Checks midnight rollover, drawing bounds, and separation of segment shapes to prevent corner artifacts. GitHub Actions builds both platforms and runs the geometry/time checks on macOS.

## Implementation

Cocoa and Core Graphics on macOS; Win32 and GDI+ on Windows. Shared C++ digit geometry is drawn directly with antialiasing and gently rounded corners, so there are no bundled font dependencies. Text color is stored in macOS user defaults or the current user's Windows registry, respectively.

## App icon

The app icon combines the BK symbol with a small clock badge. Both native icon formats are checked into `assets/`, so building the app does not require an image library. To regenerate the packaged icon formats on macOS after changing the source PNG, run `python3 scripts/package-icons.py`.
