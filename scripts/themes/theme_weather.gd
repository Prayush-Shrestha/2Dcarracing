class_name ThemeWeather
extends RefCounted
## Weather particles + lighting tint per theme.
## All effects are CPUParticles2D (works on GL Compatibility / mobile)
## with conservative counts. Road calls apply() on theme change.
##
## To add weather for a new theme: add a "when <key>:" branch in apply()
## and keep amount < 240, lifetime < 1.2s.

const WX_GROUP := "theme_wx"


static func clear(parent: Node) -> void:
	for c in parent.get_children():
		if c.is_in_group(WX_GROUP):
			c.queue_free()


static func apply(parent: Node, theme: Dictionary) -> void:
	clear(parent)
	# Let freed nodes actually leave before adding new ones.
	# (Parent is Road; safe because apply() runs outside physics callbacks.)
	_add_lighting(parent, theme)
	match str(theme.get("weather", "none")):
		"dust":
			_add_dust(parent)
		"sandstorm":
			_add_sandstorm(parent)
		"snow":
			_add_snow(parent)
		"rain":
			_add_rain(parent, Color(0.65, 0.78, 0.95, 0.5))
		"neon_rain":
			_add_rain(parent, Color(0.45, 0.85, 1.0, 0.45), 130)
			_add_neon_glow(parent)
		"embers":
			_add_embers(parent)
		"stars":
			_add_stars(parent)
		_:
			pass


static func _tag(n: Node) -> void:
	n.add_to_group(WX_GROUP)


static func _add_lighting(parent: Node, theme: Dictionary) -> void:
	var dim: Color = theme.get("dim", Color(0, 0, 0, 0))
	if dim.a <= 0.001:
		# Still add a faint top-glow for depth on day themes? No — keep clean.
		return
	var r := ColorRect.new()
	r.color = dim
	r.position = Vector2.ZERO
	r.size = Vector2(540, 960)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	_tag(r)
	# Extra fog band for snow/forest: second soft rect near horizon.
	var w := str(theme.get("weather", ""))
	if w == "snow" or w == "rain":
		var fog := ColorRect.new()
		fog.color = Color(0.85, 0.90, 0.95, 0.07)
		fog.position = Vector2(0, 60)
		fog.size = Vector2(540, 260)
		fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(fog)
		_tag(fog)


static func _base_particles() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(270, 10)
	p.position = Vector2(270, -10)
	return p


static func _add_dust(parent: Node) -> void:
	var p := _base_particles()
	p.amount = 60
	p.lifetime = 1.1
	p.direction = Vector2(0.5, 1.0)
	p.spread = 20.0
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 240.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = Color(0.75, 0.66, 0.55, 0.28)
	parent.add_child(p)
	_tag(p)


static func _add_sandstorm(parent: Node) -> void:
	var p := _base_particles()
	p.amount = 190
	p.lifetime = 0.9
	p.direction = Vector2(0.7, 1.0)
	p.spread = 14.0
	p.initial_velocity_min = 550.0
	p.initial_velocity_max = 800.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.5
	p.color = Color(0.92, 0.76, 0.50, 0.42)
	parent.add_child(p)
	_tag(p)


static func _add_snow(parent: Node) -> void:
	var p := _base_particles()
	p.amount = 160
	p.lifetime = 1.2
	p.direction = Vector2(0.1, 1.0)
	p.spread = 22.0
	p.initial_velocity_min = 130.0
	p.initial_velocity_max = 260.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.5
	p.color = Color(0.95, 0.97, 1.0, 0.85)
	parent.add_child(p)
	_tag(p)


static func _add_rain(parent: Node, col: Color, amount: int = 220) -> void:
	var p := _base_particles()
	p.amount = amount
	p.lifetime = 0.7
	p.direction = Vector2(0.15, 1.0)
	p.spread = 8.0
	p.initial_velocity_min = 700.0
	p.initial_velocity_max = 950.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = col
	parent.add_child(p)
	_tag(p)


static func _add_neon_glow(parent: Node) -> void:
	# Two vertical neon edge glows so the night city road feels lit.
	for x_col in [[88.0, Color(0.1, 0.85, 1.0, 0.20)], [452.0, Color(1.0, 0.25, 0.75, 0.20)]]:
		var g := ColorRect.new()
		g.color = x_col[1]
		g.position = Vector2(float(x_col[0]) - 3.0, 0)
		g.size = Vector2(6, 960)
		g.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(g)
		_tag(g)


static func _add_embers(parent: Node) -> void:
	var p := _base_particles()
	p.amount = 120
	p.lifetime = 1.0
	p.position = Vector2(270, 970)
	p.emission_rect_extents = Vector2(270, 10)
	p.direction = Vector2(-0.1, -1.0)
	p.spread = 18.0
	p.initial_velocity_min = 140.0
	p.initial_velocity_max = 320.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	p.color = Color(1.0, 0.45, 0.12, 0.8)
	parent.add_child(p)
	_tag(p)
	# Falling ash on top.
	var ash := _base_particles()
	ash.amount = 50
	ash.lifetime = 1.1
	ash.direction = Vector2(0.0, 1.0)
	ash.spread = 25.0
	ash.initial_velocity_min = 90.0
	ash.initial_velocity_max = 180.0
	ash.scale_amount_min = 1.0
	ash.scale_amount_max = 2.0
	ash.color = Color(0.25, 0.18, 0.16, 0.5)
	parent.add_child(ash)
	_tag(ash)


static func _add_stars(parent: Node) -> void:
	var p := _base_particles()
	p.amount = 90
	p.lifetime = 1.4
	p.direction = Vector2(0.0, 1.0)
	p.spread = 6.0
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 150.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.5
	p.color = Color(0.70, 1.0, 0.90, 0.7)
	parent.add_child(p)
	_tag(p)
