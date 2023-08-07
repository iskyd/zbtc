const std = @import("std");

// The maximum allowed size for a serialized block, in bytes (only for buffer size limits)
pub const max_block_serialized_size: u32 = 4000000;
// The maximum allowed weight for a block, see BIP 141 (network rule)
pub const max_block_heigth: u32 = 4000000;
// The maximum allowed number of signature check operations in a block (network rule)
pub const max_block_sigops_cost: i32 = 80000;
// Coinbase transaction outputs can only be spent after this number of new blocks (network rule)
pub const coinbase_maturity: i32 = 100;

test "expected values" {
    try std.testing.expect(max_block_serialized_size == 4000000);
    try std.testing.expect(max_block_heigth == 4000000);
    try std.testing.expect(max_block_sigops_cost == 80000);
    try std.testing.expect(coinbase_maturity == 100);
}
