# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

**Standard build:**
```bash
zig build
```

**Release build:**
```bash
zig build -Doptimize=ReleaseFast
```

**Run the application:**
```bash
zig build run
```

**Run tests:**
```bash
zig build test
```

**Quick release build (via Makefile):**
```bash
make build
```

**Run the executable directly:**
```bash
./zig-out/bin/zprompt
```

**Test with custom icon:**
```bash
ZPROMPT_ICON="$" ./zig-out/bin/zprompt
```

**Test with colors (using color names):**
```bash
ZPROMPT_DIR_COLOR="blue" ZPROMPT_GIT_COLOR="green" ZPROMPT_ICON_COLOR="red" ./zig-out/bin/zprompt
```

**Test with colors (using raw ANSI codes):**
```bash
ZPROMPT_DIR_COLOR=$'\033[1;34m' ZPROMPT_GIT_COLOR=$'\033[0;32m' ZPROMPT_ICON_COLOR=$'\033[1;31m' ./zig-out/bin/zprompt
```

## Project Architecture

This is a shell prompt utility written in Zig that displays information about the current directory, git status, and custom prompt symbols. The executable outputs a formatted prompt string for shell integration.

**Key components:**

- **UTF8ConsoleOutput**: Windows-specific UTF-8 console support that sets/restores console code page
- **Platform abstraction**: Separate implementations for Windows/POSIX systems for hostname and home directory detection
- **Git integration**: Parses `git status` output to extract branch/tag names, forces English output via LC_MESSAGES=C
- **Path handling**: Replaces home directory paths with `~` for display

**Main functionality flow:**
1. Initialize UTF-8 console support (Windows only)
2. Get home directory and current working directory
3. Display current path (with `~` substitution)
4. Get and display git branch/tag if in git repository
5. Output custom prompt symbol (🦀 by default, customizable via ZPROMPT_ICON environment variable)

**Color customization:**
- Supports ANSI color codes for customizing prompt appearance
- Three environment variables control colors:
  - `ZPROMPT_DIR_COLOR`: Colors the directory path
  - `ZPROMPT_GIT_COLOR`: Colors the git branch/tag (including parentheses)
  - `ZPROMPT_ICON_COLOR`: Colors the prompt icon
- Accepts both color names (e.g., "blue", "bright_red") and raw ANSI escape codes
- Available color names: black, red, green, yellow, blue, magenta, cyan, white (plus bright_ variants)
- Special modifiers: bold, dim, reset

**Memory management**: Uses different allocators based on build mode (DebugAllocator for Debug/ReleaseSafe, smp_allocator for release builds).

## Zig Version

Built and tested with Zig 0.14.1.

