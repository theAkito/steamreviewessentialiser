{.experimental: "overloadableEnums".}

type
  ReviewType * = enum
    all = "all",
    positive = "positive",
    negative = "negative" 
  PurchaseType * = enum
    all = "all",
    non_steam_purchase = "non_steam_purchase",
    steam = "steam" 
  Language * = enum ## https://partner.steamgames.com/doc/store/localization
    english = "english",
    all = "all"

  ClientType * = enum ## Type of client sending the Tag Cloud request to this server.
    desktop = "desktop",
    mobile = "mobile",
    webui = "webui"