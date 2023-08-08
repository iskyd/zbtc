const std = @import("std");
const consensus = @import("consensus/consensus.zig");

pub fn main() !void {
    std.debug.print("Full node bitcoin implementation written in {s}.\n", .{"Zig"});
    std.debug.print("This is a work in progress, is not ready for use and maybe never will.\n", .{});
    std.debug.print("max_block_serialized_size {}", .{@as(u64, consensus.max_block_serialized_size)});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
