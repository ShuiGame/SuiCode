-crypto 没有启动，之前是准备用来做服务器签名校验的（手机注册账号时，服务器后端发送私钥给客户端，客户来发送给合约，来证明用户的有效性）
-market 主要分为2块，游戏内的道具，为了防止用户自由交易，所以没设计成key+store，但是kiosk想上架，就得把游戏道具转成一个标准GameItemsCredential来上架，用户购买后又会自动转成游戏道具
        另一个就是nft,目前游戏内的nft就只有一个Ticket船票（已支持交易），shui票（暂不支持交易）
        kiosk框架用的不是很熟，主要有2个问题 1：不知道怎么把nft写成一个泛型来交易  2：policy支付的时候，不知道怎么获取物品价格，所以目前就0手续费
-meta 用户身份，游戏内各种功能基本都需要传递meta这个obj来确认身份, items是物品栏
-mission 任务系统，管理员发布任务，所有人完成后可以获得奖励，奖励的领取还未完成
-nft 船票，shui票。  tree_of_life_record是之前用来记录IDO推荐人的白名单，tree_of_life里写了浇水，开箱，合成（交换碎片）等各种主要业务逻辑
-shui airdrop空投，shui发币逻辑，swap是shui的购买兑换，founder_team_reserve是预留的白名单。