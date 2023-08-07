const std = @import("std");

// The amount of satoshis in one BTC.
pub const coin: i64 = 100000000;
// No amount larger than this (in satoshi) is valid.
//
// Note that this constant is *not* the total money supply, which in Bitcoin
// currently happens to be less than 21,000,000 BTC for various reasons, but
// rather a sanity check. As this sanity check is used by consensus-critical
// validation code, the exact value of the MAX_MONEY constant is consensus
// critical; in unusual circumstances like a(nother) overflow bug that allowed
// for the creation of coins out of thin air modification could lead to a fork.
pub const max_money: i64 = 21000000 * coin;

pub inline fn money_range(amount: i64) bool {
    return amount >= 0 and amount <= max_money;
}

test "money_range" {
    try std.testing.expect(money_range(10) == true);
    try std.testing.expect(money_range(21000000 * coin) == true);
    try std.testing.expect(money_range(21000001 * coin) == false);
    try std.testing.expect(money_range(0) == true);
    try std.testing.expect(money_range(-1) == false);
}
