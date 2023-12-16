module shui_module::swap {
    use sui::transfer;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use shui_module::shui::{Self};
    use shui_module::boat_ticket::{Self};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use std::vector::{Self};
    use sui::table::{Self, Table};
    use sui::coin::{Self, Coin, destroy_zero};
    use sui::pay;
    use sui::ed25519;
    use std::debug::print;
    use sui::address::{Self};


    const ERR_NO_PERMISSION:u64 = 0x001;
    const ERR_EXCEED_SWAP_LIMIT:u64 = 0x002;
    const ERR_NOT_IN_WHITELIST:u64 = 0x003;
    const ERR_SWAP_MIN_ONE_SUI:u64 = 0x004;
    const ERR_NOT_START:u64 = 0x005;
    const ERR_INVALID_PHASE:u64 = 0x006;
    const ERR_INVALID_MSG:u64 = 0x007;
    const AMOUNT_DECIMAL:u64 = 1_000_000_000;
    const WHITELIST_SWAP_LIMIT:u64 = 100;
    const WHITELIST_MAX_NUM:u64 = 10_000;

    struct SwapGlobal has key {
        id: UID,
        creator: address,
        crypto: address,
        phase:u64,
        balance_SUI: Balance<SUI>,
        balance_SHUI: Balance<shui::SHUI>,
        swaped_shui: u64,
        swaped_sui: u64,
        whitelist_table: Table<address, u64>,
    }

    #[test_only]
    public fun init_for_test(ctx: &mut TxContext) {
        let global = SwapGlobal {
            id: object::new(ctx),
            creator: tx_context::sender(ctx),
            crypto: @crypto,
            phase:0,
            balance_SUI: balance::zero(),
            balance_SHUI: balance::zero(),
            swaped_shui: 0,
            swaped_sui: 0,
            whitelist_table: table::new<address, u64>(ctx)
        };
        transfer::share_object(global);
    }

    public fun set_phase(global:&mut SwapGlobal, phase:u64) {
        assert!(phase == (global.phase + 1), ERR_INVALID_PHASE);
        global.phase = phase;
    }

    fun init(ctx: &mut TxContext) {
        let global = SwapGlobal {
            id: object::new(ctx),
            creator: tx_context::sender(ctx),
            crypto: @crypto,
            phase:0,
            balance_SUI: balance::zero(),
            balance_SHUI: balance::zero(),
            swaped_shui: 0,
            swaped_sui: 0,
            whitelist_table: table::new<address, u64>(ctx)
        };
        transfer::share_object(global);
    }

    public fun init_funds_from_main_contract(swapGlobal: &mut SwapGlobal, shuiGlobal:&mut shui::Global, ctx: &mut TxContext) {
        assert!(swapGlobal.creator == tx_context::sender(ctx), ERR_NO_PERMISSION);
        let balance = shui::extract_swap_balance(shuiGlobal, ctx);
        balance::join(&mut swapGlobal.balance_SHUI, balance);
    }

    public fun add_whitelist(swapGlobal: &mut SwapGlobal, account: address, ctx: &mut TxContext) {
        assert!(swapGlobal.creator == tx_context::sender(ctx), ERR_NO_PERMISSION);
        table::add(&mut swapGlobal.whitelist_table, account, WHITELIST_SWAP_LIMIT);
        assert!(table::length(&swapGlobal.whitelist_table) <= WHITELIST_MAX_NUM, 1);
    }

    // todo:check whether other ppl's ticket can be param
    public fun set_whitelist(swapGlobal: &mut SwapGlobal, _: &boat_ticket::BoatTicket, ctx:&mut TxContext) {
        let sender = tx_context::sender(ctx);
        table::add(&mut swapGlobal.whitelist_table, sender, WHITELIST_SWAP_LIMIT);
        assert!(table::length(&swapGlobal.whitelist_table) <= WHITELIST_MAX_NUM, 1);
    }

    public fun white_list_backup(swapGlobal: &mut SwapGlobal, sig: &vector<u8>, msg: &vector<u8>, ctx:&mut TxContext) {
        let pk: vector<u8> = address::to_bytes(swapGlobal.crypto);
        let sender = tx_context::sender(ctx);
        print(sig);
        print(msg);
        print(&pk);
        assert!(*msg == address::to_bytes(sender), ERR_INVALID_MSG);
        assert!(ed25519::ed25519_verify(sig, &pk, msg), ERR_NO_PERMISSION);
        table::add(&mut swapGlobal.whitelist_table, sender, WHITELIST_SWAP_LIMIT);
        assert!(table::length(&swapGlobal.whitelist_table) <= WHITELIST_MAX_NUM, 1);
    }

    public entry fun gold_reserve_swap(global: &mut SwapGlobal, sui_pay_amount:u64, coins:vector<Coin<SUI>>, ctx:&mut TxContext) {
        let ratio = 1;
        let recepient = tx_context::sender(ctx);
        let shui_to_be_swap:u64 = sui_pay_amount * ratio;
        global.swaped_shui = global.swaped_shui + shui_to_be_swap * AMOUNT_DECIMAL;
        global.swaped_sui = global.swaped_sui + sui_pay_amount * AMOUNT_DECIMAL;

        let merged_coin = vector::pop_back(&mut coins);
        pay::join_vec(&mut merged_coin, coins);
        assert!(coin::value(&merged_coin) >= 1, ERR_SWAP_MIN_ONE_SUI);
        let balance = coin::into_balance<SUI>(
            coin::split<SUI>(&mut merged_coin, sui_pay_amount * AMOUNT_DECIMAL, ctx)
        );
        balance::join(&mut global.balance_SUI, balance);
        if (coin::value(&merged_coin) > 0) {
            transfer::public_transfer(merged_coin, recepient)
        } else {
            destroy_zero(merged_coin)
        };
        let shui_balance = balance::split(&mut global.balance_SHUI, shui_to_be_swap * AMOUNT_DECIMAL);
        let shui = coin::from_balance(shui_balance, ctx);
        transfer::public_transfer(shui, recepient);
    }

    public entry fun public_swap(global: &mut SwapGlobal, sui_pay_amount:u64, coins:vector<Coin<SUI>>, ctx:&mut TxContext) {
        assert!(global.phase == 1, ERR_NOT_START);
        let ratio = 10;
        let recepient = tx_context::sender(ctx);
        let shui_to_be_swap:u64 = sui_pay_amount * ratio;
        global.swaped_shui = global.swaped_shui + shui_to_be_swap * AMOUNT_DECIMAL;
        global.swaped_sui = global.swaped_sui + sui_pay_amount * AMOUNT_DECIMAL;

        let merged_coin = vector::pop_back(&mut coins);
        pay::join_vec(&mut merged_coin, coins);
        assert!(coin::value(&merged_coin) >= 1_000_000_000, ERR_SWAP_MIN_ONE_SUI);
        let balance = coin::into_balance<SUI>(
            coin::split<SUI>(&mut merged_coin, sui_pay_amount * AMOUNT_DECIMAL, ctx)
        );
        balance::join(&mut global.balance_SUI, balance);
        if (coin::value(&merged_coin) > 0) {
            transfer::public_transfer(merged_coin, recepient)
        } else {
            destroy_zero(merged_coin)
        };
        let shui_balance = balance::split(&mut global.balance_SHUI, shui_to_be_swap * AMOUNT_DECIMAL);
        let shui = coin::from_balance(shui_balance, ctx);
        transfer::public_transfer(shui, recepient);
    }

    public entry fun white_list_swap (global: &mut SwapGlobal, sui_pay_amount:u64, coins:vector<Coin<SUI>>, ctx:&mut TxContext) {
        let ratio = 100;
        let limit = WHITELIST_SWAP_LIMIT;
        let recepient = tx_context::sender(ctx);

        let shui_to_be_swap:u64 = sui_pay_amount * ratio;

        assert!(table::contains(&global.whitelist_table, tx_context::sender(ctx)), ERR_NOT_IN_WHITELIST);
        assert!(has_swap_amount(&global.whitelist_table, shui_to_be_swap, recepient), ERR_EXCEED_SWAP_LIMIT);

        global.swaped_shui = global.swaped_shui + shui_to_be_swap * AMOUNT_DECIMAL;
        global.swaped_sui = global.swaped_sui + sui_pay_amount * AMOUNT_DECIMAL;

        let merged_coin = vector::pop_back(&mut coins);
        pay::join_vec(&mut merged_coin, coins);
        assert!(coin::value(&merged_coin) >= 1, ERR_SWAP_MIN_ONE_SUI);
        assert!(sui_pay_amount <= limit, ERR_SWAP_MIN_ONE_SUI);
        let balance = coin::into_balance<SUI>(
            coin::split<SUI>(&mut merged_coin, sui_pay_amount * AMOUNT_DECIMAL, ctx)
        );
        balance::join(&mut global.balance_SUI, balance);
        if (coin::value(&merged_coin) > 0) {
            transfer::public_transfer(merged_coin, recepient)
        } else {
            destroy_zero(merged_coin)
        };
        let shui_balance = balance::split(&mut global.balance_SHUI, shui_to_be_swap * AMOUNT_DECIMAL);
        let shui = coin::from_balance(shui_balance, ctx);
        transfer::public_transfer(shui, recepient);
        record_swaped_amount(&mut global.whitelist_table, sui_pay_amount * ratio, recepient);
    }

    fun record_swaped_amount(table: &mut Table<address, u64>, amount_culmulate:u64, recepient: address) {
        let value:&mut u64 = table::borrow_mut(table, recepient);
        *value = *value - amount_culmulate;
    }
    
    fun has_swap_amount(table: &Table<address, u64>, amount_to_swap:u64, recepient: address): bool {
       let left_amount = *table::borrow(table, recepient);
       left_amount >= amount_to_swap
    }

    public entry fun get_total_shui_balance(global: &SwapGlobal):u64 {
        balance::value(&global.balance_SHUI)
    }

    public entry fun get_total_sui_balance(global: &SwapGlobal):u64 {
        balance::value(&global.balance_SUI)
    }

    public fun get_swaped_sui(global: &SwapGlobal) :u64 {
        global.swaped_sui
    }

    public fun get_swaped_shui(global: &SwapGlobal) :u64 {
        global.swaped_shui
    }

    public entry fun withdraw_sui(global: &mut SwapGlobal, amount:u64, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == global.creator, ERR_NO_PERMISSION);
        let airdrop_balance = balance::split(&mut global.balance_SUI, amount);
        let sui = coin::from_balance(airdrop_balance, ctx);
        transfer::public_transfer(sui, tx_context::sender(ctx));
    }

    public entry fun withdraw_shui(global: &mut SwapGlobal, amount:u64, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == global.creator, ERR_NO_PERMISSION);
        let airdrop_balance = balance::split(&mut global.balance_SHUI, amount);
        let shui = coin::from_balance(airdrop_balance, ctx);
        transfer::public_transfer(shui, tx_context::sender(ctx));
    }
}