module MetaGame::airdrop {
    use sui::transfer;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use MetaGame::shui::{Self};
    use MetaGame::metaIdentity::{Self};
    use MetaGame::mission::{Self};
    use std::string::{utf8};
    use sui::clock::{Self, Clock};
    use sui::coin::{Self};
    use sui::balance::{Self, Balance};
    use sui::table::{Self};
    use MetaGame::boat_ticket::{Self, BoatTicket};

    const ERR_INVALID_PHASE:u64 = 0x001;
    const ERR_NO_PERMISSION:u64 = 0x002;
    const ERR_HAS_CLAIMED_IN_24HOUR:u64 = 0x004;
    const ERR_AIRDROP_NOT_START:u64 = 0x005;
    const ERR_INACTIVE_META:u64 = 0x007;
    const ERR_EXCEED_DAILY_LIMIT:u64 = 0x008;
    const ERR_HAS_BEEN_CLAIMED:u64 = 0x009;
    const ERR_NOT_RIGHT_INDEX:u64 = 0x010;
    const DAY_IN_MS: u64 = 86_400_000;
    const AMOUNT_DECIMAL:u64 = 1_000_000_000;

    struct AirdropGlobal has key {
        id: UID,
        start: u64,
        creator: address,
        balance_SHUI: Balance<shui::SHUI>,

        whitelist_claimed_records_list: table::Table<address, u64>,

        // address -> last claim time
        daily_claim_records_list: table::Table<address, u64>,
        total_claim_amount: u64,
        now_days: u64,
        total_daily_claim_amount: u64,
    }

    struct TimeCap has key {
        id: UID,
    }

    #[test_only]
    public fun init_for_test(ctx: &mut TxContext) {
        let global = AirdropGlobal {
            id: object::new(ctx),
            start: 0,
            creator: tx_context::sender(ctx),
            balance_SHUI: balance::zero(),
            daily_claim_records_list: table::new<address, u64>(ctx),
            whitelist_claimed_records_list: table::new<address, u64>(ctx),
            total_claim_amount: 0,
            now_days: 0,
            total_daily_claim_amount: 0,
        };
        transfer::share_object(global);
        let time_cap = TimeCap {
            id: object::new(ctx)
        };
        transfer::transfer(time_cap, tx_context::sender(ctx));
    }

    fun init(ctx: &mut TxContext) {
        let global = AirdropGlobal {
            id: object::new(ctx),
            start: 0,
            creator: tx_context::sender(ctx),
            balance_SHUI: balance::zero(),
            daily_claim_records_list: table::new<address, u64>(ctx),
            whitelist_claimed_records_list: table::new<address, u64>(ctx),
            total_claim_amount: 0,
            now_days: 0,
            total_daily_claim_amount: 0,
        };
        transfer::share_object(global);
        let time_cap = TimeCap {
            id: object::new(ctx)
        };
        transfer::transfer(time_cap, tx_context::sender(ctx));
    }

    public fun init_funds_from_main_contract(airdropGlobal: &mut AirdropGlobal, shuiGlobal:&mut shui::Global, ctx: &mut TxContext) {
        assert!(airdropGlobal.creator == tx_context::sender(ctx), ERR_NO_PERMISSION);
        let balance = shui::extract_airdrop_balance(shuiGlobal, ctx);
        balance::join(&mut airdropGlobal.balance_SHUI, balance);
    }

    public entry fun get_total_shui_balance(global: &AirdropGlobal):u64 {
        balance::value(&global.balance_SHUI)
    }

    fun get_per_amount_by_time(global: &AirdropGlobal, clock: &Clock):u64 {
        let phase = get_phase_by_time(global, clock);
        assert!(phase >= 1 && phase <= 6, ERR_INVALID_PHASE);
        if (phase == 6) {
            return 10
        };
        (60 - phase * 10) * AMOUNT_DECIMAL
    }

    public fun get_phase_by_time(info:&AirdropGlobal, clock: &Clock) : u64 {
        let now = clock::timestamp_ms(clock);
        let diff = now - info.start;
        let phase = diff / (30 * DAY_IN_MS) + 1;
        if (phase > 6) {
            phase = 6;
        };
        phase
    }

    fun record_claim_time(table: &mut table::Table<address, u64>, time:u64, recepient: address) {
        if (table::contains(table, recepient)) {
            let _ = table::remove(table, recepient);
        };
        table::add(table, recepient, time);
    }

    public entry fun claim_boat_whitelist_airdrop(info:&mut AirdropGlobal, ticket:&mut BoatTicket, meta: &metaIdentity::MetaIdentity, ctx: &mut TxContext) {
        assert!(metaIdentity::is_active(meta), ERR_INACTIVE_META);
        assert!(!boat_ticket::is_claimed(ticket), ERR_HAS_BEEN_CLAIMED);
        assert!(boat_ticket::get_index(ticket) <= 1000, ERR_NOT_RIGHT_INDEX);
        assert!(!table::contains(airdropGlobal.whitelist_claimed_records_list, user), ERR_NOT_IN_WHITELIST);
        let user = tx_context::sender(ctx);
        let amount = 10_000 * AMOUNT_DECIMAL;
        let whitelist_airdrop = balance::split(&mut info.balance_SHUI, amount);
        let shui = coin::from_balance(whitelist_airdrop, ctx);
        transfer::public_transfer(shui, tx_context::sender(ctx));
        boat_ticket::record_white_list_clamed(ticket);
        table::add(&mut airdropGlobal.whitelist_claimed_records_list, user, 1);
    }

