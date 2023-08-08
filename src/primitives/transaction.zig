const math = @import("std").math;
const script = @import("../script/script.zig");

// An outpoint - a combination of a transaction hash and an index n into its vout
const OutPoint = struct {
    hash: u256,
    n: u32,
    comptime null_index: i32 = math.maxInt(u32),
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
};
