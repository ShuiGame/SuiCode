module shui_module::shui_ticket {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    friend shui_module::tree_of_life;

    struct ShuiTicket has key, store {
        id:UID,
        amount:u64
    }

    public(friend) fun mint(amount:u64, ctx:&mut TxContext) {
        let ticket = ShuiTicket {
            id:object::new(ctx),
            amount: amount
        };
        transfer::public_transfer(ticket, tx_context::sender(ctx));
    }
}