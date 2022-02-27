##[
  Retrieve information about Steam games.
  Mainly needed for searching a game through human titles and then matching their unique App IDs.
]##

import
  meta,
  std/[
    re
  ],
  pkg/[
    puppy
  ]

const
  url = "https://api.steampowered.com/ISteamApps/GetAppList/v0002"