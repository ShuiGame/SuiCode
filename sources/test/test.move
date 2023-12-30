// Copyright 2023 ComingChat Authors. Licensed under Apache-2.0 License.
#[test_only]
module MetaGame::airdrop_test {
    use std::vector;
    use std::string::{Self, utf8};
    use sui::clock::{Self, Clock};
    use std::debug::print;
    use MetaGame::items_credential;
    use sui::coin::{Self, Coin};
    use sui::test_scenario::{
        Scenario, next_tx, begin, end, ctx, take_shared, return_shared, take_from_sender,return_to_sender,take_from_address,
        next_epoch
    };

    use sui::sui::SUI;
    use sui::tx_context;
    use sui::pay;
    use MetaGame::items::{Self};
    use MetaGame::shui::{Self};
    use MetaGame::metaIdentity::{Self};
    use MetaGame::airdrop::{Self};
    use MetaGame::founder_team_reserve::{Self};
    use MetaGame::swap::{Self};
    use MetaGame::tree_of_life::{Self};
    use MetaGame::crypto::{Self};
    use MetaGame::market;
    use MetaGame::boat_ticket::{Self};
    use MetaGame::mission;
    use sui::kiosk::{Self};

    const DAY_IN_MS: u64 = 86_400_000;
    const HOUR_IN_MS: u64 = 3_600_000;
    const START:u64 = 80000;

    struct OTW has drop {}

    // utilities
    fun scenario(): Scenario { begin(@account) }

    fun claim_airdrop(test: &mut Scenario, clock:&clock::Clock) {
        let airdropGlobal = take_shared<airdrop::AirdropGlobal>(test);
        let meta = take_from_sender<metaIdentity::MetaIdentity>(test);
        let missionGlobal = take_shared<mission::MissionGlobal>(test);
        airdrop::claim_airdrop(&mut missionGlobal, &mut airdropGlobal, &meta, clock, ctx(test));
        return_to_sender(test, meta);
        return_shared(airdropGlobal);
        return_shared(missionGlobal);
    }

    fun water_down(test: &mut Scenario, user:address, clock:&clock::Clock) {
        let treeGlobal = take_shared<tree_of_life::TreeGlobal>(test);
        let missionGlobal = take_shared<mission::MissionGlobal>(test);
        let meta = take_from_sender<metaIdentity::MetaIdentity>(test);
        let coin = take_from_address<Coin<shui::SHUI>>(test, user);
        let coins = vector::empty<Coin<shui::SHUI>>();
        vector::push_back(&mut coins, coin);
        tree_of_life::water_down(&mut missionGlobal, &mut treeGlobal, &mut meta, coins, clock, ctx(test));
        return_to_sender(test, meta);
        return_shared(treeGlobal);
        return_shared(missionGlobal);
    }

    fun print_items(itemGlobal: &items::ItemGlobal, test: &mut Scenario) {
        let meta = take_from_sender<metaIdentity::MetaIdentity>(test);
        let items_info = metaIdentity::get_items_info(&meta, itemGlobal);
        print(&items_info);
        return_to_sender(test, meta);
    }

    fun print_missions(test: &mut Scenario, clock: &Clock) {
        let missionGlobal = take_shared<mission::MissionGlobal>(test);
        let meta = take_from_sender<metaIdentity::MetaIdentity>(test);
        let mission_list = mission::query_mission_list(&missionGlobal, &mut meta, clock);
        print(&string::utf8(b"----------Mission_list----------"));
        print(&mission_list);
        print(&string::utf8(b"----------End----------"));
        return_to_sender(test, meta);
        return_shared(missionGlobal);
    }

    fun print_balance(test: &mut Scenario, user:address) {
        let coin = take_from_address<Coin<shui::SHUI>>(test, user);
        let value = coin::value(&coin);
        print(&string::utf8(b"account shui:"));
        print(&value);
        pay::keep(coin, ctx(test));
    }

