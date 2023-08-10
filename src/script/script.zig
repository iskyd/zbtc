pub const Script = struct {
    pub fn eq(self: Script, other: *const Script) bool {
        _ = other;
        _ = self;
        return true;
    }
};
pub const ScriptWitness = struct {};
