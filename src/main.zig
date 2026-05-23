const std = @import("std");
const builtin = @import("builtin");

const DEFAULT_PROMPT_ICON = "🦀";

// ANSI color codes
const ANSI_RESET = "\x1b[0m";
const ANSI_BOLD = "\x1b[1m";
const ANSI_DIM = "\x1b[2m";

// Regular colors
const ANSI_BLACK = "\x1b[30m";
const ANSI_RED = "\x1b[31m";
const ANSI_GREEN = "\x1b[32m";
const ANSI_YELLOW = "\x1b[33m";
const ANSI_BLUE = "\x1b[34m";
const ANSI_MAGENTA = "\x1b[35m";
const ANSI_CYAN = "\x1b[36m";
const ANSI_WHITE = "\x1b[37m";

// Bright colors
const ANSI_BRIGHT_BLACK = "\x1b[90m";
const ANSI_BRIGHT_RED = "\x1b[91m";
const ANSI_BRIGHT_GREEN = "\x1b[92m";
const ANSI_BRIGHT_YELLOW = "\x1b[93m";
const ANSI_BRIGHT_BLUE = "\x1b[94m";
const ANSI_BRIGHT_MAGENTA = "\x1b[95m";
const ANSI_BRIGHT_CYAN = "\x1b[96m";
const ANSI_BRIGHT_WHITE = "\x1b[97m";

/// UTF8ConsoleOutput は Windows のコンソールで UTF-8 を使うための機能を持った構造体です
///
/// 参考
/// - https://ziggit.dev/t/the-incredible-unicode-mess/6776/31
///   - この実装の参考
/// - https://ziggit.dev/t/printing-unicode-characters-in-windows-terminal/7088
///   - 上の URL を見つけたきっかけの投稿
const UTF8ConsoleOutput = struct {
    original: if (builtin.os.tag == .windows) c_uint else void,

    fn init() UTF8ConsoleOutput {
        if (builtin.os.tag == .windows) {
            const GetConsoleOutputCP = @extern(c_uint, .{ .name = "GetConsoleOutputCP", .library = "kernel32" });
            const SetConsoleOutputCP = @extern(c_uint, .{ .name = "SetConsoleOutputCP", .library = "kernel32" });
            const original = GetConsoleOutputCP();
            _ = SetConsoleOutputCP(65001);
            return .{ .original = original };
        }
        return .{ .original = {} };
    }

    fn deinit(self: UTF8ConsoleOutput) void {
        if (builtin.os.tag == .windows) {
            const SetConsoleOutputCP = @extern(c_uint, .{ .name = "SetConsoleOutputCP", .library = "kernel32" });
            _ = SetConsoleOutputCP(self.original);
        }
    }
};

fn getPosixHostName() ![]const u8 {
    const hostnamebuffer: [std.posix.HOST_NAME_MAX]u8 = [_]u8{0} ** std.posix.HOST_NAME_MAX;
    const hostname = try std.posix.gethostname(hostnamebuffer);
    if (std.mem.indexOfScalar(u8, hostname, '.')) |index| {
        return hostname[0..index];
    }
    return hostname;
}

fn getHostName() ![]const u8 {
    return switch (builtin.os.tag) {
        // TODO(zztkm): Windows でのホスト名取得方法を調査して実装する
        // 参考: https://learn.microsoft.com/en-us/windows/win32/api/winsock/nf-winsock-gethostname
        .windows => error.NotImplemented,
        .linux => getPosixHostName(),
        .macos => getPosixHostName(),
        else => error.NotImplemented,
    };
}

fn getCWD(io: std.Io, allocator: std.mem.Allocator) ![:0]u8 {
    return try std.process.currentPathAlloc(io, allocator);
}

