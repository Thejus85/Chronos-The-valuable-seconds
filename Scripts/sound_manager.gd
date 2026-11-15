class_name SoundManager
extends Node

## Procedural audio engine generating and playing retro sci-fi sound effects.
## Provides SFX for warp teleportation, item pickups, phase slips, UI clicks, crafting, and victory.

const SAMPLE_RATE: int = 22050
const POOL_SIZE: int = 8

static var instance: SoundManager

var _players: Array[AudioStreamPlayer] = []
var _next_player_idx: int = 0

var sfx_teleport: AudioStreamWAV
var sfx_pickup: AudioStreamWAV
var sfx_phase_slip: AudioStreamWAV
var sfx_button_click: AudioStreamWAV
var sfx_craft: AudioStreamWAV
var sfx_victory: AudioStreamWAV
var sfx_waterfall: AudioStreamWAV
var sfx_jungle_ambient: AudioStreamWAV
var sfx_dialogue_chirp: AudioStreamWAV

var _waterfall_player: AudioStreamPlayer
var _jungle_ambient_player: AudioStreamPlayer

func _init() -> void:
	if not instance:
		instance = self

func _ready() -> void:
	instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_player_pool()
	_generate_all_sfx()

static func ensure_instance(context: Node = null) -> SoundManager:
	if not instance or not is_instance_valid(instance):
		instance = SoundManager.new()
		var tree := Engine.get_main_loop() as SceneTree
		if tree and tree.root:
			tree.root.call_deferred("add_child", instance)
		elif context and context.is_inside_tree():
			context.get_tree().root.call_deferred("add_child", instance)
	return instance

func _init_player_pool() -> void:
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)

	_waterfall_player = AudioStreamPlayer.new()
	_waterfall_player.bus = "Master"
	add_child(_waterfall_player)

	_jungle_ambient_player = AudioStreamPlayer.new()
	_jungle_ambient_player.bus = "Master"
	add_child(_jungle_ambient_player)

func _get_player() -> AudioStreamPlayer:
	if _players.is_empty():
		return null
	var p := _players[_next_player_idx]
	_next_player_idx = (_next_player_idx + 1) % _players.size()
	return p

