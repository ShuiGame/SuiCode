module shui_module::tree_of_life_record {
    use sui::tx_context::{Self, TxContext};
    use std::vector::{Self};
    use sui::transfer;
    use sui::object::{Self, UID};
    use sui::table::{Self, Table};

    const ADDRESS_ALREADY_RECORDED:u64 = 1;
    const ERR_NO_PERMISSION:u64 = 2;

    struct GlobalRecords has key {
        id: UID,
        creator: address,
        shui_token_pre_white_list: Table<address, vector<address>>,
        meta_game_pre_white_list: Table<address, vector<address>>,
        valid_shui_token_whitelist: vector<address>,
        valid_meta_game_whitelist: vector<address>,
    }

    fun init(ctx:&mut TxContext) {
        let global = GlobalRecords {
            id:object::new(ctx),
            creator:tx_context::sender(ctx),
            shui_token_pre_white_list: table::new<address, vector<address>>(ctx),
            meta_game_pre_white_list: table::new<address, vector<address>>(ctx),
            valid_shui_token_whitelist: vector::empty<address>(),
            valid_meta_game_whitelist: vector::empty<address>(),
        };
        transfer::share_object(global); 
    }

    public fun record_shui_token(global: &mut GlobalRecords, recommendAddr: address, ctx:&mut TxContext) {
        if (!table::contains(&global.shui_token_pre_white_list, recommendAddr)) {
            let vec = vector<address>[];
            vector::push_back(&mut vec, tx_context::sender(ctx));
            table::add(&mut global.shui_token_pre_white_list, recommendAddr, vec);
        } else {
            let arr = table::borrow_mut(&mut global.shui_token_pre_white_list, recommendAddr);
            assert!(!vector::contains(arr, &tx_context::sender(ctx)), ADDRESS_ALREADY_RECORDED);
            vector::push_back(arr, tx_context::sender(ctx));
        }
    }

    public fun record_meta_game_nft(global: &mut GlobalRecords, recommendAddr: address, ctx:&mut TxContext) {
        if (!table::contains(&global.meta_game_pre_white_list, recommendAddr)) {
            let vec = vector<address>[];
            vector::push_back(&mut vec, tx_context::sender(ctx));
            table::add(&mut global.meta_game_pre_white_list, recommendAddr, vec);
        } else {
            let arr = table::borrow_mut(&mut global.meta_game_pre_white_list, recommendAddr);
            assert!(!vector::contains(arr, &tx_context::sender(ctx)), ADDRESS_ALREADY_RECORDED);
            vector::push_back(arr, tx_context::sender(ctx));
        }
    }

    // will be set after data snapshot check by contract owner
    public fun set_valid_meta_game_white_list(global: &mut GlobalRecords, white_list: vector<address>, ctx:&mut TxContext) {
        assert!(global.creator == tx_context::sender(ctx), ERR_NO_PERMISSION);
        let (i, len) = (0u64, vector::length(&white_list));
        while (i < len) {
            let account = vector::pop_back(&mut white_list);
            vector::push_back(&mut global.valid_meta_game_whitelist, account);
            i = i + 1;
        }
    }

    // will be set after data snapshot check by contract owner
    public fun set_valid_shui_token_white_list(global: &mut GlobalRecords, white_list: vector<address>, ctx:&mut TxContext) {
        assert!(global.creator == tx_context::sender(ctx), ERR_NO_PERMISSION);
        let (i, len) = (0u64, vector::length(&white_list));
        while (i < len) {
            let account = vector::pop_back(&mut white_list);
            vector::push_back(&mut global.valid_shui_token_whitelist, account);
            i = i + 1;
        }
    }

    public entry fun get_shui_token_pre_white_list(global: &mut GlobalRecords, recommendAddr:address): vector<address> {
        *table::borrow(&mut global.shui_token_pre_white_list, recommendAddr)
    }

    public entry fun get_meta_game_pre_white_list(global: &mut GlobalRecords, recommendAddr:address): vector<address> {
        *table::borrow(&mut global.meta_game_pre_white_list, recommendAddr)
    }

    public entry fun get_shui_token_white_list(global: &GlobalRecords): vector<address> {
        *&global.valid_shui_token_whitelist
    }

    public entry fun get_meta_game_white_list(global: &GlobalRecords): vector<address> {
        *&global.valid_meta_game_whitelist
    }
}