/// Git のブランチ名 or タグ名を取得する関数
// オリジナルのソースコードは以下の URL にあり、MIT ライセンスで公開されている
// https://github.com/dbushell/zigbar/blob/ee1c5800c4b45a424d3dc1aa4004f0872d984302/src/Git.zig
fn getGitBranch(gpa: std.mem.Allocator, io: std.Io, environ_map: *const std.process.Environ.Map) ![]const u8 {
    // Clone the environment map and add LC_MESSAGES=C
    var env_clone = try environ_map.clone(gpa);
    defer env_clone.deinit();
    try env_clone.put("LC_MESSAGES", "C");

    const result = try std.process.run(gpa, io, .{
        .argv = &.{ "git", "status" },
        .environ_map = &env_clone,
    });
    defer {
        gpa.free(result.stderr);
        gpa.free(result.stdout);
    }
    switch (result.term) {
        .exited => {},
        else => return error.GitCommandFailed,
    }

    // Iterate stdout lines
    var lines = std.mem.tokenizeScalar(u8, result.stdout, '\n');
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "On branch ")) {
            if (line.len >= 10) {
                const branch = try std.mem.Allocator.dupe(gpa, u8, line[10..]); // Skip "On branch "
                return branch;
            }
        }
        if (std.mem.startsWith(u8, line, "HEAD detached at ")) {
            const tag = try std.mem.Allocator.dupe(gpa, u8, line[17..]); // Skip "HEAD detached at "
            return tag;
        }
    }
    return error.GitBranchNotFound;
}

fn getHome(allocator: std.mem.Allocator, environ_map: *const std.process.Environ.Map) ![]const u8 {
    return switch (builtin.os.tag) {
        .windows => {
            const value = environ_map.get("USERPROFILE") orelse return error.HomeNotFound;
            return try allocator.dupe(u8, value);
        },
        .linux, .macos => {
            const value = environ_map.get("HOME") orelse return error.HomeNotFound;
            if (value.len == 0) return error.HomeIsEmpty;
            return try allocator.dupe(u8, value);
        },
        else => error.NotImplemented,
    };
}

fn getPromptIcon(allocator: std.mem.Allocator, environ_map: *const std.process.Environ.Map) ![]const u8 {
    if (environ_map.get("ZPROMPT_ICON")) |icon| {
        return try allocator.dupe(u8, icon);
    }
    return try allocator.dupe(u8, DEFAULT_PROMPT_ICON);
}

fn parseColorName(name: []const u8) ?[]const u8 {
    if (std.mem.eql(u8, name, "black")) return ANSI_BLACK;
    if (std.mem.eql(u8, name, "red")) return ANSI_RED;
    if (std.mem.eql(u8, name, "green")) return ANSI_GREEN;
    if (std.mem.eql(u8, name, "yellow")) return ANSI_YELLOW;
    if (std.mem.eql(u8, name, "blue")) return ANSI_BLUE;
    if (std.mem.eql(u8, name, "magenta")) return ANSI_MAGENTA;
    if (std.mem.eql(u8, name, "cyan")) return ANSI_CYAN;
    if (std.mem.eql(u8, name, "white")) return ANSI_WHITE;

    if (std.mem.eql(u8, name, "bright_black")) return ANSI_BRIGHT_BLACK;
    if (std.mem.eql(u8, name, "bright_red")) return ANSI_BRIGHT_RED;
    if (std.mem.eql(u8, name, "bright_green")) return ANSI_BRIGHT_GREEN;
    if (std.mem.eql(u8, name, "bright_yellow")) return ANSI_BRIGHT_YELLOW;
    if (std.mem.eql(u8, name, "bright_blue")) return ANSI_BRIGHT_BLUE;
    if (std.mem.eql(u8, name, "bright_magenta")) return ANSI_BRIGHT_MAGENTA;
    if (std.mem.eql(u8, name, "bright_cyan")) return ANSI_BRIGHT_CYAN;
    if (std.mem.eql(u8, name, "bright_white")) return ANSI_BRIGHT_WHITE;

    if (std.mem.eql(u8, name, "bold")) return ANSI_BOLD;
    if (std.mem.eql(u8, name, "dim")) return ANSI_DIM;
    if (std.mem.eql(u8, name, "reset")) return ANSI_RESET;

    return null;
}

fn getColor(allocator: std.mem.Allocator, environ_map: *const std.process.Environ.Map, env_var: []const u8) ![]const u8 {
    const color_value = environ_map.get(env_var) orelse return try allocator.dupe(u8, "");

    // Check if it's a color name
    if (parseColorName(color_value)) |color_code| {
        return try allocator.dupe(u8, color_code);
    }

    // Otherwise, assume it's a raw ANSI code
    return try allocator.dupe(u8, color_value);
}