func _play_stream(stream: AudioStreamWAV, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if not stream:
		return
	var player := _get_player()
	if player:
		player.stream = stream
		player.volume_db = volume_db
		player.pitch_scale = pitch_scale
		player.play()

# ---------------------------------------------------------
# Static Public Sound Trigger APIs
# ---------------------------------------------------------

static func play_teleport() -> void:
	var sm := ensure_instance()
	if sm:
		sm._play_stream(sm.sfx_teleport, 1.0)

static func play_pickup() -> void:
	var sm := ensure_instance()
	if sm:
		sm._play_stream(sm.sfx_pickup, 0.0)

static func play_phase_slip() -> void:
	var sm := ensure_instance()
	if sm:
		sm._play_stream(sm.sfx_phase_slip, 1.5)

static func play_button_click() -> void:
	var sm := ensure_instance()
	if sm:
		sm._play_stream(sm.sfx_button_click, -4.0)

static func play_craft() -> void:
	var sm := ensure_instance()
	if sm:
		sm._play_stream(sm.sfx_craft, 2.0)

static func play_victory() -> void:
	var sm := ensure_instance()
	if sm:
		sm._play_stream(sm.sfx_victory, 3.0)

static func play_dialogue_chirp() -> void:
	var sm := ensure_instance()
	if sm:
		sm._play_stream(sm.sfx_dialogue_chirp, -3.0, 1.2)

static func start_waterfall(volume_db: float = -6.0) -> void:
	var sm := ensure_instance()
	if sm and sm._waterfall_player:
		sm._waterfall_player.stream = sm.sfx_waterfall
		sm._waterfall_player.volume_db = volume_db
		if not sm._waterfall_player.playing:
			sm._waterfall_player.play()

static func stop_waterfall() -> void:
	var sm := ensure_instance()
	if sm and sm._waterfall_player and sm._waterfall_player.playing:
		sm._waterfall_player.stop()

static func start_jungle_ambient(volume_db: float = -8.0) -> void:
	var sm := ensure_instance()
	if sm and sm._jungle_ambient_player:
		sm._jungle_ambient_player.stream = sm.sfx_jungle_ambient
		sm._jungle_ambient_player.volume_db = volume_db
		if not sm._jungle_ambient_player.playing:
			sm._jungle_ambient_player.play()

static func stop_jungle_ambient() -> void:
	var sm := ensure_instance()
	if sm and sm._jungle_ambient_player and sm._jungle_ambient_player.playing:
		sm._jungle_ambient_player.stop()

## Recursively binds click sound to any Button in node hierarchy
static func hook_buttons(root_node: Node) -> void:
	if not root_node:
		return
	if root_node is Button:
		var btn := root_node as Button
		if not btn.pressed.is_connected(play_button_click):
			btn.pressed.connect(play_button_click)
	for child in root_node.get_children():
		hook_buttons(child)

# ---------------------------------------------------------
# Procedural Audio Generators (16-bit PCM WAV)
# ---------------------------------------------------------

func _generate_all_sfx() -> void:
	sfx_button_click = _create_button_click_sfx()
	sfx_pickup = _create_pickup_sfx()
	sfx_phase_slip = _create_phase_slip_sfx()
	sfx_teleport = _create_teleport_sfx()
	sfx_craft = _create_craft_sfx()
	sfx_victory = _create_victory_sfx()
	sfx_waterfall = _create_waterfall_sfx()
	sfx_jungle_ambient = _create_jungle_ambient_sfx()
	sfx_dialogue_chirp = _create_dialogue_chirp_sfx()

func _create_wav(data: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = data
	return wav

## Short 40ms electronic UI tick
func _create_button_click_sfx() -> AudioStreamWAV:
	var duration := 0.04
	var num_samples := int(duration * float(SAMPLE_RATE))
	var bytes := PackedByteArray()
	bytes.resize(num_samples * 2)

	for i in range(num_samples):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := float(i) / float(num_samples)
		var freq: float = lerpf(1600.0, 500.0, progress)
		var env: float = exp(-progress * 8.0)
		var val: float = sin(t * freq * TAU) * env * 0.7
		var sample := clampi(int(val * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, sample)

	return _create_wav(bytes)

## Sparkling 4-tone ascending arpeggio chime (E5 -> G#5 -> B5 -> E6)
func _create_pickup_sfx() -> AudioStreamWAV:
	var duration := 0.38
	var num_samples := int(duration * float(SAMPLE_RATE))
	var bytes := PackedByteArray()
	bytes.resize(num_samples * 2)

	var freqs: Array[float] = [659.25, 830.61, 987.77, 1318.51]
	var note_duration := duration / float(freqs.size())

	for i in range(num_samples):
		var t := float(i) / float(SAMPLE_RATE)
		var note_idx := clampi(int(t / note_duration), 0, freqs.size() - 1)
		var note_t := fmod(t, note_duration)
		var f := freqs[note_idx]
		var env: float = exp(-note_t * 9.0)
		var val: float = (sin(note_t * f * TAU) * 0.6 + sin(note_t * f * 2.0 * TAU) * 0.25) * env
		var sample := clampi(int(val * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, sample)

	return _create_wav(bytes)

## Shimmering dual-oscillator phase shift sweep with chorused modulation
func _create_phase_slip_sfx() -> AudioStreamWAV:
	var duration := 0.55
	var num_samples := int(duration * float(SAMPLE_RATE))
	var bytes := PackedByteArray()
	bytes.resize(num_samples * 2)

	var phase1 := 0.0
	var phase2 := 0.0

	for i in range(num_samples):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := float(i) / float(num_samples)
		var base_freq := 320.0 + 380.0 * sin(progress * PI)
		var freq1 := base_freq
		var freq2 := base_freq * 1.015

		phase1 += (freq1 * TAU) / float(SAMPLE_RATE)
		phase2 += (freq2 * TAU) / float(SAMPLE_RATE)

		var tremolo: float = 0.75 + 0.25 * sin(t * 22.0 * TAU)
		var env: float = sin(progress * PI)
		var val: float = (sin(phase1) * 0.45 + sin(phase2) * 0.45) * env * tremolo
		var sample := clampi(int(val * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, sample)

	return _create_wav(bytes)

## Glitchy sci-fi warp burst with rapid stepping, noise modulation and sub-bass drop
func _create_teleport_sfx() -> AudioStreamWAV:
	var duration := 0.85
	var num_samples := int(duration * float(SAMPLE_RATE))
	var bytes := PackedByteArray()
	bytes.resize(num_samples * 2)

	var phase := 0.0
	var rng_seed := 12345

	for i in range(num_samples):
		var progress := float(i) / float(num_samples)
		var f: float = 160.0 + 750.0 * (progress * progress)
		if progress > 0.5:
			f = lerpf(f, 90.0, (progress - 0.5) * 2.0)

		var step_mod := float((i / 220) % 5) * 35.0
		f += step_mod

		phase += (f * TAU) / float(SAMPLE_RATE)

		rng_seed = (rng_seed * 1103515245 + 12345) & 0x7FFFFFFF
		var noise := (float(rng_seed & 0xFFFF) / 32768.0) - 1.0

		var env: float = sin(progress * PI)
		var wave: float = sin(phase) * 0.5 + (1.0 if sin(phase) > 0.0 else -1.0) * 0.15
		var val: float = (wave * 0.75 + noise * 0.25 * env) * env
		var sample := clampi(int(val * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, sample)

	return _create_wav(bytes)

## Energy surge into crystalline chime
func _create_craft_sfx() -> AudioStreamWAV:
	var duration := 0.65
	var num_samples := int(duration * float(SAMPLE_RATE))
	var bytes := PackedByteArray()
	bytes.resize(num_samples * 2)

	var phase := 0.0

	for i in range(num_samples):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := float(i) / float(num_samples)

		var f: float
		var env: float
		var val: float

		if progress < 0.4:
			var charge_p := progress / 0.4
			f = 220.0 + 660.0 * (charge_p * charge_p)
			phase += (f * TAU) / float(SAMPLE_RATE)
			env = charge_p
			val = sin(phase) * 0.6 * env
		else:
			var res_t := t - (0.4 * duration)
			var env_decay: float = exp(-res_t * 6.5)
			val = (sin(res_t * 1046.5 * TAU) * 0.5 + sin(res_t * 1318.5 * TAU) * 0.4) * env_decay

		var sample := clampi(int(val * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, sample)

	return _create_wav(bytes)

## Triumphant 3-chord fanfare sequence
func _create_victory_sfx() -> AudioStreamWAV:
	var duration := 1.4
	var num_samples := int(duration * float(SAMPLE_RATE))
	var bytes := PackedByteArray()
	bytes.resize(num_samples * 2)

	for i in range(num_samples):
		var t := float(i) / float(SAMPLE_RATE)
		var val := 0.0

		if t < 0.35:
			var env: float = exp(-t * 3.5)
			val = (sin(t * 523.25 * TAU) + sin(t * 659.25 * TAU) + sin(t * 783.99 * TAU)) / 3.0 * env
		elif t < 0.70:
			var chord_t := t - 0.35
			var env: float = exp(-chord_t * 3.5)
			val = (sin(chord_t * 783.99 * TAU) + sin(chord_t * 987.77 * TAU) + sin(chord_t * 1174.66 * TAU)) / 3.0 * env
		else:
			var chord_t := t - 0.70
			var env: float = exp(-chord_t * 2.5)
			val = (sin(chord_t * 523.25 * TAU) * 0.25 + sin(chord_t * 783.99 * TAU) * 0.25 + sin(chord_t * 1046.5 * TAU) * 0.3 + sin(chord_t * 1318.5 * TAU) * 0.2) * env

		var sample := clampi(int(val * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, sample)

	return _create_wav(bytes)

## Looping waterfall cascade sound (filtered rushing noise with natural low swells)
func _create_waterfall_sfx() -> AudioStreamWAV:
	var duration := 2.5
	var num_samples := int(duration * float(SAMPLE_RATE))
	var bytes := PackedByteArray()
	bytes.resize(num_samples * 2)

	var rng_seed := 987654321
	var lpf1 := 0.0
	var lpf2 := 0.0

	for i in range(num_samples):
		var t := float(i) / float(SAMPLE_RATE)
		rng_seed = (rng_seed * 1103515245 + 12345) & 0x7FFFFFFF
		var white := (float(rng_seed & 0xFFFF) / 32768.0) - 1.0

		lpf1 = lerpf(lpf1, white, 0.18)
		lpf2 = lerpf(lpf2, lpf1, 0.12)

		var swell := 0.85 + 0.15 * sin(t * 1.5 * TAU)
		var val := lpf2 * 0.7 * swell
		var sample := clampi(int(val * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, sample)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = bytes
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = num_samples
	return wav

## Looping forest wind and gentle chimes
func _create_jungle_ambient_sfx() -> AudioStreamWAV:
	var duration := 3.0
	var num_samples := int(duration * float(SAMPLE_RATE))
	var bytes := PackedByteArray()
	bytes.resize(num_samples * 2)

	var rng_seed := 135792468
	var lpf := 0.0

	for i in range(num_samples):
		var t := float(i) / float(SAMPLE_RATE)
		rng_seed = (rng_seed * 1103515245 + 12345) & 0x7FFFFFFF
		var white := (float(rng_seed & 0xFFFF) / 32768.0) - 1.0

		lpf = lerpf(lpf, white, 0.035)

		var tone := sin(t * 220.0 * TAU) * 0.08 + sin(t * 330.0 * TAU) * 0.04
		var gust := 0.7 + 0.3 * sin(t * 0.8 * TAU)
		var val := (lpf * 0.6 + tone) * gust
		var sample := clampi(int(val * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, sample)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = bytes
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = num_samples
	return wav

## Short 30ms digital dialogue chirp
func _create_dialogue_chirp_sfx() -> AudioStreamWAV:
	var duration := 0.035
	var num_samples := int(duration * float(SAMPLE_RATE))
	var bytes := PackedByteArray()
	bytes.resize(num_samples * 2)

	for i in range(num_samples):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := float(i) / float(num_samples)
		var freq := 880.0 + 440.0 * progress
		var env := exp(-progress * 6.0)
		var val := sin(t * freq * TAU) * 0.45 * env
		var sample := clampi(int(val * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, sample)

	return _create_wav(bytes)

