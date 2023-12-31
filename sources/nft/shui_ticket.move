module MetaGame::shui_ticket {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext, sender};
    use sui::transfer;
    use sui::display;
    use sui::package;
    use std::string::{String, utf8};
    friend MetaGame::tree_of_life;

    const DEFAULT_LINK: vector<u8> = b"https://shui.one";
    const IMAGE_URL_50: vector<u8> = b"https://bafybeicis764zsykvopcqtcqytsfz74ai3mwna33xi7qqh74z2f2osyyba.ipfs.nftstorage.link/st50.png";
    const IMAGE_URL_100: vector<u8> = b"https://bafybeicis764zsykvopcqtcqytsfz74ai3mwna33xi7qqh74z2f2osyyba.ipfs.nftstorage.link/st100.png";
    const IMAGE_URL_500: vector<u8> = b"https://bafybeicis764zsykvopcqtcqytsfz74ai3mwna33xi7qqh74z2f2osyyba.ipfs.nftstorage.link/st500.png";
    const IMAGE_URL_1000: vector<u8> = b"https://bafybeicis764zsykvopcqtcqytsfz74ai3mwna33xi7qqh74z2f2osyyba.ipfs.nftstorage.link/st1000.png";
    const IMAGE_URL_5000: vector<u8> = b"https://bafybeicis764zsykvopcqtcqytsfz74ai3mwna33xi7qqh74z2f2osyyba.ipfs.nftstorage.link/st5000.png";

    const DESCRIPTION: vector<u8> = b"metagame shui ticket, it can be used to swap shui token";
    const PROJECT_URL: vector<u8> = b"https://shui.one/game/#/";
    const CREATOR: vector<u8> = b"metaGame";

    struct SHUI_TICKET has drop {}
    struct ShuiTicket50 has key, store {
        id:UID,
        name:String,
        amount:u64
    }
    struct ShuiTicket100 has key, store {
        id:UID,
        name:String,
        amount:u64
    }
    struct ShuiTicket500 has key, store {
        id:UID,
        name:String,
        amount:u64
    }
    struct ShuiTicket1000 has key, store {
        id:UID,
        name:String,
        amount:u64
    }
    struct ShuiTicket5000 has key, store {
        id:UID,
        name:String,
        amount:u64
    }

    #[allow(unused_function)]
    fun init(otw: SHUI_TICKET, ctx: &mut TxContext) {
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
        let values50 = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(IMAGE_URL_50),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];
        let values100 = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(IMAGE_URL_100),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];
        let values500 = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(IMAGE_URL_500),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];
        let values1000 = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(IMAGE_URL_1000),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];
        let values5000 = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(IMAGE_URL_5000),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];
        let publisher = package::claim(otw, ctx);

        let display50 = display::new_with_fields<ShuiTicket50>(
            &publisher, keys, values50, ctx
        );
        display::update_version(&mut display50);
        transfer::public_transfer(display50, sender(ctx));

        let display100 = display::new_with_fields<ShuiTicket100>(
            &publisher, keys, values100, ctx
        );
        display::update_version(&mut display100);
        transfer::public_transfer(display100, sender(ctx));

        let display500 = display::new_with_fields<ShuiTicket500>(
            &publisher, keys, values500, ctx
        );
        display::update_version(&mut display500);
        transfer::public_transfer(display500, sender(ctx));

        let display1000 = display::new_with_fields<ShuiTicket1000>(
            &publisher, keys, values1000, ctx
        );
        display::update_version(&mut display1000);
        transfer::public_transfer(display1000, sender(ctx));

        let display5000 = display::new_with_fields<ShuiTicket5000>(
            &publisher, keys, values5000, ctx
        );
        display::update_version(&mut display5000);
        transfer::public_transfer(display5000, sender(ctx));
        transfer::public_transfer(publisher, sender(ctx));
    }

    #[lint_allow(self_transfer)]
    public(friend) fun mint(amount:u64, ctx:&mut TxContext) {
        if (amount == 50) {
            let ticket = ShuiTicket50 {
                id:object::new(ctx),
                name:utf8(b"SHUI50"),
                amount: amount
            };
            transfer::public_transfer(ticket, tx_context::sender(ctx));
        } else if (amount == 100) {
            let ticket = ShuiTicket100 {
                id:object::new(ctx),
                name:utf8(b"SHUI100"),
                amount: amount
            };
            transfer::public_transfer(ticket, tx_context::sender(ctx));
        } else if (amount == 500) {
            let ticket = ShuiTicket500 {
                id:object::new(ctx),
                name:utf8(b"SHUI500"),
                amount: amount
            };
            transfer::public_transfer(ticket, tx_context::sender(ctx));
        } else if (amount == 1000) {
            let ticket = ShuiTicket1000 {
                id:object::new(ctx),
                name:utf8(b"SHUI1000"),
                amount: amount
            };
            transfer::public_transfer(ticket, tx_context::sender(ctx));
        } else if (amount == 5000) {
            let ticket = ShuiTicket5000 {
                id:object::new(ctx),
                name:utf8(b"SHUI5000"),
                amount: amount
            };
            transfer::public_transfer(ticket, tx_context::sender(ctx));
        };
    }
}