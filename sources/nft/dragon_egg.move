module MetaGame::dragon_egg {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext, sender};
    use sui::transfer;
    use sui::coin::{Self, Coin, destroy_zero};
    use sui::package;
    use sui::table;
    use sui::balance::{Self, Balance};
    use std::ascii;
    use std::string::{Self, String, utf8};
    use sui::display;
    use std::vector;
    use sui::pay;
    use MetaGame::shui::{SHUI};
    use MetaGame::utils;

    const DEFAULT_LINK: vector<u8> = b"https://shui.one";
    const DEFAULT_IMAGE_URL_FIRE: vector<u8> = b"https://bafybeifgrwsodbehvvahrqvtql3d7ta6ztjovjfmsbk7wslyswsymrnpzi.ipfs.nftstorage.link/dragoneggfire.jpg";
    const DEFAULT_IMAGE_URL_ICE: vector<u8> = b"https://bafybeifgrwsodbehvvahrqvtql3d7ta6ztjovjfmsbk7wslyswsymrnpzi.ipfs.nftstorage.link/dragoneggice.jpg";
    const DESCRIPTION: vector<u8> = b"metagame dragon egg series";
    const PROJECT_URL: vector<u8> = b"https://shui.one/game/#/";
    const CREATOR: vector<u8> = b"metaGame";
    const ERR_NO_PERMISSION:u64 = 0x001;
    const ERR_INVALID_VERSION:u64 = 0x002;
    const AMOUNT_DECIMAL:u64 = 1_000_000_000;   
    const ERR_PAY_AMOUNT_ERROR:u64 = 0x004;
    const ERR_HAS_BEEN_BOUGHT:u64 = 0x005;
    const VERSION: u64 = 0;

    struct DRAGON_EGG has drop {}
    struct DragonEggFire has key, store {
        id:UID,
        name:String,
        power:u64
    }

    struct DragonEggIce has key, store {
        id:UID,
        name:String,
        power:u64
    }

    struct DragonEggGlobal has key {
        id: UID,
        balance_SHUI: Balance<SHUI>,
        creator: address,
        egg_ice_bought_num: u64,
        egg_fire_bought_num: u64,
        bought_list: table::Table<address, bool>,
        version:u64
    }

    #[lint_allow(self_transfer)]
    public entry fun buy_dragon_egg_ice(global:&mut DragonEggGlobal, coins:vector<Coin<SHUI>>, ctx:&mut TxContext) {
        assert!(global.version == VERSION, ERR_INVALID_VERSION);
        let recepient = tx_context::sender(ctx);
        let price = 10000;
        let merged_coin = vector::pop_back(&mut coins);
        assert!(!table::contains(&global.bought_list, recepient), ERR_HAS_BEEN_BOUGHT);
        pay::join_vec(&mut merged_coin, coins);
        assert!(coin::value(&merged_coin) >= price * AMOUNT_DECIMAL, ERR_PAY_AMOUNT_ERROR);
        let balance = coin::into_balance<SHUI>(
            coin::split<SHUI>(&mut merged_coin, price * AMOUNT_DECIMAL, ctx)
        );
        balance::join(&mut global.balance_SHUI, balance);
        if (coin::value(&merged_coin) > 0) {
            transfer::public_transfer(merged_coin, recepient)
        } else {
            destroy_zero(merged_coin)
        };
        let egg = DragonEggIce {
            id:object::new(ctx),
            name:utf8(b"Dragon Egg Ice"),
            power:0
        };
        global.egg_ice_bought_num = global.egg_ice_bought_num + 1;
        table::add(&mut global.bought_list, recepient, true);
        transfer::transfer(egg, tx_context::sender(ctx));
    }

    #[lint_allow(self_transfer)]
    public entry fun buy_dragon_egg_fire(global:&mut DragonEggGlobal, coins:vector<Coin<SHUI>>, ctx:&mut TxContext) {
        assert!(global.version == VERSION, ERR_INVALID_VERSION);    
        let recepient = tx_context::sender(ctx);
        let price = 10000;
        let merged_coin = vector::pop_back(&mut coins);
        assert!(!table::contains(&global.bought_list, recepient), ERR_HAS_BEEN_BOUGHT);
        pay::join_vec(&mut merged_coin, coins);
        assert!(coin::value(&merged_coin) >= price * AMOUNT_DECIMAL, ERR_PAY_AMOUNT_ERROR);
        let balance = coin::into_balance<SHUI>(
            coin::split<SHUI>(&mut merged_coin, price * AMOUNT_DECIMAL, ctx)
        );
        balance::join(&mut global.balance_SHUI, balance);
        if (coin::value(&merged_coin) > 0) {
            transfer::public_transfer(merged_coin, recepient)
        } else {
            destroy_zero(merged_coin)
        };
        let egg = DragonEggFire {
            id:object::new(ctx),
            name:utf8(b"Dragon Egg Fire"),
            power:0
        };
        global.egg_fire_bought_num = global.egg_fire_bought_num + 1;
        table::add(&mut global.bought_list, recepient, true);
        transfer::transfer(egg, tx_context::sender(ctx));
    }

    #[allow(unused_function)]
    fun init(otw: DRAGON_EGG, ctx: &mut TxContext) {
        let keys = vector[
            // A name for the object. The name is displayed when users view the object.
            utf8(b"name"),
            // A description for the object. The description is displayed when users view the object.
            utf8(b"description"),
            // A link to the object to use in an application.
            utf8(b"link"),
            // A URL or a blob with the image for the object.
            utf8(b"image_url"),
            // A link to a website associated with the object or creator.
            utf8(b"project_url"),
            // A string that indicates the object creator.
            utf8(b"creator")
        ];
        let valueIce = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(DEFAULT_IMAGE_URL_ICE),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];

        let valueFire = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(DEFAULT_IMAGE_URL_FIRE),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];

        // Claim the `Publisher` for the package!
        let publisher = package::claim(otw, ctx);

        let displayFire = display::new_with_fields<DragonEggFire>(
            &publisher, keys, valueFire, ctx
        );
        let displayIce = display::new_with_fields<DragonEggIce>(
            &publisher, keys, valueIce, ctx
        );

        display::update_version(&mut displayFire);
        transfer::public_transfer(displayFire, sender(ctx));
        display::update_version(&mut displayIce);
        transfer::public_transfer(displayIce, sender(ctx));

        transfer::public_transfer(publisher, sender(ctx));
        let global = DragonEggGlobal {
            id: object::new(ctx),
            balance_SHUI: balance::zero(), 
            creator: tx_context::sender(ctx),
            egg_ice_bought_num:0,
            egg_fire_bought_num:0,
            bought_list: table::new<address, bool>(ctx),
            version:0
        };
        transfer::share_object(global);
    }

    #[lint_allow(self_transfer)]
    public entry fun withdraw_shui(global: &mut DragonEggGlobal, amount:u64, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == global.creator, ERR_NO_PERMISSION);
        let balance = balance::split(&mut global.balance_SHUI, amount);
        let shui = coin::from_balance(balance, ctx);
        transfer::public_transfer(shui, tx_context::sender(ctx));
    }

    public entry fun get_left_egg_num(global: &DragonEggGlobal) : String {
        let fire = utils::numbers_to_ascii_vector((global.egg_fire_bought_num as u16));
        let ice = utils::numbers_to_ascii_vector((global.egg_ice_bought_num as u16));
        let vec_out:vector<u8> = *string::bytes(&string::utf8(b""));
        let byte_comma = ascii::byte(ascii::char(44));
        vector::append(&mut vec_out, fire);
        vector::push_back(&mut vec_out, byte_comma);
        vector::append(&mut vec_out, ice);
        string::utf8(vec_out)
    }

    public fun change_owner(global:&mut DragonEggGlobal, account:address, ctx:&mut TxContext) {
        assert!(global.creator == tx_context::sender(ctx), ERR_NO_PERMISSION);
        global.creator = account
    }

    public fun increment(global: &mut DragonEggGlobal, version: u64) {
        assert!(global.version == VERSION, ERR_INVALID_VERSION);
        global.version = version;
    }
}