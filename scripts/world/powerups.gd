class_name PowerUpDef
extends RefCounted
## Power-up definitions shared by the PowerUp scene and game.gd.
## SHIELD blocks one crash. MAGNET pulls nearby coins for a duration.

const KIND_SHIELD := "shield"
const KIND_MAGNET := "magnet"

const MAGNET_DURATION := 8.0
const MAGNET_RADIUS := 220.0
const SPAWN_INTERVAL := 14.0


static func color_for(kind: String) -> Color:
	match kind:
		KIND_SHIELD:
			return Color(0.35, 0.75, 1.0)
		KIND_MAGNET:
			return Color(1.0, 0.45, 0.55)
	return Color.WHITE


static func label_for(kind: String) -> String:
	match kind:
		KIND_SHIELD:
			return "SHIELD"
		KIND_MAGNET:
			return "MAGNET"
	return kind.to_upper()
