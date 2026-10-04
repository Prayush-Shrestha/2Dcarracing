THEME: ROCK MOUNTAIN (id: rock_mountain, index 0)
================================================
Fantasy: extreme off-road. Rocky cliffs, boulders, caution posts,
dirt track, dust in the air.

Palette (matches ThemeManager):
  side      #6B594D   side_dark #54473D
  road      #453D38   edge      #F2BF52 (caution yellow)
  dash      #FAEED0   accent    #EB8528
  lighting  none (daylight)     weather: dust

Decor (scripts/themes/theme_decor.gd -> "rock"):
  roadside: boulders, cliff slabs, caution posts
  on-road:  dirt patches (translucent, visual only)

Gameplay: handling x0.90 (uneven), speed x1.00.

HOW TO ADD SPRITES LATER:
  Drop PNGs here (e.g. boulder.png, cliff.png) and extend
  ThemeDecor._make_rock() to instance Sprite2D instead of Polygon2D.
  Keep sprites <= 64px, 1 draw call each; decor pool stays at ~18 nodes.
