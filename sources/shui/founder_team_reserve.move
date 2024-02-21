module MetaGame::founder_team_reserve {
    use sui::transfer;
    use sui::object::{Self, UID};
    use MetaGame::shui::{Self, SHUI};
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use sui::coin::{Self};
    use sui::balance::{Self, Balance};
    use sui::table::{Self};
    use std::debug::print;

    const ERR_NO_PERMISSION:u64 = 0x001;
    const ERR_EXCEED_LIST_LIMIT:u64 = 0x002;
    const ERR_ACCOUNT_HAS_BEEN_IN_WHITELIST:u64 = 0x003;
    const ERR_PHASE_TIME_NOT_REACH:u64 = 0x004;
    const ERR_ALREADY_CLAIMED:u64 = 0x005;
    const ERR_INVALID_VERSION:u64 = 0x006;
    const VERSION: u64 = 0;

    const DAY_IN_MS: u64 = 86_400_000;
    const AMOUNT_DECIMAL:u64 = 1_000_000_000;

    const RESERVE_500_num:u64 = 1;
    const RESERVE_300_num:u64 = 1;
    const RESERVE_200_num:u64 = 4;
    const RESERVE_100_num:u64 = 2;
    const RESERVE_50_num:u64 = 4;
    const RESERVE_20_num:u64 = 1;
    const RESERVE_10_num:u64 = 8;

    const RESERVE_500_SINGLE:u64 = 250_000;
    const RESERVE_300_SINGLE:u64 = 150_000;
    const RESERVE_200_SINGLE:u64 = 100_000;
    const RESERVE_100_SINGLE:u64 = 50_000;
    const RESERVE_50_SINGLE:u64 = 50_000;
    const RESERVE_20_SINGLE:u64 = 20_000;
    const RESERVE_10_SINGLE:u64 = 100_000;

    struct FounderTeamGlobal has key {
        id: UID,
        phase_start_time: u64,
        current_phase: u64,
        creator: address,
        balance_SHUI: Balance<SHUI>,

        // account -> left claimed times
        whitelist_500: table::Table<address, u64>,
        whitelist_300: table::Table<address, u64>,
        whitelist_200: table::Table<address, u64>,
        whitelist_100: table::Table<address, u64>,
        whitelist_50: table::Table<address, u64>,
        whitelist_20: table::Table<address, u64>,
        whitelist_10: table::Table<address, u64>,
        address_set: table::Table<address, u64>,
        version: u64
    }

    #[test_only]
    public fun init_for_test(ctx: &mut TxContext) {
        let global = FounderTeamGlobal {
            id: object::new(ctx),
            current_phase: 0,
            phase_start_time: 0,
            creator: tx_context::sender(ctx),
            balance_SHUI: balance::zero(),
            whitelist_500: table::new<address, u64>(ctx),
            whitelist_300: table::new<address, u64>(ctx),
            whitelist_200: table::new<address, u64>(ctx),
            whitelist_100: table::new<address, u64>(ctx),
            whitelist_50: table::new<address, u64>(ctx),
            whitelist_20: table::new<address, u64>(ctx),
            whitelist_10: table::new<address, u64>(ctx),
            address_set: table::new<address, u64>(ctx),
            version: 0
        };
        transfer::share_object(global);
    }

    #[allow(unused_function)]
    fun init(ctx: &mut TxContext) {
        let global = FounderTeamGlobal {
            id: object::new(ctx),
            current_phase: 0,
            phase_start_time: 0,
            creator: tx_context::sender(ctx),
            balance_SHUI: balance::zero(),
            whitelist_500: table::new<address, u64>(ctx),
            whitelist_300: table::new<address, u64>(ctx),
            whitelist_200: table::new<address, u64>(ctx),
            whitelist_100: table::new<address, u64>(ctx),
            whitelist_50: table::new<address, u64>(ctx),
            whitelist_20: table::new<address, u64>(ctx),
            whitelist_10: table::new<address, u64>(ctx),
            address_set: table::new<address, u64>(ctx),
            version: 0
        };
        transfer::share_object(global);
    }

    public fun init_funds_from_main_contract(global: &mut FounderTeamGlobal, shuiGlobal:&mut shui::Global, ctx: &mut TxContext) {
        assert!(global.creator == tx_context::sender(ctx), ERR_NO_PERMISSION);
        let balance = shui::extract_founder_reserve_balance(shuiGlobal, ctx);
        balance::join(&mut global.balance_SHUI, balance);
    }

    public entry fun get_total_shui_balance(global: &FounderTeamGlobal):u64 {
        balance::value(&global.balance_SHUI)
    }

    public fun get_current_phase(global:&FounderTeamGlobal) :u64 {
        global.current_phase
    }

    public entry fun next_phase(global:&mut FounderTeamGlobal, clock:&Clock, ctx:&mut TxContext) {
        assert!(global.version == VERSION, ERR_INVALID_VERSION);
        assert!(global.creator == tx_context::sender(ctx), ERR_NO_PERMISSION);
        if (global.current_phase == 0) {
            global.phase_start_time = clock::timestamp_ms(clock);
            global.current_phase = global.current_phase + 1
        } else {
            let time_diff = clock::timestamp_ms(clock) - global.phase_start_time;
            let days_diff = time_diff / (30 * DAY_IN_MS) + 1;
            assert!(days_diff >= 30, ERR_PHASE_TIME_NOT_REACH);
            global.phase_start_time = clock::timestamp_ms(clock);
            global.current_phase = global.current_phase + 1
        };
    }

    public entry fun add_white_list(global:&mut FounderTeamGlobal, account:address, amount_type:u64, ctx: &mut TxContext) {
        assert!(global.version == VERSION, ERR_INVALID_VERSION);
        assert!(global.creator == tx_context::sender(ctx), ERR_NO_PERMISSION);
        assert!(!table::contains(&global.address_set, account), ERR_ACCOUNT_HAS_BEEN_IN_WHITELIST);
        table::add(&mut global.address_set, account, 1);
        if (amount_type == 500) {
            table::add(&mut global.whitelist_500, account, 20);
            assert!(table::length(&global.whitelist_500) <= RESERVE_500_num, ERR_EXCEED_LIST_LIMIT);
        } else if (amount_type == 300) {
            table::add(&mut global.whitelist_300, account, 20);
            assert!(table::length(&global.whitelist_300) <= RESERVE_300_num, ERR_EXCEED_LIST_LIMIT);
        } else if (amount_type == 200) {
            table::add(&mut global.whitelist_200, account, 20);
            assert!(table::length(&global.whitelist_200) <= RESERVE_200_num, ERR_EXCEED_LIST_LIMIT);
        } else if (amount_type == 100) {
            table::add(&mut global.whitelist_100, account, 10);
            assert!(table::length(&global.whitelist_100) <= RESERVE_100_num, ERR_EXCEED_LIST_LIMIT);
        } else if (amount_type == 50) {
            table::add(&mut global.whitelist_50, account, 10);
            assert!(table::length(&global.whitelist_50) <= RESERVE_50_num, ERR_EXCEED_LIST_LIMIT);
        } else if (amount_type == 20) {
            table::add(&mut global.whitelist_20, account, 10);
            assert!(table::length(&global.whitelist_20) <= RESERVE_20_num, ERR_EXCEED_LIST_LIMIT);
        } else if (amount_type == 10) {
            table::add(&mut global.whitelist_10, account, 1);
            assert!(table::length(&global.whitelist_10) <= RESERVE_10_num, ERR_EXCEED_LIST_LIMIT);
        }
    }

    #[lint_allow(self_transfer)]
    public entry fun claim_reserve(global: &mut FounderTeamGlobal, amount_type:u64, ctx: &mut TxContext) {
        assert!(global.version == VERSION, ERR_INVALID_VERSION);
        assert!(global.current_phase > 0, ERR_PHASE_TIME_NOT_REACH);
        let account = tx_context::sender(ctx);
        // phase 1 claimed once , phase 2 claimed twice   phase > (limit - left claimed times)
        if (amount_type == 500) {
            print(table::borrow(&global.whitelist_500, account));
            let claimed_nums = 20 - *table::borrow(&global.whitelist_500, account);
            assert!(global.current_phase > claimed_nums, ERR_ALREADY_CLAIMED);
            let reserve = balance::split(&mut global.balance_SHUI, RESERVE_500_SINGLE * AMOUNT_DECIMAL);
            let shui = coin::from_balance(reserve, ctx);
            transfer::public_transfer(shui, account);
            let left_num:&mut u64 = table::borrow_mut(&mut global.whitelist_500, account);
            *left_num = *left_num - 1;
        } else if (amount_type == 300) {
            let claimed_nums = 20 - *table::borrow(&global.whitelist_300, account);
            assert!(global.current_phase > claimed_nums, ERR_ALREADY_CLAIMED);
            let reserve = balance::split(&mut global.balance_SHUI, RESERVE_300_SINGLE * AMOUNT_DECIMAL);
            let shui = coin::from_balance(reserve, ctx);
            transfer::public_transfer(shui, account);
            let left_num:&mut u64 = table::borrow_mut(&mut global.whitelist_300, account);
            *left_num = *left_num - 1;
        } else if (amount_type == 200) {
            let claimed_nums = 20 - *table::borrow(&global.whitelist_200, account);
            assert!(global.current_phase > claimed_nums, ERR_ALREADY_CLAIMED);
            let reserve = balance::split(&mut global.balance_SHUI, RESERVE_200_SINGLE * AMOUNT_DECIMAL);
            let shui = coin::from_balance(reserve, ctx);
            transfer::public_transfer(shui, account);
            let left_num:&mut u64 = table::borrow_mut(&mut global.whitelist_200, account);
            *left_num = *left_num - 1;
        } else if (amount_type == 100) {
            let claimed_nums = 10 - *table::borrow(&global.whitelist_100, account);
            assert!(global.current_phase > claimed_nums, ERR_ALREADY_CLAIMED);
            let reserve = balance::split(&mut global.balance_SHUI, RESERVE_100_SINGLE * AMOUNT_DECIMAL);
            let shui = coin::from_balance(reserve, ctx);
            let left_num:&mut u64 = table::borrow_mut(&mut global.whitelist_100, account);
            *left_num = *left_num - 1;
            transfer::public_transfer(shui, account);
        } else if (amount_type == 50) {
            let claimed_nums = 10 - *table::borrow(&global.whitelist_50, account);
            assert!(global.current_phase > claimed_nums, ERR_ALREADY_CLAIMED);
            let reserve = balance::split(&mut global.balance_SHUI, RESERVE_50_SINGLE * AMOUNT_DECIMAL);
            let shui = coin::from_balance(reserve, ctx);
            transfer::public_transfer(shui, account);
            let left_num:&mut u64 = table::borrow_mut(&mut global.whitelist_50, account);
            *left_num = *left_num - 1;
        } else if (amount_type == 20) {
            let claimed_nums = 10 - *table::borrow(&global.whitelist_20, account);
            assert!(global.current_phase > claimed_nums, ERR_ALREADY_CLAIMED);
            let reserve = balance::split(&mut global.balance_SHUI, RESERVE_20_SINGLE * AMOUNT_DECIMAL);
            let shui = coin::from_balance(reserve, ctx);
            transfer::public_transfer(shui, account);
            let left_num:&mut u64 = table::borrow_mut(&mut global.whitelist_20, account);
            *left_num = *left_num - 1;
        } else if (amount_type == 10) {
            let claimed_nums = 1 - *table::borrow(&global.whitelist_10, account);
            assert!(global.current_phase > claimed_nums, ERR_ALREADY_CLAIMED);
            let reserve = balance::split(&mut global.balance_SHUI, RESERVE_10_SINGLE * AMOUNT_DECIMAL);
            let shui = coin::from_balance(reserve, ctx);
            transfer::public_transfer(shui, account);
            let left_num:&mut u64 = table::borrow_mut(&mut global.whitelist_10, account);
            *left_num = *left_num - 1;
        }
    }

    public fun change_owner(global:&mut FounderTeamGlobal, account:address, ctx:&mut TxContext) {
        assert!(global.creator == tx_context::sender(ctx), ERR_NO_PERMISSION);
        global.creator = account
    }

    public fun increment(global: &mut FounderTeamGlobal, version: u64) {
        assert!(global.version == VERSION, ERR_INVALID_VERSION);
        global.version = version;
    }
}