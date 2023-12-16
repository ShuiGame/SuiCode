module shui_module::crypto {
    use sui::ed25519;

    public fun test_ecds(): bool {
        let msg = b"set whitelist";
        // private key = x"efe7a39deee0e595eb1ff861267af60b404dd08f21ecb15b01571fcd662c9ae4"
        let pk = x"fbbea5cd4a5039652c5e565b22551fc9253f5df9b415ca269689c1c32f4a1cfc";
        let sig = x"26C49F2F7AECECCFF917A65AE13C7CAEE4C3273AA0819D3BE328FEBF0BDB140D3BC2A7B04EF4977868FD96AFEBE65CC84E4B162DB3F56831CF9F9B64CD31EB06";
        ed25519::ed25519_verify(&sig, &pk, &msg)
    }
}