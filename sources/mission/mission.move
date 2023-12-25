module SuiFrameTest::mission {
    use sui::object::{UID};
    use sui::table::{Self, Table};
    use sui::tx_context::{Self, TxContext};
    use std::string;
    use sui::transfer;
    use sui::object::{Self};
    use std::string::{String, utf8, bytes};
    use sui::clock::{Self, Clock};
    use sui::balance::{Self, Balance};
    use std::vector;
    use std::ascii;
    use SuiFrameTest::metaIdentity::{Self, MetaIdentity};
    use std::debug::print;
    use SuiFrameTest::shui;
    use sui::linked_table::{Self, LinkedTable};
    use sui::coin::{Self};
    use std::option::{Self};
    friend SuiFrameTest::tree_of_life;
    friend SuiFrameTest::airdrop;

    const ERR_MISSION_EXIST:u64 = 0x01;
    const ERR_NO_PERMISSION:u64 = 0x02;
    const ERR_META_RECORDS_NOT_EXIST:u64 = 0x03;
    const ERR_MISSION_NOT_EXIST:u64 = 0x04;
    const ERR_IS_ALREADY_CLAIMED:u64 = 0x05;
    const ERR_PROGRESS_NOT_REACH:u64 = 0x06;
    const ERR_HAS_EXCEED_INVITE_POOL_LIMIT:u64 = 0x07;
    const DAY_IN_MS: u64 = 86_400_000;
    const AMOUNT_DECIMAL:u64 = 1_000_000_000;
    const INVITE_REWARD_LIMIT:u64 = 59_000_000;
    const ERR_NOT_PERMIT_TO_CLAIM:u64 = 0x08;

    struct MissionGlobal has key {
        id: UID,
        balance_SHUI: Balance<shui::SHUI>,

        invite_pool_limit : u64,

        // missionName -> MissionRecord
        mission_records: LinkedTable<String, MissionInfo>,

        // metaId -> invite mission num -> has claimed
        invite_claim_records: Table<u64, Table<u64, bool>>,
        creator: address
    }

    struct MissionInfo has store {
        name:String,
        desc:String,
        goal_process:u64,

        // metaId -> Record
        missions: Table<u64, UserRecord>,
        deadline:u64,
        reward:String
    }

    struct UserRecord has store, drop {
        name:String,
        metaId:u64,
        current_process:u64,
        is_claimed:bool
    }

    public fun init_funds_from_main_contract(global: &mut MissionGlobal, shuiGlobal:&mut shui::Global, ctx: &mut TxContext) {
        assert!(global.creator == tx_context::sender(ctx), ERR_NO_PERMISSION);
        let balance = shui::extract_mission_reserve_balance(shuiGlobal, ctx);
        balance::join(&mut global.balance_SHUI, balance);
    }

    fun init(ctx: &mut TxContext) {
        let global = MissionGlobal {
            id: object::new(ctx),
            invite_pool_limit: 0,
            mission_records: linked_table::new<String, MissionInfo>(ctx),
            balance_SHUI: balance::zero(),
            creator: @account,
            invite_claim_records: table::new<u64, Table<u64, bool>>(ctx)
        };
        transfer::share_object(global);
    }

    #[test_only]
    public fun init_for_test(ctx: &mut TxContext) {
        let global = MissionGlobal {
            id: object::new(ctx),
            invite_pool_limit: 0,
            balance_SHUI: balance::zero(),
            mission_records: linked_table::new<String, MissionInfo>(ctx),
            creator: @account,
            invite_claim_records: table::new<u64, Table<u64, bool>>(ctx)
        };
        transfer::share_object(global);
    }

    public entry fun query_mission_list(global: &MissionGlobal, meta:&mut MetaIdentity, clock: &Clock) : String {
        // name:desc:goal:current:deadline:reward
        let table = &global.mission_records;
        let key:&option::Option<String> = linked_table::front(table);
        let key_value = *option::borrow(key);
        let mission_info:&MissionInfo = linked_table::borrow(table, key_value);
        let current_process = 0;
        let deadline = mission_info.deadline;
        let now = clock::timestamp_ms(clock);
        let res_out:vector<u8> = *bytes(&utf8(b""));
        let metaId = metaIdentity::get_meta_id(meta);
        let byte_colon = ascii::byte(ascii::char(58));
        let byte_semi = ascii::byte(ascii::char(59));
        if (table::contains(&mission_info.missions, metaId)) {
            let userRecord = table::borrow(&mission_info.missions, metaId);
            if (!userRecord.is_claimed && now < deadline) {
                current_process = userRecord.current_process;
                vector::append(&mut res_out, *bytes(&mission_info.name));
                vector::push_back(&mut res_out, byte_colon);
                vector::append(&mut res_out, *bytes(&mission_info.desc));
                vector::push_back(&mut res_out, byte_colon);
                vector::append(&mut res_out, numbers_to_ascii_vector((current_process as u16)));
                vector::push_back(&mut res_out, byte_colon);
                vector::append(&mut res_out, numbers_to_ascii_vector((mission_info.goal_process as u16)));
                vector::push_back(&mut res_out, byte_colon);
                vector::append(&mut res_out, numbers_to_ascii_vector_64(mission_info.deadline - now));
                vector::push_back(&mut res_out, byte_colon);
                vector::append(&mut res_out, *bytes(&mission_info.reward));
                vector::push_back(&mut res_out, byte_semi);
            };
        } else if (now < deadline) {
            vector::append(&mut res_out, *bytes(&mission_info.name));
            vector::push_back(&mut res_out, byte_colon);
            vector::append(&mut res_out, *bytes(&mission_info.desc));
            vector::push_back(&mut res_out, byte_colon);
            vector::append(&mut res_out, numbers_to_ascii_vector((current_process as u16)));
            vector::push_back(&mut res_out, byte_colon);
            vector::append(&mut res_out, numbers_to_ascii_vector((mission_info.goal_process as u16)));
            vector::push_back(&mut res_out, byte_colon);
            vector::append(&mut res_out, numbers_to_ascii_vector_64(mission_info.deadline - now));
            vector::push_back(&mut res_out, byte_colon);
            vector::append(&mut res_out, *bytes(&mission_info.reward));
            vector::push_back(&mut res_out, byte_semi);
        };

        let next:&option::Option<String> = linked_table::next(table, *option::borrow(key));
        while (option::is_some(next)) {
            key_value = *option::borrow(next);
            print(&key_value);
            let mission_info:&MissionInfo = linked_table::borrow(table, key_value);
            let current_process = 0;
            if (table::contains(&mission_info.missions, metaId)) {
                let userRecord = table::borrow(&mission_info.missions, metaId);
                if (userRecord.is_claimed) {
                    continue
                } else {
                    current_process = userRecord.current_process;
                };
            };
            if (now < deadline) {
                vector::append(&mut res_out, *bytes(&mission_info.name));
                vector::push_back(&mut res_out, byte_colon);
                vector::append(&mut res_out, *bytes(&mission_info.desc));
                vector::push_back(&mut res_out, byte_colon);
                vector::append(&mut res_out, numbers_to_ascii_vector((current_process as u16)));
                vector::push_back(&mut res_out, byte_colon);
                vector::append(&mut res_out, numbers_to_ascii_vector((mission_info.goal_process as u16)));
                vector::push_back(&mut res_out, byte_colon);
                vector::append(&mut res_out, numbers_to_ascii_vector_64(mission_info.deadline - now));
                vector::push_back(&mut res_out, byte_colon);
                vector::append(&mut res_out, *bytes(&mission_info.reward));
                vector::push_back(&mut res_out, byte_semi);
            };
            next = linked_table::next(table, key_value);
        };
        utf8(res_out)
    }

    fun numbers_to_ascii_vector(val: u16): vector<u8> {
        let vec = vector<u8>[];
        loop {
            let b = val % 10;
            vector::push_back(&mut vec, (48 + b as u8));
            val = val / 10;
            if (val <= 0) break;
        };
        vector::reverse(&mut vec);
        vec
    }
        
    fun numbers_to_ascii_vector_64(val: u64): vector<u8> {
        let vec = vector<u8>[];
        loop {
            let b = val % 10;
            vector::push_back(&mut vec, (48 + b as u8));
            val = val / 10;
            if (val <= 0) break;
        };
        vector::reverse(&mut vec);
        vec
    }

    public entry fun query_invite_status(global:&MissionGlobal, metaGlobal: &metaIdentity::MetaInfoGlobal, metaId:u64) : String {
        let vec_out:vector<u8> = *string::bytes(&string::utf8(b""));
        let num = metaIdentity::query_invited_num(metaGlobal, metaId);
        let claimed = numbers_to_ascii_vector(1);
        let fail_num = numbers_to_ascii_vector(0);
        let ok_num = numbers_to_ascii_vector(2);
        if (num >= 2) {
            if (!has_clamied_invite(global, metaId, 2)) {
                vector::append(&mut vec_out, ok_num);
            } else {
                vector::append(&mut vec_out, claimed);
            }
        } else {
            vector::append(&mut vec_out, fail_num);
        };
        if (num >= 5) {
            if (!has_clamied_invite(global, metaId, 5)) {
                vector::append(&mut vec_out, ok_num);
            } else {
                vector::append(&mut vec_out, claimed);
            }
        } else {
            vector::append(&mut vec_out, fail_num);
        };
        if (num >= 10) {
            if (!has_clamied_invite(global, metaId, 10)) {
                vector::append(&mut vec_out, ok_num);
            } else {
                vector::append(&mut vec_out, claimed);
            }
        } else {
            vector::append(&mut vec_out, fail_num);
        };
        if (num >= 20) {
            if (!has_clamied_invite(global, metaId, 20)) {
                vector::append(&mut vec_out, ok_num);
            } else {
                vector::append(&mut vec_out, claimed);
            }
        } else {
            vector::append(&mut vec_out, fail_num);
        };
        if (num >= 50) {
            if (!has_clamied_invite(global, metaId, 50)) {
                vector::append(&mut vec_out, ok_num);
            } else {
                vector::append(&mut vec_out, claimed);
            }
        } else {
            vector::append(&mut vec_out, fail_num);
        };
        if (num >= 75) {
            if (!has_clamied_invite(global, metaId, 75)) {
                vector::append(&mut vec_out, ok_num);
            } else {
                vector::append(&mut vec_out, claimed);
            }
        } else {
            vector::append(&mut vec_out, fail_num);
        };
        if (num >= 99) {
            if (!has_clamied_invite(global, metaId, 99)) {
                vector::append(&mut vec_out, ok_num);
            } else {
                vector::append(&mut vec_out, claimed);
            }
        } else {
            vector::append(&mut vec_out, fail_num);
        };
        string::utf8(vec_out)
    }

    fun has_clamied_invite(global:&MissionGlobal, metaId:u64, missionNum:u64): bool {
        if (!table::contains(&global.invite_claim_records, metaId)) {
            return false;
        };
        let numTable = table::borrow(&global.invite_claim_records, metaId);
        if (!table::contains(numTable, missionNum)) {
            return false;
        };
        let value = table::borrow(numTable, missionNum);
        return *value
    }

    fun record_invite_clamied(global:&mut MissionGlobal, metaId:u64, missionNum:u64, ctx:&mut TxContext) {
        if (!table::contains(&global.invite_claim_records, metaId)) {
            let table_records = table::new<u64, bool>(ctx);
            table::add(&mut table_records, missionNum, true);
            table::add(&mut global.invite_claim_records, metaId, table_records);
        } else {
            let table_records = table::borrow_mut(&mut global.invite_claim_records, metaId);
            if (!table::contains(table_records, missionNum)) {
                table::add(table_records, missionNum, true);
            };
        };
    }

    public entry fun claim_invite_mission(global: &mut MissionGlobal, metaGlobal: &metaIdentity::MetaInfoGlobal, inviteNum:u64, 
        meta:&mut MetaIdentity, ctx:&mut TxContext) {
        let num = metaIdentity::query_invited_num(metaGlobal, metaIdentity::getMetaId(meta));
        let claimed = false;
        if (inviteNum == 2 && num >= 2) {
            let reward = 100 * AMOUNT_DECIMAL;
            global.invite_pool_limit = global.invite_pool_limit + 100;
            if (!has_clamied_invite(global, metaIdentity::getMetaId(meta), inviteNum)) {
                let shui_balance = balance::split(&mut global.balance_SHUI, reward);
                let shui = coin::from_balance(shui_balance, ctx);
                transfer::public_transfer(shui, tx_context::sender(ctx));
                record_invite_clamied(global, metaIdentity::getMetaId(meta), inviteNum, ctx);
                claimed = true;
            };
        };
        if (inviteNum == 5 && num >= 5) {
            let reward = 500 * AMOUNT_DECIMAL;
            global.invite_pool_limit = global.invite_pool_limit + 500;
            if (!has_clamied_invite(global, metaIdentity::getMetaId(meta), inviteNum)) {
                let shui_balance = balance::split(&mut global.balance_SHUI, reward);
                let shui = coin::from_balance(shui_balance, ctx);
                transfer::public_transfer(shui, tx_context::sender(ctx));
                record_invite_clamied(global, metaIdentity::getMetaId(meta), inviteNum, ctx);
                claimed = true;
            };
        };
        if (inviteNum == 10 && num >= 10) {
            let reward = 1000 * AMOUNT_DECIMAL;
            global.invite_pool_limit = global.invite_pool_limit + 1000;
            if (!has_clamied_invite(global, metaIdentity::getMetaId(meta), inviteNum)) {
                let shui_balance = balance::split(&mut global.balance_SHUI, reward);
                let shui = coin::from_balance(shui_balance, ctx);
                transfer::public_transfer(shui, tx_context::sender(ctx));
                record_invite_clamied(global, metaIdentity::getMetaId(meta), inviteNum, ctx);
                claimed = true;
            };
        };
        if (inviteNum == 20 && num >= 20) {
            let reward = 3000 * AMOUNT_DECIMAL;
            global.invite_pool_limit = global.invite_pool_limit + 3000;
            if (!has_clamied_invite(global, metaIdentity::getMetaId(meta), inviteNum)) {
                let shui_balance = balance::split(&mut global.balance_SHUI, reward);
                let shui = coin::from_balance(shui_balance, ctx);
                transfer::public_transfer(shui, tx_context::sender(ctx));
                record_invite_clamied(global, metaIdentity::getMetaId(meta), inviteNum, ctx);
                claimed = true;
            };
        };
        if (inviteNum == 50 && num >= 50) {
            let reward = 10000 * AMOUNT_DECIMAL;
            global.invite_pool_limit = global.invite_pool_limit + 10000;
            if (!has_clamied_invite(global, metaIdentity::getMetaId(meta), inviteNum)) {
                let shui_balance = balance::split(&mut global.balance_SHUI, reward);
                let shui = coin::from_balance(shui_balance, ctx);
                transfer::public_transfer(shui, tx_context::sender(ctx));
                record_invite_clamied(global, metaIdentity::getMetaId(meta), inviteNum, ctx);
                claimed = true;
            };
        };
        if (inviteNum == 75 && num >= 75) {
            let reward = 25000 * AMOUNT_DECIMAL;
            global.invite_pool_limit = global.invite_pool_limit + 25000;
            if (!has_clamied_invite(global, metaIdentity::getMetaId(meta), inviteNum)) {
                let shui_balance = balance::split(&mut global.balance_SHUI, reward);
                let shui = coin::from_balance(shui_balance, ctx);
                transfer::public_transfer(shui, tx_context::sender(ctx));
                record_invite_clamied(global, metaIdentity::getMetaId(meta), inviteNum, ctx);
                claimed = true;
            };
        };
        if (inviteNum == 99 && num >= 99) {
            let reward = 50000 * AMOUNT_DECIMAL;
            global.invite_pool_limit = global.invite_pool_limit + 50000;
            if (!has_clamied_invite(global, metaIdentity::getMetaId(meta), inviteNum)) {
                let shui_balance = balance::split(&mut global.balance_SHUI, reward);
                let shui = coin::from_balance(shui_balance, ctx);
                transfer::public_transfer(shui, tx_context::sender(ctx));
                record_invite_clamied(global, metaIdentity::getMetaId(meta), inviteNum, ctx);
                claimed = true;
            };
        };
        assert!(global.invite_pool_limit <= INVITE_REWARD_LIMIT, ERR_HAS_EXCEED_INVITE_POOL_LIMIT);
        assert!(claimed, ERR_NOT_PERMIT_TO_CLAIM);
    }

    public entry fun claim_mission(global: &mut MissionGlobal, mission:String, meta:&mut MetaIdentity) {
        let mission_records = &mut global.mission_records;
        assert!(linked_table::contains(mission_records, mission), ERR_MISSION_NOT_EXIST);
        let mission_info = linked_table::borrow_mut(mission_records, mission);
        let metaId = metaIdentity::get_meta_id(meta);
        assert!(table::contains(&mission_info.missions, metaId), ERR_META_RECORDS_NOT_EXIST);
        let user_record = table::borrow_mut(&mut mission_info.missions, metaId);
        assert!(!user_record.is_claimed, ERR_IS_ALREADY_CLAIMED);
        assert!(user_record.current_process >= mission_info.goal_process, ERR_PROGRESS_NOT_REACH);
        // todo: send item

        user_record.is_claimed = true;
        print(&utf8(b"receive reward"));
    }   

    public(friend) fun add_process(global: &mut MissionGlobal, mission:String, meta:&MetaIdentity) {
        let mission_records = &mut global.mission_records;
        if (linked_table::contains(mission_records, mission)) {
            let mission_info = linked_table::borrow_mut(mission_records, mission);
            let metaId = metaIdentity::get_meta_id(meta);
            if (!table::contains(&mission_info.missions, metaId)) {
                let new_record = UserRecord {
                    name:mission,
                    metaId:metaId,
                    current_process:1,
                    is_claimed:false
                };
                table::add(&mut mission_info.missions, metaId, new_record);
            } else {
                let goal_process = mission_info.goal_process;
                let user_record = table::borrow_mut(&mut mission_info.missions, metaId);
                if (user_record.current_process < goal_process) {
                    user_record.current_process = user_record.current_process + 1;
                };
            };
        };
    }

    public fun init_missions(global: &mut MissionGlobal, clock:&clock::Clock, ctx:&mut TxContext) {
        // init all missions here, update with latest version
        // mission1: invite 2 players
        // let now = clock::timestamp_ms(clock);
        // let mission1_name = utf8(b"invite players2");
        // let mission1 = MissionInfo {
        //     name:mission1_name,
        //     desc:utf8(b"invite 2 players"),
        //     goal_process:2,
        //     missions: table::new<u64, UserRecord>(ctx),
        //     deadline:now + 365 * DAY_IN_MS,
        //     reward:utf8(b"SUI:100")
        // };
        // assert!(!linked_table::contains(&global.mission_records, mission1_name), ERR_MISSION_EXIST);
        // linked_table::push_back(&mut global.mission_records, mission1_name, mission1);

        // // mission2: invite 5 players
        // let now = clock::timestamp_ms(clock);
        // let mission2_name = utf8(b"invite players5");
        // let mission2 = MissionInfo {
        //     name:mission2_name,
        //     desc:utf8(b"invite 5 players"),
        //     goal_process:5,
        //     missions: table::new<u64, UserRecord>(ctx),
        //     deadline:now + 365 * DAY_IN_MS,
        //     reward:utf8(b"SUI:500")
        // };
        // assert!(!linked_table::contains(&global.mission_records, mission2_name), ERR_MISSION_EXIST);
        // linked_table::push_back(&mut global.mission_records, mission2_name, mission2);

        // // mission3: invite 10 players
        // let now = clock::timestamp_ms(clock);
        // let mission3_name = utf8(b"invite players10");
        // let mission3 = MissionInfo {
        //     name:mission3_name,
        //     desc:utf8(b"invite 10 players"),
        //     goal_process:10,
        //     missions: table::new<u64, UserRecord>(ctx),
        //     deadline:now + 365 * DAY_IN_MS,
        //     reward:utf8(b"SUI:1000")
        // };
        // assert!(!linked_table::contains(&global.mission_records, mission3_name), ERR_MISSION_EXIST);
        // linked_table::push_back(&mut global.mission_records, mission3_name, mission3);

        // // mission4: invite 20 players
        // let now = clock::timestamp_ms(clock);
        // let mission4_name = utf8(b"invite players20");
        // let mission4 = MissionInfo {
        //     name:mission4_name,
        //     desc:utf8(b"invite 20 players"),
        //     goal_process:20,
        //     missions: table::new<u64, UserRecord>(ctx),
        //     deadline:now + 365 * DAY_IN_MS,
        //     reward:utf8(b"SUI:3000")
        // };
        // assert!(!linked_table::contains(&global.mission_records, mission4_name), ERR_MISSION_EXIST);
        // linked_table::push_back(&mut global.mission_records, mission4_name, mission4);

        // // mission5: invite 50 players
        // let now = clock::timestamp_ms(clock);
        // let mission5_name = utf8(b"invite players50");
        // let mission5 = MissionInfo {
        //     name:mission5_name,
        //     desc:utf8(b"invite 50 players"),
        //     goal_process:50,
        //     missions: table::new<u64, UserRecord>(ctx),
        //     deadline:now + 365 * DAY_IN_MS,
        //     reward:utf8(b"SUI:10000")
        // };
        // assert!(!linked_table::contains(&global.mission_records, mission5_name), ERR_MISSION_EXIST);
        // linked_table::push_back(&mut global.mission_records, mission5_name, mission5);
        
        
        // // mission6: invite 75 players
        // let now = clock::timestamp_ms(clock);
        // let mission6_name = utf8(b"invite players75");
        // let mission6 = MissionInfo {
        //     name:mission6_name,
        //     desc:utf8(b"invite 75 players"),
        //     goal_process:75,
        //     missions: table::new<u64, UserRecord>(ctx),
        //     deadline:now + 365 * DAY_IN_MS,
        //     reward:utf8(b"SUI:25000")
        // };
        // assert!(!linked_table::contains(&global.mission_records, mission6_name), ERR_MISSION_EXIST);
        // linked_table::push_back(&mut global.mission_records, mission6_name, mission6);

        // // mission7: invite 99 players
        // let now = clock::timestamp_ms(clock);
        // let mission7_name = utf8(b"invite players99");
        // let mission7 = MissionInfo {
        //     name:mission7_name,
        //     desc:utf8(b"invite 99 players"),
        //     goal_process:99,
        //     missions: table::new<u64, UserRecord>(ctx),
        //     deadline:now + 365 * DAY_IN_MS,
        //     reward:utf8(b"SUI:25000")
        // };
        // assert!(!linked_table::contains(&global.mission_records, mission7_name), ERR_MISSION_EXIST);
        // linked_table::push_back(&mut global.mission_records, mission7_name, mission7);

        // mission2: finish 3 water down
        let now = clock::timestamp_ms(clock);
        let mission1_name = utf8(b"water down");
        let mission1 = MissionInfo {
            name:mission1_name,
            desc:utf8(b"water down 3 times"),
            goal_process:3,
            missions: table::new<u64, UserRecord>(ctx),
            deadline:now + 3 * DAY_IN_MS,
            reward:utf8(b"anything")
        };
        assert!(!linked_table::contains(&global.mission_records, mission1_name), ERR_MISSION_EXIST);
        linked_table::push_back(&mut global.mission_records, mission1_name, mission1);

        // mission3: swap any water element
        // let mission2_name = utf8(b"swap water element");
        // let mission2 = MissionInfo {
        //     name:mission2_name,
        //     desc:utf8(b"swap fragments into any water element"),
        //     goal_process:1,
        //     missions: table::new<u64, UserRecord>(ctx),
        //     deadline:now + 4 * DAY_IN_MS,
        //     reward:utf8(b"anything")
        // };
        // assert!(!linked_table::contains(&global.mission_records, mission2_name), ERR_MISSION_EXIST);
        // linked_table::push_back(&mut global.mission_records, mission2_name, mission2);

        // mission4: claim airdrop
        // let mission3_name = utf8(b"claim airdrop");
        // let mission3 = MissionInfo {
        //     name:mission2_name,
        //     desc:utf8(b"claim airdrop once"),
        //     goal_process:1,
        //     missions: table::new<u64, UserRecord>(ctx),
        //     deadline:now + 5 * DAY_IN_MS,
        //     reward:utf8(b"anything")
        // };
        // assert!(!linked_table::contains(&global.mission_records, mission3_name), ERR_MISSION_EXIST);
        // linked_table::push_back(&mut global.mission_records, mission3_name, mission3);
    }

    public entry fun delete_mission(global: &mut MissionGlobal, mission:String, _clock:&Clock, ctx:&mut TxContext) {
        assert!(tx_context::sender(ctx) == @account, ERR_NO_PERMISSION);
        assert!(linked_table::contains(&global.mission_records, mission), ERR_MISSION_EXIST);
        let mission_info = linked_table::remove(&mut global.mission_records, mission);
        let MissionInfo {name:_, desc:_, goal_process:_, missions, deadline:_, reward:_} = mission_info; 
        table::drop(missions);
    }
}