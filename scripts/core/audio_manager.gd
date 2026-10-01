class_name AudioManager
extends RefCounted
## Central audio helper. All sounds are optional files with synthesized
## fallback tones, so the game never breaks when assets are missing.
## Volumes are persisted via SaveManager (music_volume / sfx_volume / muted).

const SOUND_DIR := "res://assets/sounds/"

# File names looked up first; every one is optional.
const FILES := {
	"click": "click.wav",
	"coin": "coin.wav",
	"crash": "crash.wav",
	"level": "level.wav",
	"engine": "engine.wav",
	"gameover": "gameover.wav",
	"victory": "victory.wav",
	"nitro": "nitro.wav",
	"powerup": "powerup.wav",
}


static func apply_volumes(music_volume: float, sfx_volume: float, muted: bool) -> void:
	if muted:
		AudioServer.set_bus_mute(0, true)
		return
	AudioServer.set_bus_mute(0, false)
	var music_db := linear_to_db(clampf(music_volume, 0.001, 1.0))
	var sfx_db := linear_to_db(clampf(sfx_volume, 0.001, 1.0))
	# Bus 0 is Master; keep it simple and drive both from saved prefs.
	AudioServer.set_bus_volume_db(0, minf(music_db, sfx_db))


static func stream_for(kind: String) -> AudioStream:
	var fname: String = FILES.get(kind, "")
	if fname != "" and FileAccess.file_exists(SOUND_DIR + fname):
		var loaded := load(SOUND_DIR + fname)
		if loaded is AudioStream:
			return loaded
	# Synthesized fallback per kind.
	match kind:
		"click":
			return make_tone(660.0, 0.07, 0.4)
		"coin":
			return make_tone(990.0, 0.12, 0.45, 1560.0)
		"crash":
			return make_tone(160.0, 0.35, 0.6, 60.0)
		"level":
			return make_tone(520.0, 0.18, 0.4, 880.0)
		"gameover":
			return make_gameover_tone()
		"victory":
			return make_victory_tone()
		"nitro":
			return make_tone(220.0, 0.4, 0.5, 880.0)
		"powerup":
			return make_tone(740.0, 0.16, 0.45, 1180.0)
	return make_tone(440.0, 0.1, 0.4)


static func play(player: AudioStreamPlayer, kind: String, muted: bool = false) -> void:
	if muted or player == null:
		return
	if AudioServer.is_bus_mute(0):
		return
	player.stream = stream_for(kind)
	player.play()


static func make_tone(freq: float, dur: float, volume: float = 0.5, slide_to: float = 0.0) -> AudioStreamWAV:
	var rate := 22050
	var frames := int(rate * dur)
	var data := PackedByteArray()
	data.resize(frames)
	var end_f := slide_to if slide_to > 0.0 else freq
	for i in range(frames):
		var t := float(i) / float(rate)
		var k := float(i) / float(maxi(frames - 1, 1))
		var f := lerpf(freq, end_f, k)
		data[i] = int(128.0 + 90.0 * volume * sin(TAU * f * t))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	return stream


static func make_engine_loop() -> AudioStreamWAV:
	var f := file_stream("engine")
	if f is AudioStreamWAV:
		var wav := f as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		var bytes_per_frame := 2 if wav.stereo else 1
		if wav.format == AudioStreamWAV.FORMAT_16_BITS:
			bytes_per_frame *= 2
		wav.loop_end = int(wav.data.size() / bytes_per_frame)
		return wav
	if f != null:
		return null
	var rate := 22050
	var frames := int(rate * 0.5)
	var data := PackedByteArray()
	data.resize(frames)
	for i in range(frames):
		var t := float(i) / float(rate)
		data[i] = int(128.0 + 40.0 * sin(TAU * 82.0 * t) + 18.0 * sin(TAU * 164.0 * t))
	var loop := AudioStreamWAV.new()
	loop.format = AudioStreamWAV.FORMAT_8_BITS
	loop.mix_rate = rate
	loop.stereo = false
	loop.data = data
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_begin = 0
	loop.loop_end = frames
	return loop


static func make_gameover_tone() -> AudioStreamWAV:
	var rate := 22050
	var frames := int(rate * 0.5)
	var data := PackedByteArray()
	data.resize(frames)
	for i in range(frames):
		var t := float(i) / float(rate)
		var k := float(i) / float(frames)
		data[i] = int(128.0 + 80.0 * (1.0 - k) * sin(TAU * lerpf(320.0, 110.0, k) * t))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = rate
	stream.data = data
	return stream


static func make_victory_tone() -> AudioStreamWAV:
	var rate := 22050
	var notes := [523.25, 659.25, 783.99, 1046.5, 1318.5]
	var total := 0.9
	var frames := int(rate * total)
	var data := PackedByteArray()
	data.resize(frames)
	for i in range(frames):
		var t := float(i) / float(rate)
		var k := int(t / 0.16)
		var f: float = notes[mini(k, notes.size() - 1)]
		var env := exp(-3.0 * (t - float(k) * 0.16) / 0.16)
		data[i] = int(128.0 + 80.0 * env * sin(TAU * f * t))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = rate
	stream.data = data
	return stream


static func file_stream(kind: String) -> AudioStream:
	var fname: String = FILES.get(kind, "")
	if fname != "" and FileAccess.file_exists(SOUND_DIR + fname):
		var loaded := load(SOUND_DIR + fname)
		if loaded is AudioStream:
			return loaded
	return null
