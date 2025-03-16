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

pub fn main() !void {
    // Windows のコンソールで UTF-8 を使うための設定
    const cp_out = UTF8ConsoleOutput.init();
    defer cp_out.deinit();

    const writer = std.io.getStdOut().writer();
    _ = try writer.write("zprompt 🦀 ");
}
