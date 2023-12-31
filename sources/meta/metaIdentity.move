module MetaGame::metaIdentity {
    use std::string;
    use sui::object::{Self, UID};
    use sui::linked_table::{Self, LinkedTable};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer::{Self};
    use sui::table::{Self};
    use sui::sui::SUI;
    use std::vector::{Self};
    use sui::event;
    use MetaGame::items;
    use sui::coin::{Self, Coin, value, destroy_zero};
    use sui::pay;
    
    const ERR_NO_PERMISSION:u64 = 0x004;
    const ERR_UNBINDED:u64 = 0x003;
    const ERR_ALREADY_BIND:u64 = 0x008;
    const ERR_INVALID_TYPE:u64 = 0x011;
    const ERR_PHONE_HAS_BEEN_BINDED:u64= 0x012;
    const ERR_ADDRESS_HAS_BEEN_BINDED:u64= 0x013;
    const ERR_BALANCE_AMOUNT_WRONG:u64 = 0x014;
    const ERR_HAS_BEEN_INVITED_BY_MYSELF:u64 = 0x015;
    const ERR_HAS_BEEN_INVITED:u64 = 0x016;
    const ERR_ALREADY_BEEN_INVITED:u64 = 0x017;
    const ERR_NOT_BEEN_INVITED:u64 = 0x018;
    const ERR_HE_NOT_INVITE_ANYONE:u64 = 0x019;
    const ERR_INVALID_VERSION:u64 = 0x020;
    const VERSION: u64 = 0;

    const TYPE_ALPHA:u64 = 0;
    const TYPE_BETA:u64 = 1;
    const AMOUNT_DECIMAL:u64 = 1_000_000_000;

    struct MetaIdentity has key {
        // preserve 0-20000 for airdrop
        id:UID,
        metaId:u64,
        name:string::String,
        phone:string::String,
        email:string::String,
        bind_status: bool,
        items:items::Items,
        wallet:address
    }

    // ====== Events ======
    // For when someone has purchased a donut.
    struct RegisterEvent has copy, drop {
        name: string::String,
        email: string::String,
    }

    struct MetaInfoGlobal has key{
        id:UID,
        creator: address,
        total_players: u64,

        // 0-9999
        meta_alpha_count:u64,

        // 10000-20000
        meta_beta_count:u64,

        // 20001+
        meta_common_user_count:u64,

        // for alpha activity participators
        alpha_whitelist:table::Table<address, u64>,

        // for shui token owners
        beta_whitelist:table::Table<address,u64>,

        // wallet_addr -> meta_addr
        wallet_meta_map:table::Table<address, address>,

        // phone -> meta_addr
        phone_meta_map:table::Table<string::String, address>,

        // wallet_addr -> phone
        wallet_phone_map:table::Table<address, string::String>,

        register_owner:address,

        // invitor metaId -> vec<other players's addres>
        inviteMap:LinkedTable<u64, vector<address>>,

        invitedMap:LinkedTable<u64, vector<address>>,
        version: u64
    }

    #[test_only]
    public fun init_for_test(ctx: &mut TxContext) {
        let global = MetaInfoGlobal {
            id: object::new(ctx),
            creator:@manager,
            total_players: 0,
            meta_alpha_count: 0,
            meta_beta_count:0,
            meta_common_user_count:0,
            alpha_whitelist:table::new<address, u64>(ctx),
            beta_whitelist:table::new<address,u64>(ctx),
            wallet_meta_map:table::new<address, address>(ctx),
            phone_meta_map:table::new<string::String, address>(ctx),
            wallet_phone_map:table::new<address, string::String>(ctx),
            register_owner:@manager,
            inviteMap:linked_table::new<u64, vector<address>>(ctx),
            invitedMap:linked_table::new<u64, vector<address>>(ctx),
            version: 0
        };
        transfer::share_object(global);
    }

    #[allow(unused_function)]
    fun init(ctx: &mut TxContext) {
        let global = MetaInfoGlobal {
            id: object::new(ctx),
            creator:@manager,
            total_players: 0,
            meta_alpha_count: 0,
            meta_beta_count:0,
            meta_common_user_count:0,
            alpha_whitelist:table::new<address, u64>(ctx),
            beta_whitelist:table::new<address,u64>(ctx),
            wallet_meta_map:table::new<address, address>(ctx),
            phone_meta_map:table::new<string::String, address>(ctx),
            wallet_phone_map:table::new<address, string::String>(ctx),
            register_owner:@manager,
            inviteMap:linked_table::new<u64, vector<address>>(ctx),
            invitedMap:linked_table::new<u64, vector<address>>(ctx),
            version: 0
        };
        transfer::share_object(global);
    }

    // send 1 sui
    #[lint_allow(self_transfer)]
    public entry fun inviteSendSui(global: &mut MetaInfoGlobal, inviteMetaId:u64, receiver:address, coins:vector<Coin<SUI>>, ctx:&mut TxContext) {
        assert!(global.version == VERSION, ERR_INVALID_VERSION);
        let price = 1 * AMOUNT_DECIMAL;
        let sender = tx_context::sender(ctx);
        let merged_coin = vector::pop_back(&mut coins);
        assert!(!is_registered(global, receiver), ERR_HAS_BEEN_INVITED);
        pay::join_vec(&mut merged_coin, coins);
        assert!(coin::value(&merged_coin) >= price, ERR_BALANCE_AMOUNT_WRONG);
        let payment = coin::split<SUI>(&mut merged_coin, price, ctx);
        transfer::public_transfer(payment, receiver);
        let value = value(&merged_coin);
        if (value > 0) {
            transfer::public_transfer(merged_coin, sender);
        } else {
            destroy_zero(merged_coin);
        };
        // add to map
        if(linked_table::contains(&global.inviteMap, inviteMetaId)) {
            let invite_players = linked_table::borrow_mut(&mut global.inviteMap, inviteMetaId);
            assert!(!vector::contains(invite_players, &receiver), ERR_HAS_BEEN_INVITED_BY_MYSELF);
            vector::push_back(invite_players, receiver);
        } else {
            let invite_players = vector::empty<address>();
            vector::push_back(&mut invite_players, receiver);
            linked_table::push_back(&mut global.inviteMap, inviteMetaId, invite_players);
        };
    }

    public entry fun mintInviteMeta(global: &mut MetaInfoGlobal, inviteMetaId:u64, name:string::String, phone:string::String,
        email:string::String, user_addr:address, ctx:&mut TxContext) {
        assert!(global.version == VERSION, ERR_INVALID_VERSION);
        let sender = tx_context::sender(ctx);
        assert!(!table::contains(&global.wallet_meta_map, user_addr), ERR_ALREADY_BIND);
        let uid = object::new(ctx);
        let meta_addr = object::uid_to_address(&uid);
        let meta = MetaIdentity {
            id: uid,
            metaId: generateUid(global, user_addr),
            name:name,
            phone:phone,
            email: email,
            bind_status: true,
            items:items::new(ctx),
            wallet:sender
        };
        assert!(linked_table::contains(&global.inviteMap, inviteMetaId), ERR_HE_NOT_INVITE_ANYONE);
        let inviteVec = linked_table::borrow(&global.inviteMap, inviteMetaId);
        assert!(vector::contains(inviteVec, &user_addr), ERR_NOT_BEEN_INVITED);
        if (!linked_table::contains(&global.invitedMap, inviteMetaId)) {
            let newVec = vector::empty<address>();
            vector::push_back(&mut newVec, user_addr);
            linked_table::push_back(&mut global.invitedMap, inviteMetaId, newVec);
        } else {
            let oldVec = linked_table::borrow_mut(&mut global.invitedMap, inviteMetaId);
            assert!(!vector::contains(oldVec, &user_addr), ERR_ALREADY_BEEN_INVITED);
            vector::push_back(oldVec, user_addr);
        };
        assert!(!table::contains(&global.wallet_meta_map, user_addr), ERR_ADDRESS_HAS_BEEN_BINDED);
        table::add(&mut global.wallet_meta_map, user_addr, meta_addr);

        assert!(!table::contains(&global.phone_meta_map, phone), ERR_PHONE_HAS_BEEN_BINDED);
        table::add(&mut global.phone_meta_map, phone, meta_addr);

        assert!(!table::contains(&global.wallet_phone_map, user_addr), ERR_ADDRESS_HAS_BEEN_BINDED);
        table::add(&mut global.wallet_phone_map, user_addr, phone);
        transfer::transfer(meta, user_addr);

        event::emit(
            RegisterEvent {
                name: name,
                email: email
            }
        );
        global.total_players = global.total_players + 1;
    }

    public entry fun mintMeta(global: &mut MetaInfoGlobal, name:string::String, phone:string::String, email:string::String, user_addr:address, ctx:&mut TxContext) {
        assert!(global.version == VERSION, ERR_INVALID_VERSION);
        let sender = tx_context::sender(ctx);
        assert!(!table::contains(&global.wallet_meta_map, user_addr), ERR_ALREADY_BIND);
        let uid = object::new(ctx);
        let meta_addr = object::uid_to_address(&uid);
        let meta = MetaIdentity {
            id: uid,
            metaId: generateUid(global, user_addr),
            name:name,
            phone:phone,
            email: email,
            bind_status: true,
            items:items::new(ctx),
            wallet:sender
        };
        assert!(!table::contains(&global.wallet_meta_map, user_addr), ERR_ADDRESS_HAS_BEEN_BINDED);
        table::add(&mut global.wallet_meta_map, user_addr, meta_addr);

        assert!(!table::contains(&global.phone_meta_map, phone), ERR_PHONE_HAS_BEEN_BINDED);
        table::add(&mut global.phone_meta_map, phone, meta_addr);

        assert!(!table::contains(&global.wallet_phone_map, user_addr), ERR_ADDRESS_HAS_BEEN_BINDED);
        table::add(&mut global.wallet_phone_map, user_addr, phone);
        transfer::transfer(meta, user_addr);

        event::emit(
            RegisterEvent {
                name: name,
                email: email
            }
        );
        global.total_players = global.total_players + 1;
    }

    fun generateUid(global: &mut MetaInfoGlobal, addr:address):u64 {
        let metaId;
        if (table::contains(&global.alpha_whitelist, addr)) {
            metaId = global.meta_alpha_count;
            if (metaId >= 10000) {
                metaId = get_common_metaid(global);
            } else {
                global.meta_alpha_count = global.meta_alpha_count + 1;
            }
        } else if (table::contains(&global.beta_whitelist, addr)) {
            metaId = 10000 + global.meta_beta_count;
            if (metaId > 20000) {
                metaId = get_common_metaid(global);
            } else {
                global.meta_beta_count = global.meta_beta_count + 1;
            }
        } else {
            metaId = get_common_metaid(global);
        };
        metaId
    }

    fun get_common_metaid(global: &mut MetaInfoGlobal):u64 {
        let metaId = 20000 + global.meta_common_user_count;
        global.meta_common_user_count = global.meta_common_user_count + 1;
        metaId
    }

    public entry fun bindMeta(global: &mut MetaInfoGlobal, meta:&mut MetaIdentity, phone:string::String, email:string::String, ctx:&mut TxContext) {
        assert!(meta.bind_status == false, ERR_ALREADY_BIND);
        meta.phone = phone;
        meta.email = email;
        meta.bind_status = true;
        table::add(&mut global.phone_meta_map, meta.phone, object::uid_to_address(&meta.id));
        table::add(&mut global.wallet_phone_map, tx_context::sender(ctx), phone);
    }

    public entry fun unbindMeta(global: &mut MetaInfoGlobal, meta:&mut MetaIdentity, ctx:&mut TxContext) {
        assert!(meta.bind_status == true, ERR_UNBINDED);
        meta.phone = string::utf8(b"");
        meta.email = string::utf8(b"");
        meta.bind_status = false;
        _ = table::remove(&mut global.phone_meta_map, meta.phone);
        _ = table::remove(&mut global.wallet_phone_map, tx_context::sender(ctx));
    }

    public fun transferMeta(global: &mut MetaInfoGlobal, meta: MetaIdentity, receiver:address, ctx:&mut TxContext) {
        _ = table::remove(&mut global.wallet_meta_map, tx_context::sender(ctx));
        unbindMeta(global, &mut meta, ctx);
        transfer::transfer(meta, receiver);
    }

    public entry fun deleteMeta(meta: MetaIdentity) {
        let MetaIdentity {id, metaId:_, name:_, phone:_, email:_, bind_status:_, items, wallet:_} = meta;

        // todo:check bags
        items::destroy_empty(items);
        object::delete(id);
    }

    public fun getMetaId(meta: &MetaIdentity) :u64 {
        meta.metaId
    }

    public fun getAddr(meta: &MetaIdentity) : address {
        meta.wallet
    }

    public fun is_active(meta: &MetaIdentity) :bool {
        meta.bind_status
    }

    public fun add_whitelists_by_type(global: &mut MetaInfoGlobal, whitelist: vector<address>, type:u64, ctx: &mut TxContext) {
        assert!(@manager == tx_context::sender(ctx), ERR_NO_PERMISSION);
        assert!(type >= TYPE_ALPHA && type <= TYPE_BETA, ERR_INVALID_TYPE);
        let whitelist_table;
        if (type == TYPE_ALPHA) {
            whitelist_table = &mut global.alpha_whitelist;
        } else {
            whitelist_table = &mut global.beta_whitelist;
        };
        let (i, len) = (0u64, vector::length(&whitelist));
        while (i < len) {
            let account = vector::pop_back(&mut whitelist);
            table::add(whitelist_table, account, 0);
            i = i + 1
        };
    }

    public fun add_whitelist_by_type(global: &mut MetaInfoGlobal, account: address, type:u64, ctx: &mut TxContext) {
        assert!(@manager == tx_context::sender(ctx), ERR_NO_PERMISSION);
        assert!(type >= TYPE_ALPHA && type <= TYPE_BETA, ERR_INVALID_TYPE);
        let whitelist_table;
        if (type == TYPE_ALPHA) {
            whitelist_table = &mut global.alpha_whitelist;
        } else {
            whitelist_table = &mut global.beta_whitelist;
        };
        assert!(table::length(whitelist_table) == 0, 1);
        table::add(whitelist_table, account, 0);
    }

    public fun query_meta_by_address(global: &MetaInfoGlobal, user_addr:address): &address {
         table::borrow(&global.wallet_meta_map, user_addr)
    }

    public fun is_registered(global: &MetaInfoGlobal, user_addr:address) : bool {
        table::contains(&global.wallet_meta_map, user_addr)
    }

    public fun query_meta_by_phone(global: &MetaInfoGlobal, phone:string::String): &address {
        table::borrow(&global.phone_meta_map, phone)
    }

    public fun change_register_owner(global: &mut MetaInfoGlobal, new_owner:address, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        assert!(sender == global.creator, ERR_NO_PERMISSION);
        global.register_owner = new_owner;
    }

    public fun check_bind_relationship(global: &MetaInfoGlobal, phone:string::String, wallet_addr:address) : bool {
        let phone_cache = *table::borrow(&global.wallet_phone_map, wallet_addr);
        phone_cache == phone
    }

    public fun get_items(meta: &mut MetaIdentity) : &mut items::Items {
        &mut meta.items
    }

    public fun get_items_info(meta: &MetaIdentity, itemGlobal:&items::ItemGlobal) : string::String {
        items::get_items_info(itemGlobal, &meta.items)
    }

    public fun get_meta_id(meta: &MetaIdentity): u64 {
        *&meta.metaId
    }

    public fun get_meta_name(meta: &MetaIdentity): string::String {
        *&meta.name
    }

    public fun get_total_players(global:&MetaInfoGlobal): u64 {
        global.total_players
    }

    public entry fun query_invited_num(global:&MetaInfoGlobal, metaId: u64) : u64 {
        if (linked_table::contains(&global.invitedMap, metaId)) {
            let addr_vec = linked_table::borrow(&global.invitedMap, metaId);
            vector::length(addr_vec)
        } else {
            0
        }
    }

    public fun change_owner(global:&mut MetaInfoGlobal, account:address, ctx:&mut TxContext) {
        assert!(global.creator == tx_context::sender(ctx), ERR_NO_PERMISSION);
        global.creator = account
    }
    
    public fun increment(global: &mut MetaInfoGlobal, version: u64) {
        assert!(global.version == VERSION, ERR_INVALID_VERSION);
        global.version = version;
    }
}