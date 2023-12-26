module MetaGame::utils {
    use std::vector;

    public entry fun numbers_to_ascii_vector(val: u16): vector<u8> {
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
}