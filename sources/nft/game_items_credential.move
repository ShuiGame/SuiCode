module shui_module::items_credential {
    use std::string::{Self, utf8, String};
    use sui::object;
    use sui::display;
    use sui::object::UID;
    use sui::package;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    friend shui_module::market;

    const DEFAULT_LINK: vector<u8> = b"https://shui.one";
    const DEFAULT_IMAGE_URL: vector<u8> = b"https://bafybeibzoi4kzr4gg75zhso5jespxnwespyfyakemrwibqorjczkn23vpi.ipfs.nftstorage.link/NFT-CARD1.png";
    const DESCRIPTION: vector<u8> = b"Boat ticket to meta masrs";
    const PROJECT_URL: vector<u8> = b"https://shui.one/game/#/";
    const CREATOR: vector<u8> = b"metaGame";

    struct GameItemsCredential has key, store {
        id: UID,
        name: string::String,
        num: u64
    }

    struct ITEMS_CREDENTIAL has drop {}

    fun init(otw: ITEMS_CREDENTIAL, ctx: &mut TxContext) {
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
        let values = vector[
            utf8(b"{name}"),
            utf8(DESCRIPTION),
            utf8(DEFAULT_LINK),
            utf8(DEFAULT_IMAGE_URL),
            utf8(PROJECT_URL),
            utf8(CREATOR)
        ];

        // Claim the `Publisher` for the package!
        let publisher = package::claim(otw, ctx);

        // Get a new `Display` object for the `GameItemsCredential` type.
        let display = display::new_with_fields<GameItemsCredential>(
            &publisher, keys, values, ctx
        );

        // // set 0% royalty
        // royalty_policy::new_royalty_policy<GameItemsCredential>(&publisher, 0, ctx);

        // Commit first version of `Display` to apply changes.
        display::update_version(&mut display);
        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(display, tx_context::sender(ctx));
    }

    public(friend) fun construct(
        name: String,
        num: u64,
        ctx: &mut TxContext,
    ): GameItemsCredential {
        GameItemsCredential {
            id: object::new(ctx),
            name,
            num
        }
    }

    public(friend) fun destruct(
        game_credential: GameItemsCredential
    ):(String, u64) {
        let GameItemsCredential {id, name, num} = game_credential;
        object::delete(id);

        return (name, num)
    }
}