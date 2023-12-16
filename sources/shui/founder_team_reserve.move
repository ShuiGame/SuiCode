module shui_module::founder_team_reserve {
    use sui::transfer;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use shui_module::shui::{Self};
    use sui::clock::{Self, Clock};
    use sui::coin::{Self};
    use sui::balance::{Self, Balance};
    use sui::table::{Self};
    use std::vector;

    const ERR_INVALID_PHASE:u64 = 0x001;
    const ERR_NO_PERMISSION:u64 = 0x002;
    const ERR_EXCEED_LIST_LIMIT:u64 = 0x009;
    const ERR_RESERVE_IS_lOCKED:u64 = 0x010;
    const ERR_INVALID_TYPE:u64 = 0x011;
    const ERR_ACCOUNT_HAS_BEEN_IN_WHITELIST:u64 = 0x012;
    const ERR_NOT_IN_WHITELIST:u64 = 0x013;

    const DAY_IN_MS: u64 = 86_400_000;
    const AMOUNT_DECIMAL:u64 = 1_000_000_000;

    const TYPE_FOUNDER:u64 = 0;
    const TYPE_CO_FOUNDER:u64 = 1;
    const TYPE_CORE_MEMBER:u64 = 2;
    const TYPE_TECH_TEAM:u64 = 3;
    const TYPE_PROMOTION:u64 = 4;

    const RESERVE_FOUNDER:u64 = 500_000;
    const RESERVE_CO_FOUNDER:u64 = 400_000;
    const RESERVE_CORE_MEMBER:u64 = 300_000;
    const RESERVE_TECH_TEAM:u64 = 200_000;
    const RESERVE_PROMOTION:u64 = 100_000;

    struct FounderTeamGlobal has key {
        id: UID,
        first_phase_start: u64,
        second_phase_start: u64,
        creator: address,
        balance_SHUI: Balance<shui::SHUI>,

        whitelist_founder: table::Table<address, u64>,
        whitelist_co_founder: table::Table<address, u64>,
        whitelist_core_members: table::Table<address, u64>,
        whitelist_tech_team: table::Table<address, u64>,
        whitelist_promotion: table::Table<address, u64>,

        // record to disallow set whitelist on same account
        address_set: table::Table<address, u64>,
        claim_record: table::Table<address, u64>,
    }

    struct TimeCap1 has key {
        id: UID,
    }

    struct TimeCap2 has key {
        id: UID,
    }

    #[test_only]
    public fun init_for_test(ctx: &mut TxContext) {
        let global = FounderTeamGlobal {
            id: object::new(ctx),
            first_phase_start: 0,
            second_phase_start: 0,
            creator: tx_context::sender(ctx),
            balance_SHUI: balance::zero(),

            whitelist_founder: table::new<address, u64>(ctx),
            whitelist_co_founder: table::new<address, u64>(ctx),
            whitelist_core_members:table::new<address, u64>(ctx),
            whitelist_tech_team: table::new<address, u64>(ctx),
            whitelist_promotion: table::new<address, u64>(ctx),

            address_set: table::new<address, u64>(ctx),
            claim_record: table::new<address, u64>(ctx),
        };
        transfer::share_object(global);
        let time_cap1 = TimeCap1 {
            id: object::new(ctx)
        };
        let time_cap2 = TimeCap2 {
            id: object::new(ctx)
        };
        transfer::transfer(time_cap1, tx_context::sender(ctx));
        transfer::transfer(time_cap2, tx_context::sender(ctx));
    }

    fun init(ctx: &mut TxContext) {
        let global = FounderTeamGlobal {
            id: object::new(ctx),
            first_phase_start: 0,
            second_phase_start: 0,
            creator: tx_context::sender(ctx),
            balance_SHUI: balance::zero(),

            whitelist_founder: table::new<address, u64>(ctx),
            whitelist_co_founder: table::new<address, u64>(ctx),
            whitelist_core_members:table::new<address, u64>(ctx),
            whitelist_tech_team: table::new<address, u64>(ctx),
            whitelist_promotion: table::new<address, u64>(ctx),

            address_set: table::new<address, u64>(ctx),
            claim_record: table::new<address, u64>(ctx),
        };
        transfer::share_object(global);
        let time_cap1 = TimeCap1 {
            id: object::new(ctx)
        };
        let time_cap2 = TimeCap2 {
            id: object::new(ctx)
        };
        transfer::transfer(time_cap1, tx_context::sender(ctx));
        transfer::transfer(time_cap2, tx_context::sender(ctx));
    }

    public fun init_funds_from_main_contract(global: &mut FounderTeamGlobal, shuiGlobal:&mut shui::Global, ctx: &mut TxContext) {
        assert!(global.creator == tx_context::sender(ctx), ERR_NO_PERMISSION);
        let balance = shui::extract_founder_reserve_balance(shuiGlobal, ctx);
        balance::join(&mut global.balance_SHUI, balance);
    }

    public entry fun get_total_shui_balance(global: &FounderTeamGlobal):u64 {
        balance::value(&global.balance_SHUI)
    }

    public entry fun start_phase1(global:&mut FounderTeamGlobal, time_cap: TimeCap1, clock_object: &Clock) {
        global.first_phase_start = clock::timestamp_ms(clock_object);
        let TimeCap1 { id } = time_cap;
        object::delete(id);
    }

    public entry fun start_phase2(global:&mut FounderTeamGlobal, time_cap: TimeCap2, clock_object: &Clock) {
        global.second_phase_start = clock::timestamp_ms(clock_object);
        let TimeCap2 { id } = time_cap;
        object::delete(id);
    }

    public entry fun add_white_list(global:&mut FounderTeamGlobal, account:address, type:u64, ctx: &mut TxContext) {
        assert!(global.creator == tx_context::sender(ctx), ERR_NO_PERMISSION);
        let (address_set, whitelist_table) = borrow_mut_white_list(global, type);
        assert!(!table::contains(address_set, account), ERR_ACCOUNT_HAS_BEEN_IN_WHITELIST);
        table::add(address_set, account, 0);
        table::add(whitelist_table, account, 0);
        let limit = get_white_list_limit(type);
        assert!(table::length(whitelist_table) <= limit, ERR_EXCEED_LIST_LIMIT);
    }

    public entry fun set_white_lists(global:&mut FounderTeamGlobal, whitelist: vector<address>, type:u64, ctx: &mut TxContext) {
        assert!(global.creator == tx_context::sender(ctx), ERR_NO_PERMISSION);
        let (address_set, whitelist_table) = borrow_mut_white_list(global, type);
        let (i, len) = (0u64, vector::length(&whitelist));
        while (i < len) {
            let account = vector::pop_back(&mut whitelist);
            assert!(!table::contains(address_set, account), ERR_ACCOUNT_HAS_BEEN_IN_WHITELIST);
            table::add(address_set, account, 0);
            table::add(whitelist_table, account, 0);
            i = i + 1
        };
    }

    fun borrow_mut_white_list(global: &mut FounderTeamGlobal, type:u64) : (&mut table::Table<address, u64>, &mut table::Table<address, u64>) {
        assert!(type >= 0 && type <= 4, ERR_INVALID_TYPE);
        let whitelist_table;
        if (type == TYPE_FOUNDER) {
            whitelist_table = &mut global.whitelist_founder;
        } else if (type == TYPE_CO_FOUNDER) {
            whitelist_table = &mut global.whitelist_co_founder;
        } else if (type == TYPE_CORE_MEMBER) {
            whitelist_table = &mut global.whitelist_core_members;
        } else if (type == TYPE_TECH_TEAM) {
            whitelist_table = &mut global.whitelist_tech_team;
        } else if (type == TYPE_PROMOTION) {
            whitelist_table = &mut global.whitelist_promotion;
        } else {
            whitelist_table = &mut global.whitelist_promotion;
        };
        (&mut global.address_set, whitelist_table)
    }

    fun borrow_white_list(global: &FounderTeamGlobal, type:u64) : &table::Table<address, u64> {
        assert!(type >= 0 && type <= 4, ERR_INVALID_TYPE);
        let whitelist_table;
        if (type == TYPE_FOUNDER) {
            whitelist_table = &global.whitelist_founder;
        } else if (type == TYPE_CO_FOUNDER) {
            whitelist_table = &global.whitelist_co_founder;
        } else if (type == TYPE_CORE_MEMBER) {
            whitelist_table = &global.whitelist_core_members;
        } else if (type == TYPE_TECH_TEAM) {
            whitelist_table = &global.whitelist_tech_team;
        } else if (type == TYPE_PROMOTION) {
            whitelist_table = &global.whitelist_promotion;
        } else {
            whitelist_table = &global.whitelist_promotion;
        };
        whitelist_table
    }

    fun get_white_list_limit(type:u64) :u64 {
        let limit;
        if (type == TYPE_FOUNDER) {
            limit = 5;
        } else if (type == TYPE_CO_FOUNDER) {
            limit = 10;
        } else if (type == TYPE_CORE_MEMBER) {
            limit = 15;
        } else if (type == TYPE_TECH_TEAM) {
            limit = 25;
        } else if (type == TYPE_PROMOTION) {
            limit = 50;
        } else {
            limit = 0;
        };
        limit
    }

    fun get_unlock_reserve_amount(global:&FounderTeamGlobal, type:u64, phase:u64, clock: &Clock) : u64 {
        let now = clock::timestamp_ms(clock);
        let num_months;
        if (phase == 1) {
            num_months = (now - global.first_phase_start) / (30 * DAY_IN_MS) + 1;
        } else {
            num_months = (now - global.second_phase_start) / (30 * DAY_IN_MS) + 1;
        };
        if (num_months >= 10) {
            num_months = 10;
        };
        let reseve_per_amount:u64;
        if (type == TYPE_FOUNDER) {
            reseve_per_amount = RESERVE_FOUNDER;
        } else if (type == TYPE_CO_FOUNDER) {
            reseve_per_amount = RESERVE_CO_FOUNDER;
        } else if (type == TYPE_CORE_MEMBER) {
            reseve_per_amount = RESERVE_CORE_MEMBER;
        } else if (type == TYPE_TECH_TEAM) {
            reseve_per_amount = RESERVE_TECH_TEAM;
        } else if (type == TYPE_PROMOTION) {
            reseve_per_amount = RESERVE_PROMOTION;
        } else {
            reseve_per_amount = 0;
        };
        reseve_per_amount * num_months / 10 / 2
    }

    public entry fun claim_reserve(global: &mut FounderTeamGlobal, clock:&Clock, type:u64, phase:u64, ctx: &mut TxContext):u64 {
        assert!(phase == 1 || phase == 2, ERR_INVALID_PHASE);
        if (phase == 1) {
            assert!(global.first_phase_start > 0, ERR_RESERVE_IS_lOCKED);
        } else {
            assert!(global.second_phase_start > 0, ERR_RESERVE_IS_lOCKED);
        };
        let account = tx_context::sender(ctx);
        let claimed = 0;
        if (table::contains(&global.claim_record, account)) {
            claimed = *table::borrow(&global.claim_record, account);
        };
        let reserve = get_unlock_reserve_amount(global, type, phase, clock);
        assert!(is_in_whitelist(global, type, account), ERR_NOT_IN_WHITELIST);
        assert!(reserve > 0, ERR_NO_PERMISSION);
        if (reserve - claimed > 0) {
            let airdrop_balance = balance::split(&mut global.balance_SHUI, (reserve - claimed) * AMOUNT_DECIMAL);
            let shui = coin::from_balance(airdrop_balance, ctx);
            transfer::public_transfer(shui, tx_context::sender(ctx));
            if (table::contains(&mut global.claim_record, account)) {
                let claimed_value = table::borrow_mut(&mut global.claim_record, account);
                *claimed_value = reserve;
            } else {
                table::add(&mut global.claim_record, account, reserve);
            }
        };
        reserve - claimed
    }

    public fun is_in_whitelist(global:&mut FounderTeamGlobal, type:u64, account:address) : bool {
        let whitelist_table = borrow_white_list(global, type);
        table::contains(whitelist_table, account)
    }

    public fun get_white_list_size(global:&mut FounderTeamGlobal, type:u64) : u64 {
        let whitelist_table = borrow_white_list(global, type);
        table::length(whitelist_table)
    }
}