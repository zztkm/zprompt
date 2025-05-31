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
5. Output custom prompt symbol (🦀)

**Memory management**: Uses different allocators based on build mode (DebugAllocator for Debug/ReleaseSafe, smp_allocator for release builds).

## Zig Version

Built and tested with Zig 0.14.1.

