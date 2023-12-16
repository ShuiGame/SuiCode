
module shui_module::items {
    use sui::bag::{Self};
    use sui::linked_table::{Self, LinkedTable};
    use std::vector::{Self};
    use std::string;
    use sui::tx_context::{TxContext};
    use std::option::{Self};
    use std::ascii;
    use sui::transfer;
    use sui::table::{Self};
    use sui::object::{Self, UID};

    friend shui_module::metaIdentity;
    friend shui_module::tree_of_life;

    const ERR_ITEMS_VEC_NOT_EXIST:u64 = 0x001;
    const ERR_ITEMS_NOT_EXIST:u64 = 0x002;
    const ERR_ITEMS_NOT_ENOUGH:u64 = 0x003;

    struct Items has store {
        // store all objects: name -> vector<T>
        bags:bag::Bag,

        // store nums of objects for print: name -> num
        link_table:LinkedTable<string::String, u16>,
    }

    struct ItemGlobal has key {
        id: UID,

        // store name -> desc
        desc_table:table::Table<string::String, string::String>,
    }

    #[test_only]
    public fun init_for_test(ctx: &mut TxContext) {
        let global = ItemGlobal {
            id: object::new(ctx),
            desc_table: table::new<string::String, string::String>(ctx)
        };
        init_items_desc(&mut global);
        transfer::share_object(global);
    }

    fun init(ctx: &mut TxContext) {
        let global = ItemGlobal {
            id: object::new(ctx),
            desc_table: table::new<string::String, string::String>(ctx)
        };
        init_items_desc(&mut global);
        transfer::share_object(global);
    }

    fun init_items_desc(global:&mut ItemGlobal) {
        // fruit
        table::add(&mut global.desc_table, string::utf8(b"fruit"), string::utf8(b"fruit desc"));

        // water element
        table::add(&mut global.desc_table, string::utf8(b"water_element_holy"), string::utf8(b"holy water element desc"));
        table::add(&mut global.desc_table, string::utf8(b"water_element_blood"), string::utf8(b"blood water element desc"));
        table::add(&mut global.desc_table, string::utf8(b"water_element_resurrect"), string::utf8(b"resurrect water element desc"));
        table::add(&mut global.desc_table, string::utf8(b"water_element_life"), string::utf8(b"life water element desc"));
        table::add(&mut global.desc_table, string::utf8(b"water_element_memory"), string::utf8(b"memory water element desc"));

        // fragment
        table::add(&mut global.desc_table, string::utf8(b"fragment_holy"), string::utf8(b"holy water element fragment desc"));
        table::add(&mut global.desc_table, string::utf8(b"fragment_blood"), string::utf8(b"holy water element fragment desc"));
        table::add(&mut global.desc_table, string::utf8(b"fragment_resurrect"), string::utf8(b"holy water element fragment desc"));
        table::add(&mut global.desc_table, string::utf8(b"fragment_life"), string::utf8(b"holy water element fragment desc"));
        table::add(&mut global.desc_table, string::utf8(b"fragment_memory"), string::utf8(b"holy water element fragment desc"));
    }

    public(friend) fun new(ctx:&mut TxContext): Items {
        Items {
            bags:bag::new(ctx),
            link_table:linked_table::new<string::String, u16>(ctx),
        }
    }

    public(friend) fun destroy_empty(items: Items) {
        let Items {bags:bags, link_table} = items;
        linked_table::drop(link_table);
        bag::destroy_empty(bags);
    }

    public(friend) fun store_item<T:store>(items: &mut Items, name:string::String, item:T) {
        if (bag::contains(&mut items.bags, name)) {
            let vec = bag::borrow_mut(&mut items.bags, name);
            vector::push_back(vec, item);
            let len = vector::length(vec);
            set_items_num(&mut items.link_table, name, (len as u16));
        } else {
            let vec = vector::empty<T>();
            vector::push_back(&mut vec, item);
            bag::add(&mut items.bags, name, vec);
            set_items_num(&mut items.link_table, name, 1);
        }
    }

