@tool
extends SceneTree

func _init() -> void:
	print("Testing audio generation...")
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	var samples: int = int(22050 * 0.2)
	var byte_array := PackedByteArray()
	byte_array.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / 22050.0
		var val := sin(t * 880.0 * TAU) * (1.0 - float(i) / float(samples))
		var s := clampi(int(val * 32767.0), -32768, 32767)
		byte_array.encode_s16(i * 2, s)
	wav.data = byte_array
	print("Generated WAV length: ", wav.get_length())
	assert(wav.get_length() > 0.19)
	print("Audio test passed!")
	quit(0)
