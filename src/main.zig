const std = @import("std");
const builtin = @import("builtin");

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
            const original = std.os.windows.kernel32.GetConsoleOutputCP();
            _ = std.os.windows.kernel32.SetConsoleOutputCP(65001);
            return .{ .original = original };
        }
        return .{ .original = {} };
    }

    fn deinit(self: UTF8ConsoleOutput) void {
        if (builtin.os.tag == .windows) {
            _ = std.os.windows.kernel32.SetConsoleOutputCP(self.original);
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
        .windows => error.NotImplemented,
        .linux => getPosixHostName(),
        .macos => getPosixHostName(),
        else => error.NotImplemented,
    };
}

fn getCWD(allocator: std.mem.Allocator) ![]const u8 {
    const cwd = std.fs.cwd();
    const cwd_path = try cwd.realpathAlloc(allocator, ".");
    // ホームディレクトリの場合は "~" に置き換える
    return cwd_path;
}

/// Git のブランチ名を取得する関数
// オリジナルのソースコードは以下の URL にあり、MIT ライセンスで公開されている
// https://github.com/dbushell/zigbar/blob/ee1c5800c4b45a424d3dc1aa4004f0872d984302/src/Git.zig
fn getGitBranch(allocator: std.mem.Allocator) ![]const u8 {
    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ "git", "status" },
    });
    defer {
        allocator.free(result.stderr);
        allocator.free(result.stdout);
    }
    if (result.term != .Exited) {
        return error.GitCommandFailed;
    }

    // Iterate stdout lines
    // Windows でも \n で良いのだっけ...
    // だめそうなら \r\n にする
    var lines = std.mem.tokenizeScalar(u8, result.stdout, '\n');
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "On branch ")) {
            const branch = try std.mem.Allocator.dupe(allocator, u8, line[10..]); // Skip "On branch "
            return branch;
        }
    }
    return error.GitBranchNotFound;
}

pub fn main() !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    const allocator, const is_debug = a: {
        break :a switch (builtin.mode) {
            .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
            .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
        };
    };
    defer if (is_debug) {
        _ = debug_allocator.deinit();
    };

    // Windows のコンソールで UTF-8 を使うための設定
    const cp_out = UTF8ConsoleOutput.init();
    defer cp_out.deinit();

    const writer = std.io.getStdOut().writer();

    // TODO(zztkm): メモリ管理がよくわかっていないので、あとで調べる
    // 今は main 関数内で defer で allocator.free しているので、特にメモリリークが発生することはなさそうだけど
    // これで良いのかわかってない
    const cwd = getCWD(allocator) catch "";
    defer allocator.free(cwd);
    if (cwd.len != 0) {
        _ = try writer.print("{s} ", .{cwd});
    }

    const git_branch = getGitBranch(allocator) catch "";
    defer allocator.free(git_branch);
    if (git_branch.len != 0) {
        _ = try writer.print("({s}) ", .{git_branch});
    }

    _ = try writer.write("🦀 ");
}