    public(friend) fun store_items<T:store>(items: &mut Items, name:string::String, item_arr: vector<T>) {
        if (bag::contains(&mut items.bags, name)) {
            let vec = bag::borrow_mut(&mut items.bags, name);
            let (i, len) = (0u64, vector::length(&item_arr));
            while (i < len) {
                let item:T = vector::pop_back(&mut item_arr);
                vector::push_back(vec, item);
                i = i + 1
            };
            let len = vector::length(vec);
            set_items_num(&mut items.link_table, name, (len as u16));
        } else {
            let vec = vector::empty<T>();
            let (i, len) = (0u64, vector::length(&item_arr));
            while (i < len) {
                let item:T = vector::pop_back(&mut item_arr);
                vector::push_back(&mut vec, item);
                i = i + 1
            };
            bag::add(&mut items.bags, name, vec);
            set_items_num(&mut items.link_table, name, (len as u16));
        };
        vector::destroy_empty(item_arr);
    }

    public(friend) fun extract_item<T:store>(items: &mut Items, name:string::String): T {
        assert!(bag::contains(&items.bags, name), ERR_ITEMS_VEC_NOT_EXIST);
        let vec:&mut vector<T> = bag::borrow_mut(&mut items.bags, name);
        assert!(vector::length(vec) > 0, ERR_ITEMS_NOT_EXIST);
        let item = vector::pop_back(vec);
        let len = vector::length(vec);
        set_items_num(&mut items.link_table, name, (len as u16));
        item
    }

    public(friend) fun extract_items<T:store>(items: &mut Items, name:string::String, num:u64): vector<T> {
        assert!(bag::contains(&items.bags, name), ERR_ITEMS_VEC_NOT_EXIST);
        let vec:&mut vector<T> = bag::borrow_mut(&mut items.bags, name);
        assert!(vector::length(vec) >= num, ERR_ITEMS_NOT_ENOUGH);
        let extra_vec = vector::empty();
        let i = 0u64;
        while (i < num) {
            let item:T = vector::pop_back(vec);
            vector::push_back(&mut extra_vec, item);
            i = i + 1
        };
        let len = vector::length(vec);
        set_items_num(&mut items.link_table, name, (len as u16));
        extra_vec
    }

    fun set_items_num(linked_table: &mut linked_table::LinkedTable<string::String, u16>, name:string::String, num:u16) {
        if (linked_table::contains(linked_table, name)) {
            if (num == 0) {
                linked_table::remove(linked_table, name);
                return
            };
            let num_m = linked_table::borrow_mut(linked_table, name);
            *num_m = num;
        } else {
            linked_table::push_back(linked_table, name, num);
        }
    }

    public(friend) fun get_items_info(itemGlobal:&ItemGlobal, items: &Items) : string::String {
        // :
        let byte_colon = ascii::byte(ascii::char(58));
        // ;
        let byte_semi = ascii::byte(ascii::char(59));
        // ,
        let byte_comma = ascii::byte(ascii::char(44));

        let table: &linked_table::LinkedTable<string::String, u16> = &items.link_table;
        if (linked_table::is_empty(table)) {
            return string::utf8(b"none")
        };
        let vec_out:vector<u8> = *string::bytes(&string::utf8(b""));
        let key:&option::Option<string::String> = linked_table::front(table);
        let key_value = *option::borrow(key);

        // name:num,desc;
        vector::append(&mut vec_out, *string::bytes(&key_value));
        vector::push_back(&mut vec_out, byte_colon);
        let val_str = linked_table::borrow(table, key_value);
        vector::append(&mut vec_out, numbers_to_ascii_vector(*val_str));
        vector::push_back(&mut vec_out, byte_comma);
        let desc_str = get_desc_by_name(itemGlobal, key_value);
        vector::append(&mut vec_out, *string::bytes(&desc_str));
        vector::push_back(&mut vec_out, byte_semi);

        let next:&option::Option<string::String> = linked_table::next(table, *option::borrow(key));
        while (option::is_some(next)) {
            let key_value = *option::borrow(next);
            vector::append(&mut vec_out, *string::bytes(&key_value));
            vector::push_back(&mut vec_out, byte_colon);

            let val_str = linked_table::borrow(table, key_value);
            vector::append(&mut vec_out, numbers_to_ascii_vector(*val_str));
            vector::push_back(&mut vec_out, byte_comma);
            let desc_str = get_desc_by_name(itemGlobal, key_value);
            vector::append(&mut vec_out, *string::bytes(&desc_str));
            vector::push_back(&mut vec_out, byte_semi);
            next = linked_table::next(table, key_value);
        };

        string::utf8(vec_out)
    }

    // 123 -> [49,50,51]
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

    public fun get_desc_by_name(global: &ItemGlobal, name:string::String): string::String {
        if (table::contains(&global.desc_table, name)) {
            return *table::borrow(&global.desc_table, name)
        };
        string::utf8(b"None")
    }

}