module shui_module::race {
    use std::string;
    struct Race has store, copy, drop {
        category:string::String,
        desc:string::String,
    }

    public fun category(data: &Race): string::String {
        return data.category
    }
    public fun none(): Race {
        Race {
            category:string::utf8(b""),
            desc:string::utf8(b"")
        }
    }
}