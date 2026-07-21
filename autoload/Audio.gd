extends Node
## Audio
## -----
## Central sound-effects singleton. All SFX are SYNTHESIZED procedurally at
## boot into AudioStreamWAV buffers — no external .wav/.ogg assets to ship,
## no licensing to worry about, and the totem stays fully self-contained in
## a single exported .exe.
##
## Like Database/GameManager, this file knows nothing about UI: screens just
## call Audio.play_hit(), Audio.play_combo(), etc. If you later want to swap
## these synthesized beeps for real recorded SFX, drop the files in
## res://audio/ and replace the stream lookups in _ready() — call sites won't
## change.

const SAMPLE_RATE := 22050
const MASTER_DB := -12.0  # suave, mas ainda audível num totem de evento. Ajuste aqui.

var _players: Array[AudioStreamPlayer] = []
var _next := 0
const VOICES := 8  # small pool so rapid hits can overlap without cutting each other

var _streams := {}
var enabled := true

func _ready() -> void:
	# A tiny pool of players lets fast consecutive taps overlap naturally
	# instead of one sound chopping off the previous one.
	for i in range(VOICES):
		var p := AudioStreamPlayer.new()
		p.volume_db = MASTER_DB
		add_child(p)
		_players.append(p)

	_streams["hit"] = _make_hit()
	_streams["combo"] = _make_combo()
	_streams["miss"] = _make_miss()
	_streams["click"] = _make_click()
	_streams["countdown"] = _make_countdown_beep()
	_streams["go"] = _make_go_beep()
	_streams["finish"] = _make_finish()

# ---------------- Public API ----------------

func play_hit() -> void:
	_play("hit")

func play_combo() -> void:
	_play("combo")

func play_miss() -> void:
	_play("miss")

func play_click() -> void:
	_play("click")

func play_countdown() -> void:
	_play("countdown")

func play_go() -> void:
	_play("go")

func play_finish() -> void:
	_play("finish")

func _play(key: String) -> void:
	if not enabled or not _streams.has(key):
		return
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = _streams[key]
	p.play()

# ---------------- Synthesis helpers ----------------

## Builds a 16-bit mono AudioStreamWAV from an array of float samples in [-1, 1].
func _stream_from_samples(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in range(samples.size()):
		var s: float = clampf(samples[i], -1.0, 1.0)
		var v := int(s * 32767.0)
		bytes.encode_s16(i * 2, v)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream

## One tone with a soft attack + exponential decay envelope. The short
## fade-in (attack) removes the hard "click" you get when a waveform starts
## at full amplitude, which is most of what made the old SFX feel harsh.
## `shape` picks the timbre; sine is the smoothest.
func _tone(freq: float, dur: float, vol: float = 0.6, shape := "sine", decay := 6.0) -> PackedFloat32Array:
	var n := int(SAMPLE_RATE * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	var attack := int(SAMPLE_RATE * 0.008)  # ~8ms fade-in to kill the click
	var release := int(SAMPLE_RATE * 0.010)  # ~10ms fade-out at the very end
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var phase := TAU * freq * t
		var wave := 0.0
		match shape:
			"square":
				# softened square (rounded) instead of a hard ±1 edge
				wave = tanh(sin(phase) * 2.5) * 0.7
			"tri":
				wave = asin(sin(phase)) * (2.0 / PI)
			"saw":
				wave = 2.0 * (fposmod(freq * t, 1.0)) - 1.0
			_:
				wave = sin(phase)
		var env := exp(-decay * t)  # body decay
		# Attack ramp (fade-in) and a tiny release ramp (fade-out).
		if i < attack:
			env *= float(i) / attack
		if i > n - release:
			env *= float(n - i) / release
		out[i] = wave * env * vol
	return out

## Simple one-pole low-pass filter to round off high-frequency harshness,
## giving the beeps a softer, more "equalized" tone. `amount` in [0,1):
## higher = mellower.
func _lowpass(samples: PackedFloat32Array, amount: float = 0.35) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(samples.size())
	var prev := 0.0
	for i in range(samples.size()):
		prev = prev + (samples[i] - prev) * (1.0 - amount)
		out[i] = prev
	return out

func _mix(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var n: int = max(a.size(), b.size())
	var out := PackedFloat32Array()
	out.resize(n)
	for i in range(n):
		var va: float = a[i] if i < a.size() else 0.0
		var vb: float = b[i] if i < b.size() else 0.0
		out[i] = va + vb
	return out

func _concat(chunks: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for c in chunks:
		out.append_array(c)
	return out

# ---------------- Individual SFX ----------------
# All tones use sine-leaning timbres, gentle volumes and a final low-pass so
# nothing is piercing. Volumes here are pre-master (MASTER_DB lowers them all
# further). Tweak per-sound vol/decay to taste.

## Soft rounded "blip" on a hit — warm, short, not piercing.
func _make_hit() -> AudioStreamWAV:
	var body := _tone(720.0, 0.10, 0.34, "sine", 13.0)
	var sparkle := _tone(1080.0, 0.06, 0.12, "sine", 20.0)
	return _stream_from_samples(_lowpass(_mix(body, sparkle), 0.30))

## Gentle rising 3-note arpeggio for a combo — pleasant, clearly "better".
func _make_combo() -> AudioStreamWAV:
	var a := _tone(587.0, 0.09, 0.30, "sine", 11.0)   # D5
	var b := _tone(784.0, 0.09, 0.30, "sine", 11.0)   # G5
	var c := _tone(1046.0, 0.16, 0.34, "sine", 8.0)   # C6
	return _stream_from_samples(_lowpass(_concat([a, b, c]), 0.28))

## Low soft thud on a miss — a mellow "boop", not punishing.
func _make_miss() -> AudioStreamWAV:
	return _stream_from_samples(_lowpass(_tone(160.0, 0.16, 0.34, "sine", 9.0), 0.45))

## Very subtle UI tick for button presses / navigation.
func _make_click() -> AudioStreamWAV:
	return _stream_from_samples(_lowpass(_tone(480.0, 0.05, 0.20, "sine", 22.0), 0.40))

## Soft tick for each "3 / 2 / 1" countdown step.
func _make_countdown_beep() -> AudioStreamWAV:
	return _stream_from_samples(_lowpass(_tone(440.0, 0.13, 0.30, "sine", 8.0), 0.30))

## Warmer "GO!" tone when the countdown hits zero and the round starts.
func _make_go_beep() -> AudioStreamWAV:
	return _stream_from_samples(_lowpass(_tone(660.0, 0.24, 0.38, "sine", 4.5), 0.25))

## Soft descending two-note flourish when time runs out.
func _make_finish() -> AudioStreamWAV:
	var a := _tone(660.0, 0.18, 0.32, "sine", 5.5)
	var b := _tone(440.0, 0.34, 0.36, "sine", 3.5)
	return _stream_from_samples(_lowpass(_concat([a, b]), 0.28))