    public fun is_airdrop_claimed(info:&AirdropGlobal, ctx: &mut TxContext) : bool {
        table::contains(&airdropGlobal.whitelist_claimed_records_list, user)
    }

    public entry fun claim_airdrop(mission_global:&mut mission::MissionGlobal, info:&mut AirdropGlobal, meta: &metaIdentity::MetaIdentity, clock:&Clock, ctx: &mut TxContext) {
        assert!(metaIdentity::is_active(meta), ERR_INACTIVE_META);
        assert!(info.start > 0, ERR_AIRDROP_NOT_START);
        let now = clock::timestamp_ms(clock);
        let user = tx_context::sender(ctx);
        let amount = get_per_amount_by_time(info, clock);
        let days = get_now_days(clock, info);
        let daily_limit = get_daily_limit(days);
        if (days > info.now_days) {
            info.now_days = days;
            info.total_daily_claim_amount = amount;
        } else {
            info.total_daily_claim_amount = info.total_daily_claim_amount + amount;
        };
        info.total_claim_amount = info.total_claim_amount + amount;
        assert!(info.total_daily_claim_amount < daily_limit, ERR_EXCEED_DAILY_LIMIT);
        let last_claim_time = 0;
        if (table::contains(&info.daily_claim_records_list, user)) {
            last_claim_time = *table::borrow(&info.daily_claim_records_list, user);
        };
        assert!((now - last_claim_time) > 86_400_000, ERR_HAS_CLAIMED_IN_24HOUR);
        let airdrop_balance = balance::split(&mut info.balance_SHUI, amount);
        let shui = coin::from_balance(airdrop_balance, ctx);
        transfer::public_transfer(shui, tx_context::sender(ctx));
        record_claim_time(&mut info.daily_claim_records_list, now, user);
        mission::add_process(mission_global, utf8(b"claim airdrop"), meta);
    }

    public entry fun start_timing(info:&mut AirdropGlobal, time_cap: TimeCap, clock_object: &Clock) {
        info.start = clock::timestamp_ms(clock_object);
        let TimeCap { id } = time_cap;
        object::delete(id);
    }

    public fun get_participator_num(info:&AirdropGlobal) :u64 {
        table::length(&info.daily_claim_records_list)
    }

    public fun get_now_days(clock:&Clock, info: &AirdropGlobal):u64 {
        let time_diff = clock::timestamp_ms(clock) - info.start;
        time_diff / DAY_IN_MS + 1
    }

    public entry fun get_total_claim_amount(info: &AirdropGlobal):u64 {
        info.total_claim_amount
    }

    public entry fun get_total_daily_claim_amount(info: &AirdropGlobal):u64 {
        info.total_daily_claim_amount
    }

    public entry fun get_airdrop_diff_time(info: &AirdropGlobal, clock:&Clock, wallet_addr:address) : u64 {
        let now = clock::timestamp_ms(clock);
        if (table::contains(&info.daily_claim_records_list, wallet_addr)) {
            let last_claim_time = *table::borrow(&info.daily_claim_records_list, wallet_addr);
            now - last_claim_time
        } else {
            now
        }
    }

    public entry fun get_daily_remain_amount(clock:&Clock, info: &AirdropGlobal):u64 {
        let time_dif = clock::timestamp_ms(clock) - info.start;
        let days = time_dif / DAY_IN_MS;
        get_daily_limit(days) - info.total_daily_claim_amount
    }

    public entry fun get_daily_limit(days:u64) :u64 {
        if (days >= 150) {
            1_000_000 * AMOUNT_DECIMAL
        } else {
            (days / 30 + 1) * 1_000_000 * AMOUNT_DECIMAL
        }
    }

    public entry fun get_culmulate_remain_amount(clock:&Clock, info: &AirdropGlobal) :u64 {
        assert!(info.start > 0, ERR_AIRDROP_NOT_START);
        let time_dif = clock::timestamp_ms(clock) - info.start;
        let days = time_dif / DAY_IN_MS;
        if (days == 0) {
            0
        } else if (days <= 30) {
            days * 1_000_000 * AMOUNT_DECIMAL - info.total_claim_amount
        } else if (days <= 60) {
            (30 + days * 2) * 1_000_000 * AMOUNT_DECIMAL - info.total_claim_amount
        } else if (days <= 90) {
            (90 + days * 3) * 1_000_000 * AMOUNT_DECIMAL - info.total_claim_amount
        } else if (days <= 120) {
            (180 + days * 4) * 1_000_000 * AMOUNT_DECIMAL - info.total_claim_amount
        } else if (days <= 150) {
            (300 + days * 5) * 1_000_000 * AMOUNT_DECIMAL - info.total_claim_amount
        } else {
            (450 + days) * 1_000_000 * AMOUNT_DECIMAL - info.total_claim_amount
        }
    }
}