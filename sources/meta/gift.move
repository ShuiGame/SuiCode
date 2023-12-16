module shui_module::gift {
    use std::string;

    struct Gift has store, copy, drop {
        gift:string::String,
    }

    public fun get_gift(data: &Gift): string::String {
        return data.gift
    }

    public entry fun new_gift(gift_json:string::String): Gift{
        Gift {
            gift:gift_json
        }
    }

    public entry fun none() : Gift {
        Gift {
            gift:string::utf8(b"")
        }
    }
}