class_name NitroSystem
extends Node
## Nitro boost: SPACE to burn, meter drains, recharges over time.
## Game.gd reads `boost_mult` to scale road speed while active.

signal changed(value: float, max_value: float, active: bool)

const MAX_NITRO := 100.0
const DRAIN_RATE := 42.0
const RECHARGE_RATE := 16.0
const RECHARGE_DELAY := 1.2
const BOOST_MULT := 1.45

var nitro: float = MAX_NITRO
var active: bool = false
var _since_use: float = 99.0
var _wants_boost: bool = false


func _process(delta: float) -> void:
	if get_tree().paused:
		_set_active(false)
		return
	_since_use += delta
	# Input uses the InputMap action with ui fallback handled by caller.
	if _wants_boost and nitro > 5.0:
		_set_active(true)
	else:
		_set_active(false)
	if active:
		nitro = maxf(nitro - DRAIN_RATE * delta, 0.0)
		_since_use = 0.0
		if nitro <= 0.0:
			_set_active(false)
	elif _since_use >= RECHARGE_DELAY:
		nitro = minf(nitro + RECHARGE_RATE * delta, MAX_NITRO)


func set_want_boost(wants: bool) -> void:
	_wants_boost = wants and nitro > 1.0


func boost_mult() -> float:
	return BOOST_MULT if active else 1.0


func is_ready() -> bool:
	return nitro > 20.0


func _set_active(on: bool) -> void:
	if on and nitro <= 1.0:
		on = false
	if active == on:
		return
	active = on
	changed.emit(nitro, MAX_NITRO, active)
