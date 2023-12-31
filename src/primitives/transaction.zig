const math = @import("std").math;
const script = @import("../script/script.zig");
const moneyRange = @import("../consensus/amount.zig").moneyRange;
const std = @import("std");

const TransactionError = error{OutOfRangeError};

// An outpoint - a combination of a transaction hash and an index n into its vout
const OutPoint = struct {
    hash: u256,
    n: u32,
    comptime null_index: u32 = math.maxInt(u32),

    pub fn eq(self: *const OutPoint, other: *const OutPoint) bool {
        return self.*.hash == other.*.hash and self.*.n == other.*.n;
    }

    pub fn format(self: OutPoint, actual_fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = actual_fmt;
        _ = options;

        try writer.print("OutPoint({d}, {d})", .{ self.hash, self.n });
    }

    pub fn toString(self: OutPoint, buffer: []u8) ![]u8 {
        return std.fmt.bufPrint(buffer, "{}", .{self});
    }
};

// An input of a transaction.  It contains the location of the previous
// transaction's output that it claims and a signature that matches the
// output's public key.
const TxIn = struct {
    prevout: OutPoint,
    script_sig: script.Script,
    n_sequence: u32,
    script_witness: script.ScriptWitness,

    // Setting nSequence to this value for every input in a transaction
    // disables nLockTime/IsFinalTx().
    // It fails OP_CHECKLOCKTIMEVERIFY/CheckLockTime() for any input that has
    // it set (BIP 65).
    // It has SEQUENCE_LOCKTIME_DISABLE_FLAG set (BIP 68/112).
    sequence_final: u32 = 0xffffffff,

    // This is the maximum sequence number that enables both nLockTime and
    // OP_CHECKLOCKTIMEVERIFY (BIP 65).
    // It has SEQUENCE_LOCKTIME_DISABLE_FLAG set (BIP 68/112).
    max_sequence_non_final: u32 = 0xfffffffe,

    // Below flags apply in the context of BIP 68. BIP 68 requires the tx
    // version to be set to 2, or higher.
    // If this flag is set, CTxIn::nSequence is NOT interpreted as a
    // relative lock-time.
    // It skips SequenceLocks() for any input that has it set (BIP 68).
    // It fails OP_CHECKSEQUENCEVERIFY/CheckSequence() for any input that has
    // it set (BIP 112).
    comptime sequence_locktime_disable_flag: u32 = 1 << 31,

    // If CTxIn::nSequence encodes a relative lock-time and this flag
    // is set, the relative lock-time has units of 512 seconds,
    // otherwise it specifies blocks with a granularity of 1.
    comptime sequence_locktime_type_flag: u32 = 1 << 22,

    // If CTxIn::nSequence encodes a relative lock-time, this mask is
    // applied to extract that lock-time from the sequence field.
    sequence_locktime_mask: u32 = 0x0000ffff,

    // In order to use the same number of bits to encode roughly the
    // same wall-clock duration, and because blocks are naturally
    // limited to occur every 600s on average, the minimum granularity
    // for time-based relative lock-time is fixed at 512 seconds.
    // Converting from CTxIn::nSequence to seconds is performed by
    // multiplying by 512 = 2^9, or equivalently shifting up by
    // 9 bits.
    sequence_locktime_granularity: i32 = 9,

    pub fn eq(self: *const TxIn, other: *const TxIn) bool {
        return self.*.prevout.eq(other.*.prevout) and
            self.*.script_sig.eq(other.*.script_sig) and
            self.*.n_sequence == other.*.n_sequence;
    }

    pub fn neq(self: *const TxIn, other: *const TxIn) bool {
        return !self.eq(other);
    }

    pub fn toString(self: TxIn, allocator: std.mem.Allocator) ![]const u8 {
        _ = allocator;
        _ = self;
    }
};

const TxOut = struct {
    n_value: i64,
    script_pubkey: script.Script,

    pub fn setNull(self: TxOut) void {
        self.n_value = -1;
        self.script_pubkey = undefined;
    }

    pub fn isNull(self: TxOut) bool {
        return self.n_value == -1;
    }

    pub fn eq(self: TxOut, other: *const TxOut) bool {
        return self.n_value == other.n_value and
            self.script_pubkey.eq(&other.script_pubkey);
    }

    pub fn neq(self: TxOut, other: *const TxOut) bool {
        return !self.eq(other);
    }

    pub fn format(self: TxOut, actual_fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = actual_fmt;
        _ = options;

        try writer.print("TxOut(n_value={d}, script_pub_key={s})", .{ self.n_value, self.script_pubkey });
    }

    pub fn toString(self: TxOut, buffer: []u8) ![]u8 {
        return std.fmt.bufPrint(buffer, "{}", .{self});
    }
};

const Transaction = struct {
    current_version: i32 = 2, // Default transaction version
    vin: []TxIn,
    vout: []TxOut,
    n_lock_time: u32,
    n_version: i32,
    hash: u256,
    m_witness_hash: u256,

    pub fn isNull(self: Transaction) bool {
        return self.vin.len == 0 and self.vout.len == 0;
    }

    pub fn getHash(self: Transaction) u256 {
        return self.hash;
    }

    pub fn getWitnessHash(self: Transaction) u256 {
        return self.m_witness_hash;
    }

    pub fn getValueOut(self: Transaction) !i64 {
        var n_value_out = 0;
        for (self.vout) |vout| {
            if (!moneyRange(vout.n_value) or !moneyRange(vout.n_value + n_value_out)) {
                return TransactionError.OutOfRangeError;
            }

            n_value_out += vout.n_value;
        }

        return n_value_out;
    }
};

test "equal outpoint" {
    const o1: OutPoint = .{ .hash = 0x1234567890abcdef, .n = 0 };
    const o2: OutPoint = .{ .hash = 0x1234567890abcdef, .n = 0 };
    const o3: OutPoint = .{ .hash = 0x1234567890abcdff, .n = 0 };

    try std.testing.expect(o1.eq(&o2));
    try std.testing.expect(o1.eq(&o3) == false);
}

test "outpoint tostring" {
    const o1: OutPoint = .{ .hash = 0x1234567890abcdef, .n = 1 };

    // 100 is the max size of the string
    // it was calculated using
    // var max_u256: u256 = std.math.maxInt(u256);
    // var max_u32: u32 = std.math.maxInt(u32);
    // var size = 12 + 2 + std.math.log10_int(max_u256) + std.math.log10_int(max_u32);
    // std.math.log10_int() returns the number of digits in the number - 1
    // 12 is the number of characters in "OutPoint(, )"
    // 2 (1+1) is the missing numbers from log10_int()
    // std.debug.print("max_size: {}\n", .{size});
    var buffer: [100]u8 = undefined;

    const string: []const u8 = try o1.toString(&buffer);
    const expected_string: []const u8 = "OutPoint(1311768467294899695, 1)";
    try std.testing.expect(std.mem.eql(u8, string, expected_string));
}

test "TxOut eq" {
    const out1: TxOut = .{ .n_value = 1, .script_pubkey = undefined };
    const out2: TxOut = .{ .n_value = 1, .script_pubkey = undefined };
    const out3: TxOut = .{ .n_value = 2, .script_pubkey = undefined };

    try std.testing.expect(out1.eq(&out2));
    try std.testing.expect(out1.eq(&out3) == false);
    try std.testing.expect(out1.neq(&out2) == false);
    try std.testing.expect(out1.neq(&out3));
}
