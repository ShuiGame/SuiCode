module shui_module::avatar {
    use std::string;
    struct Avatar has store, copy, drop {
        url:string::String,
    }

    public fun get_icon(data: &Avatar): string::String {
        return data.url
    }

    public fun new_icon(url:string::String): Avatar{
        Avatar {
            url:url
        }
    }

    public fun none(): Avatar{
        Avatar {
            url:string::utf8(b"")
        }
    }

    public fun set_icon(avatar:&mut Avatar, url:string::String) {
        avatar.url = url;
    }
}