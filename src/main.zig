const std = @import("std");
const consensus = @import("consensus/consensus.zig");

pub fn main() !void {
    std.debug.print("Full node bitcoin implementation written in {s}.\n", .{"Zig"});
    std.debug.print("This is a work in progress, is not ready for use and maybe never will.\n", .{});
}
