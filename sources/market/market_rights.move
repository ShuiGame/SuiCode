module MetaGame::market_right {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext, sender};
    use sui::transfer;
    use sui::display;
    use sui::package;
    use std::string::{String, utf8};
    friend MetaGame::tree_of_life;

    const DEFAULT_LINK: vector<u8> = b"https://shui.game";
    const IMAGE_URL_NFT_20: vector<u8> = b"https://bafybeicis764zsykvopcqtcqytsfz74ai3mwna33xi7qqh74z2f2osyyba.ipfs.nftstorage.link/st50.png";
    const IMAGE_URL_NFT_15: vector<u8> = b"https://bafybeicis764zsykvopcqtcqytsfz74ai3mwna33xi7qqh74z2f2osyyba.ipfs.nftstorage.link/st100.png";
    const IMAGE_URL_NFT_10: vector<u8> = b"https://bafybeicis764zsykvopcqtcqytsfz74ai3mwna33xi7qqh74z2f2osyyba.ipfs.nftstorage.link/st500.png";
    const IMAGE_URL_NFT_5: vector<u8> = b"https://bafybeicis764zsykvopcqtcqytsfz74ai3mwna33xi7qqh74z2f2osyyba.ipfs.nftstorage.link/st1000.png";
    const IMAGE_URL_NFT_0: vector<u8> = b"https://bafybeicis764zsykvopcqtcqytsfz74ai3mwna33xi7qqh74z2f2osyyba.ipfs.nftstorage.link/st5000.png";

    const IMAGE_URL_GAME_25: vector<u8> = b"https://bafybeicis764zsykvopcqtcqytsfz74ai3mwna33xi7qqh74z2f2osyyba.ipfs.nftstorage.link/st50.png";
    const IMAGE_URL_GAME_20: vector<u8> = b"https://bafybeicis764zsykvopcqtcqytsfz74ai3mwna33xi7qqh74z2f2osyyba.ipfs.nftstorage.link/st100.png";
    const IMAGE_URL_GAME_10: vector<u8> = b"https://bafybeicis764zsykvopcqtcqytsfz74ai3mwna33xi7qqh74z2f2osyyba.ipfs.nftstorage.link/st500.png";
    const IMAGE_URL_GAME_5: vector<u8> = b"https://bafybeicis764zsykvopcqtcqytsfz74ai3mwna33xi7qqh74z2f2osyyba.ipfs.nftstorage.link/st1000.png";
    const IMAGE_URL_GAME_3: vector<u8> = b"https://bafybeicis764zsykvopcqtcqytsfz74ai3mwna33xi7qqh74z2f2osyyba.ipfs.nftstorage.link/st5000.png";
    const IMAGE_URL_GAME_2: vector<u8> = b"https://bafybeicis764zsykvopcqtcqytsfz74ai3mwna33xi7qqh74z2f2osyyba.ipfs.nftstorage.link/st1000.png";
    const IMAGE_URL_GAME_0: vector<u8> = b"https://bafybeicis764zsykvopcqtcqytsfz74ai3mwna33xi7qqh74z2f2osyyba.ipfs.nftstorage.link/st5000.png";
    const DESCRIPTION: vector<u8> = b"shui metagame market fee rights, owner can gain gas fee from it cyclically";
    const PROJECT_URL: vector<u8> = b"https://shui.game/game/#/";
    const CREATOR: vector<u8> = b"metaGame";

    struct MARKET_RIGHT has drop {}

    // nft gas fee rights
    struct MARKET_RIGHT_NFT20 has key, store {
        id:UID,
        name:String,
        amount:u64
    }
    struct MARKET_RIGHT_NFT15 has key, store {
        id:UID,
        name:String,
        amount:u64
    }
    struct MARKET_RIGHT_NFT10 has key, store {
        id:UID,
        name:String,
        amount:u64
    }
    struct MARKET_RIGHT_NFT5 has key, store {
        id:UID,
        name:String,
        amount:u64
    }
    struct MARKET_RIGHT_NFT0 has key, store {
        id:UID,
        name:String,
        amount:u64
    }

    // gamefi gas fee rights
    struct MARKET_RIGHT_GAME25 has key, store {
        id:UID,
        name:String,
        amount:u64
    }
    struct MARKET_RIGHT_GAME20 has key, store {
        id:UID,
        name:String,
        amount:u64
    }
    struct MARKET_RIGHT_GAME10 has key, store {
        id:UID,
        name:String,
        amount:u64
    }
    struct MARKET_RIGHT_GAME5 has key, store {
        id:UID,
        name:String,
        amount:u64
    }
    struct MARKET_RIGHT_GAME3 has key, store {
        id:UID,
        name:String,
        amount:u64
    }
    struct MARKET_RIGHT_GAME2 has key, store {
        id:UID,
        name:String,
        amount:u64
    }
    struct MARKET_RIGHT_GAME0 has key, store {
        id:UID,
        name:String,
        amount:u64
    }

    #[allow(unused_function)]
    fun init(otw: MARKET_RIGHT, ctx: &mut TxContext) {
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
        let values_nft_20 = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(IMAGE_URL_NFT_20),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];
        let values_nft_15 = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(IMAGE_URL_NFT_15),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];
        let values_nft_10 = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(IMAGE_URL_NFT_10),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];
        let values_nft_5 = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(IMAGE_URL_NFT_5),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];
        let values_nft_0 = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(IMAGE_URL_NFT_0),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];

        let values_game_25 = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(IMAGE_URL_NFT_20),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];
        let values_game_20 = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(IMAGE_URL_NFT_15),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];
        let values_game_10 = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(IMAGE_URL_NFT_10),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];
        let values_game_5 = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(IMAGE_URL_NFT_5),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];
        let values_game_3 = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(IMAGE_URL_NFT_5),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];
        let values_game_2 = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(IMAGE_URL_NFT_5),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];
        let values_game_0 = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(IMAGE_URL_NFT_0),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];

        let publisher = package::claim(otw, ctx);

        let display_nft_20 = display::new_with_fields<MARKET_RIGHT_NFT20>(
            &publisher, keys, values_nft_20, ctx
        );
        display::update_version(&mut display_nft_20);
        transfer::public_transfer(display_nft_20, sender(ctx));

        let display_nft_15 = display::new_with_fields<MARKET_RIGHT_NFT15>(
            &publisher, keys, values_nft_15, ctx
        );
        display::update_version(&mut display_nft_15);
        transfer::public_transfer(display_nft_15, sender(ctx));

        let display_nft_10 = display::new_with_fields<MARKET_RIGHT_NFT10>(
            &publisher, keys, values_nft_10, ctx
        );
        display::update_version(&mut display_nft_10);
        transfer::public_transfer(display_nft_10, sender(ctx));

        let display_nft_5 = display::new_with_fields<MARKET_RIGHT_NFT5>(
            &publisher, keys, values_nft_5, ctx
        );
        display::update_version(&mut display_nft_5);
        transfer::public_transfer(display_nft_5, sender(ctx));

        let display_nft_0 = display::new_with_fields<MARKET_RIGHT_NFT0>(
            &publisher, keys, values_nft_0, ctx
        );
        display::update_version(&mut display_nft_0);
        transfer::public_transfer(display_nft_0, sender(ctx));



        let display_game_25 = display::new_with_fields<MARKET_RIGHT_GAME25>(
            &publisher, keys, values_game_25, ctx
        );
        display::update_version(&mut display_game_25);
        transfer::public_transfer(display_game_25, sender(ctx));

        let display_game_20 = display::new_with_fields<MARKET_RIGHT_GAME20>(
            &publisher, keys, values_game_20, ctx
        );
        display::update_version(&mut display_game_20);
        transfer::public_transfer(display_game_20, sender(ctx));

        let display_game_10 = display::new_with_fields<MARKET_RIGHT_GAME10>(
            &publisher, keys, values_game_10, ctx
        );
        display::update_version(&mut display_game_10);
        transfer::public_transfer(display_game_10, sender(ctx));

        let display_game_5 = display::new_with_fields<MARKET_RIGHT_GAME5>(
            &publisher, keys, values_game_5, ctx
        );
        display::update_version(&mut display_game_5);
        transfer::public_transfer(display_game_5, sender(ctx));

        let display_game_3 = display::new_with_fields<MARKET_RIGHT_GAME3>(
            &publisher, keys, values_game_3, ctx
        );
        display::update_version(&mut display_game_3);
        transfer::public_transfer(display_game_3, sender(ctx));

        let display_game_2 = display::new_with_fields<MARKET_RIGHT_GAME2>(
            &publisher, keys, values_game_2, ctx
        );
        display::update_version(&mut display_game_2);
        transfer::public_transfer(display_game_2, sender(ctx));

        let display_game_0 = display::new_with_fields<MARKET_RIGHT_GAME0>(
            &publisher, keys, values_game_0, ctx
        );
        display::update_version(&mut display_game_0);
        transfer::public_transfer(display_game_0, sender(ctx));
        
        transfer::public_transfer(publisher, sender(ctx));
    }

    // #[lint_allow(self_transfer)]
    // public(friend) fun mint(amount:u64, ctx:&mut TxContext) {
    //     if (amount == 50) {
    //         let ticket = ShuiTicket50 {
    //             id:object::new(ctx),
    //             name:utf8(b"SHUI50"),
    //             amount: amount
    //         };
    //         transfer::public_transfer(ticket, tx_context::sender(ctx));
    //     } else if (amount == 100) {
    //         let ticket = ShuiTicket100 {
    //             id:object::new(ctx),
    //             name:utf8(b"SHUI100"),
    //             amount: amount
    //         };
    //         transfer::public_transfer(ticket, tx_context::sender(ctx));
    //     } else if (amount == 500) {
    //         let ticket = ShuiTicket500 {
    //             id:object::new(ctx),
    //             name:utf8(b"SHUI500"),
    //             amount: amount
    //         };
    //         transfer::public_transfer(ticket, tx_context::sender(ctx));
    //     } else if (amount == 1000) {
    //         let ticket = ShuiTicket1000 {
    //             id:object::new(ctx),
    //             name:utf8(b"SHUI1000"),
    //             amount: amount
    //         };
    //         transfer::public_transfer(ticket, tx_context::sender(ctx));
    //     } else if (amount == 5000) {
    //         let ticket = ShuiTicket5000 {
    //             id:object::new(ctx),
    //             name:utf8(b"SHUI5000"),
    //             amount: amount
    //         };
    //         transfer::public_transfer(ticket, tx_context::sender(ctx));
    //     };
    // }
}