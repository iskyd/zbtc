pub fn checkTransaction(tx: *Transaction, state: *TxValidationState) !bool {
    if (tx.vin.empty()) {
        return false;
    }
    if (tx.vout.empty()) {
        return false;
    }

    return true;
}