fn getDirectoryColor(allocator: std.mem.Allocator, environ_map: *const std.process.Environ.Map) ![]const u8 {
    return getColor(allocator, environ_map, "ZPROMPT_DIR_COLOR");
}

fn getGitColor(allocator: std.mem.Allocator, environ_map: *const std.process.Environ.Map) ![]const u8 {
    return getColor(allocator, environ_map, "ZPROMPT_GIT_COLOR");
}

fn getIconColor(allocator: std.mem.Allocator, environ_map: *const std.process.Environ.Map) ![]const u8 {
    return getColor(allocator, environ_map, "ZPROMPT_ICON_COLOR");
}

/// zsh用のエスケープシーケンスラッパー関数
/// ANSIエスケープシーケンスを %{ と %} で囲む
fn wrapForZsh(allocator: std.mem.Allocator, escape_seq: []const u8) ![]const u8 {
    if (escape_seq.len == 0) {
        return try allocator.dupe(u8, "");
    }
    return try std.fmt.allocPrint(allocator, "%{{{s}%}}", .{escape_seq});
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    const environ_map = init.environ_map;

    // Windows のコンソールで UTF-8 を使うための設定
    const cp_out = UTF8ConsoleOutput.init();
    defer cp_out.deinit();

    // Stdout writer setup
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    // TODO(zztkm): メモリ管理がよくわかっていないので、あとで調べる
    // 今は main 関数内で defer で allocator.free しているので、特にメモリリークが発生することはなさそうだけど
    // これで良いのかわかってない
    const home = getHome(allocator, environ_map) catch "";
    defer allocator.free(home);
    const cwd = getCWD(io, allocator) catch "";
    defer allocator.free(cwd);

    // Get colors for each component
    const dir_color = try getDirectoryColor(allocator, environ_map);
    defer allocator.free(dir_color);
    const git_color = try getGitColor(allocator, environ_map);
    defer allocator.free(git_color);
    const icon_color = try getIconColor(allocator, environ_map);
    defer allocator.free(icon_color);

    // Wrap colors for zsh
    const wrapped_dir_color = try wrapForZsh(allocator, dir_color);
    defer allocator.free(wrapped_dir_color);
    const wrapped_git_color = try wrapForZsh(allocator, git_color);
    defer allocator.free(wrapped_git_color);
    const wrapped_icon_color = try wrapForZsh(allocator, icon_color);
    defer allocator.free(wrapped_icon_color);
    const wrapped_reset = try wrapForZsh(allocator, ANSI_RESET);
    defer allocator.free(wrapped_reset);

    if (cwd.len != 0) {
        // cwd の先頭が home と一致する場合は "~" に置き換える
        if (std.mem.startsWith(u8, cwd, home)) {
            try stdout.print("{s}~{s}{s} ", .{ wrapped_dir_color, cwd[home.len..], if (dir_color.len > 0) wrapped_reset else "" });
        } else {
            try stdout.print("{s}{s}{s} ", .{ wrapped_dir_color, cwd, if (dir_color.len > 0) wrapped_reset else "" });
        }
    }

    const git_branch = getGitBranch(allocator, io, environ_map) catch "";
    defer allocator.free(git_branch);
    if (git_branch.len != 0) {
        try stdout.print("{s}({s}){s} ", .{ wrapped_git_color, git_branch, if (git_color.len > 0) wrapped_reset else "" });
    }

    // プロンプトアイコンを環境変数 ZPROMPT_ICON から取得 (デフォルト: 🦀)
    const prompt_icon = try getPromptIcon(allocator, environ_map);
    defer allocator.free(prompt_icon);
    try stdout.print("{s}{s}{s} ", .{ wrapped_icon_color, prompt_icon, if (icon_color.len > 0) wrapped_reset else "" });

    // Flush stdout
    try stdout.flush();

    // TODO(zztkm): プロンプトのフォーマットをカスタムできるようにする
}