    // #[test]
    fun test_crypto() {
        let scenario = scenario();
        let test = &mut scenario;
        let admin = @account;

        // init package
        next_tx(test, admin);
        {
            let res = crypto::test_ecds();
            print(&string::utf8(b"test:"));
            print(&res);
            // print(hex::decode(b"This is a test of the tsunami alert system."));
        };
        end(scenario);
    }

    #[test]
    fun test_market() {
        let scenario = scenario();
        let test = &mut scenario;
        let admin = @account;
        let user = @user;
        let clock = clock::create_for_testing(ctx(test));

        // init package
        next_tx(test, admin);
        {
            shui::init_for_test(test);
            metaIdentity::init_for_test(ctx(test));
            airdrop::init_for_test(ctx(test));
            swap::init_for_test(ctx(test));
            founder_team_reserve::init_for_test(ctx(test));
            tree_of_life::init_for_test(ctx(test));
            items::init_for_test(ctx(test));
            mission::init_for_test(ctx(test));
            market::init_for_test(ctx(test));
        };

        // funds split
        next_tx(test, admin);
        {
            let shuiGlobal = take_shared<shui::Global>(test);
            let airdropGlobal = take_shared<airdrop::AirdropGlobal>(test);
            let reserveGlobal = take_shared<founder_team_reserve::FounderTeamGlobal>(test); 
            airdrop::init_funds_from_main_contract(&mut airdropGlobal, &mut shuiGlobal, ctx(test));
            founder_team_reserve::init_funds_from_main_contract(&mut reserveGlobal, &mut shuiGlobal, ctx(test));
            return_shared(shuiGlobal);
            return_shared(airdropGlobal);
            return_shared(reserveGlobal);
        };

        next_tx(test, admin);
        {
            clock::increment_for_testing(&mut clock, 1 * DAY_IN_MS);
            let airdropGlobal = take_shared<airdrop::AirdropGlobal>(test);
            let timeCap = take_from_sender<airdrop::TimeCap>(test);
            airdrop::start_timing(&mut airdropGlobal, timeCap, &clock);
            return_shared(airdropGlobal);
        };

        // register meta
        next_tx(test, admin);
        {
            let global = take_shared<metaIdentity::MetaInfoGlobal>(test);
            metaIdentity::mintMeta(
                &mut global,
                string::utf8(b"sean"),
                string::utf8(b"13262272231"),
                string::utf8(b"448651346@qq.com"),
                admin,
                ctx(test)
            );
            return_shared(global)
        };

        next_tx(test, user);
        {
            let global = take_shared<metaIdentity::MetaInfoGlobal>(test);
            metaIdentity::mintMeta(
                &mut global,
                string::utf8(b"sean2"),
                string::utf8(b"13262272331"),
                string::utf8(b"448651346@qq.com"),
                user,
                ctx(test)
            );
            return_shared(global)
        };

        // next_tx(test, user);
        // {
        //     let global = take_shared<metaIdentity::MetaInfoGlobal>(test);
        //     metaIdentity::mintInviteMeta(
        //         &mut global,
        //         20001,
        //         string::utf8(b"sean3"),
        //         string::utf8(b"13262272322331"),
        //         string::utf8(b"448651346@qq.com"),
        //         user2,
        //         ctx(test)
        //     );
        //     print(&utf8(b"invite query:"));
        //     print(&metaIdentity::query_invited_num(&global, 20001));
        //     return_shared(global)
        // };

        next_tx(test, admin);
        {
            boat_ticket::init_for_test(ctx(test));
            next_epoch(test, admin);
            let boatGlobal = take_shared<boat_ticket::BoatTicketGlobal>(test);
            boat_ticket::claim_ticket(&mut boatGlobal, ctx(test));
            return_shared(boatGlobal);
        };

        next_tx(test, user);
        {
            next_epoch(test, user);
            let boatGlobal = take_shared<boat_ticket::BoatTicketGlobal>(test);
            boat_ticket::claim_ticket(&mut boatGlobal, ctx(test));
            return_shared(boatGlobal);
        };

        next_tx(test, admin);
        {
            let missionGlobal = take_shared<mission::MissionGlobal>(test);
            mission::init_missions(&mut missionGlobal, &clock, ctx(test));
            return_shared(missionGlobal);
            clock::increment_for_testing(&mut clock, 2 * DAY_IN_MS + 600000);
            next_epoch(test, admin);
            print_missions(test, &clock);
        };

        next_tx(test, admin);
        {
            let itemGlobal = take_shared<items::ItemGlobal>(test);
            let i = 0;
            while (i < 4) {
                clock::increment_for_testing(&mut clock, 8 * HOUR_IN_MS + 1);
                water_down(test, admin, &clock);
                next_epoch(test, admin);
                i = i + 1;
            };
            return_shared(itemGlobal);
            next_epoch(test, admin);
            print_missions(test, &clock);
        };

        next_tx(test, user);
        {
            clock::increment_for_testing(&mut clock, 2 * DAY_IN_MS + 600000);
            claim_airdrop(test, &clock);
        };

        next_tx(test, user);
        {
            let itemGlobal = take_shared<items::ItemGlobal>(test);
            let i = 0;
            while (i < 4) {
                clock::increment_for_testing(&mut clock, 8 * HOUR_IN_MS + 1);
                water_down(test, user, &clock);
                next_epoch(test, user);
                i = i + 1;
            };
            return_shared(itemGlobal);
            next_epoch(test, user);
            print_missions(test, &clock);
        };

        // next_tx(test, admin);
        // {
        //     let missionGlobal = take_shared<mission::MissionGlobal>(test);
        //     let meta = take_from_sender<metaIdentity::MetaIdentity>(test);
        //     mission::claim_mission(&mut missionGlobal, utf8(b"water down"), &mut meta);
        //     next_epoch(test, admin);
        //     return_to_sender(test, meta);
        //     return_shared(missionGlobal);
        //     next_epoch(test, admin);
        //     print_missions(test, &clock);
        // };

        // water down
        next_tx(test, admin);
        {
            let itemGlobal = take_shared<items::ItemGlobal>(test);
            let i = 0;
            while (i < 20) {
                clock::increment_for_testing(&mut clock, 8 * HOUR_IN_MS + 1);
                water_down(test, admin, &clock);
                next_epoch(test, admin);
                i = i + 1;
            };
            print_items(&itemGlobal, test);
            return_shared(itemGlobal);
        };

        // open fruit for fragment
        next_tx(test, admin);
        {
            print(&string::utf8(b"open some fruits"));
            let itemGlobal = take_shared<items::ItemGlobal>(test);
            tx_context::increment_epoch_timestamp(ctx(test), 4);
            let i = 0;
            let loop_num = 5;
            while (i < loop_num) {
                let meta = take_from_sender<metaIdentity::MetaIdentity>(test);
                tree_of_life::open_fruit(&mut meta, ctx(test));
                return_to_sender(test, meta);
                next_epoch(test, admin);
                i = i + 1;
                next_epoch(test, admin);
            };
            print_items(&itemGlobal, test);
            return_shared(itemGlobal);
        };

        next_tx(test, admin);
        {
            print(&string::utf8(b"-----------------start market test---------------"));
            let market_global =  take_shared<market::MarketGlobal>(test);
            let itemGlobal = take_shared<items::ItemGlobal>(test);
            let ticket = take_from_sender<boat_ticket::BoatTicket>(test);
            let meta = take_from_sender<metaIdentity::MetaIdentity>(test);
            market::list_nft_item<boat_ticket::BoatTicket>(&mut market_global, &mut meta, utf8(b"boat_ticket"), 1132, utf8(b"SUI"), &clock, ticket, ctx(test));
            return_to_sender(test, meta);
            let res = market::get_game_sales(&market_global, &clock);
            print(&res);

            return_shared(market_global);
            next_epoch(test, admin);

            print_items(&itemGlobal, test);
            return_shared(itemGlobal);
        };

        next_tx(test, user);
        {
            print(&string::utf8(b"-----------------start user list test---------------"));
            let market_global =  take_shared<market::MarketGlobal>(test);
            let itemGlobal = take_shared<items::ItemGlobal>(test);
            let meta = take_from_sender<metaIdentity::MetaIdentity>(test);
            let ticket = take_from_sender<boat_ticket::BoatTicket>(test);
            market::list_game_item(&mut market_global, &mut meta, utf8(b"LuckyBox"), 1,  1, utf8(b"SUI"), &clock, ctx(test));
            market::list_nft_item<boat_ticket::BoatTicket>(&mut market_global, &mut meta, utf8(b"boat_ticket"), 12, utf8(b"SUI"), &clock, ticket, ctx(test));
            return_to_sender(test, meta);
            let res = market::get_game_sales(&market_global, &clock);
            let my_sales = market::query_my_onsale(&market_global, 20001);
            print(&utf8(b"mysales"));
            print(&my_sales);
            print(&res);
            return_shared(market_global);
            return_shared(itemGlobal);
        };

        // unlist test
        // next_tx(test, admin);
        // {
        //     print(&string::utf8(b"-----------------start unlist test---------------"));
        //     let market_global =  take_shared<market::MarketGlobal>(test);
        //     let itemGlobal = take_shared<items::ItemGlobal>(test);
        //     let meta = take_from_sender<metaIdentity::MetaIdentity>(test);
        //     print(&metaIdentity::getMetaId(&meta));
        //     market::unlist_game_item(&mut market_global, &mut meta, utf8(b"Water Element Memory"), 1,  1, &clock, ctx(test));
        //     market::unlist_nft_item<boat_ticket::BoatTicket>(&mut market_global, &mut meta, utf8(b"boat_ticket"), 1, 1132, &clock, ctx(test));
        //     return_to_sender(test, meta);
        //     return_shared(market_global);
        //     return_shared(itemGlobal);
        // };

        next_tx(test, admin);
        {
            let itemGlobal = take_shared<items::ItemGlobal>(test);
            print_items(&itemGlobal, test);
            return_shared(itemGlobal);
        };

        // market purchase test
        next_tx(test, admin);
        {
            print(&string::utf8(b"-----------------start purchase test---------------"));
            let market_global =  take_shared<market::MarketGlobal>(test);
            let itemGlobal = take_shared<items::ItemGlobal>(test);
            let meta = take_from_sender<metaIdentity::MetaIdentity>(test);
            // let coin = coin::mint_for_testing<SUI>(1, ctx(test));
            // let coins = vector::empty<Coin<SUI>>();
            let coin2 = coin::mint_for_testing<SUI>(12, ctx(test));
            let coins2 = vector::empty<Coin<SUI>>();
            // vector::push_back(&mut coins, coin);
            vector::push_back(&mut coins2, coin2);
            market::purchase_nft_item<SUI, boat_ticket::BoatTicket>(&mut market_global, &mut meta, 20001, utf8(b"boat_ticket"), 1, coins2, &clock, ctx(test));
            return_to_sender(test, meta);
            let res = market::get_game_sales(&market_global, &clock);
            print(&res);
            return_shared(market_global);
            return_shared(itemGlobal);
        };

        next_tx(test, admin);
        {
            let itemGlobal = take_shared<items::ItemGlobal>(test);
            print_items(&itemGlobal, test);
            return_shared(itemGlobal);
        };

        next_tx(test, admin);
        {
            let type = 0;
            let founderTeamGlobal = take_shared<founder_team_reserve::FounderTeamGlobal>(test);
            founder_team_reserve::next_phase(&mut founderTeamGlobal, &clock, ctx(test));
            founder_team_reserve::add_white_list(&mut founderTeamGlobal, @account, 500, ctx(test));
            return_shared(founderTeamGlobal);
            next_epoch(test, admin);
        };

        next_tx(test, admin);
        {
            let type = 0;
            let founderTeamGlobal = take_shared<founder_team_reserve::FounderTeamGlobal>(test);
            founder_team_reserve::claim_reserve(&mut founderTeamGlobal, 500, ctx(test));
            return_shared(founderTeamGlobal);
            next_epoch(test, admin);
        };

        clock::destroy_for_testing(clock);  
        end(scenario);
    }
}