pub const consensus = @import("src/consensus/consensus.zig");
pub const consensus_amount = @import("src/consensus/amount.zig");

test {
    @import("std").testing.refAllDecls(@This());
}
