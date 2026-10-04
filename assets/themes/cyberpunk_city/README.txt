THEME: CYBERPUNK CITY (id: cyberpunk_city, index 4)
===================================================
Fantasy: night skyscrapers, neon grid, glowing tarmac, boost strips.

Palette:
  side      #0F0D1F   side_dark #0A0817
  road      #1A1A2B   edge      #0DE6FF (cyan neon)
  dash      #FF61D9   accent    #FF40BF
  lighting  deep blue night dim weather: neon_rain (130) + edge glows

Decor ("cyberpunk"): tower silhouettes with lit windows, neon poles /
on-road boost-strip shimmer.

Gameplay: handling x1.00, boost zones ON (2s overdrive every 14s,
see game.gd _update_theme_boost).

SPRITES LATER: tower_*.png, billboard.png (see _make_cyberpunk()).
Keep emissive colors; avoid large transparent fills on mobile.
