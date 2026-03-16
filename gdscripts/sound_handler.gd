extends Node

var bgm_player: AudioStreamPlayer
var footstep_player: AudioStreamPlayer
var jump_player: AudioStreamPlayer

var harvestboi: AudioStreamPlayer
var plantboi: AudioStreamPlayer

var footstep_sounds: Array[AudioStream] = []
var current_footstep_index: int = 0

func _ready() -> void:
	# 1. Background Music (Forced Code Loop)
	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)
	var music_stream = preload("res://sounds/music.mp3")
	if music_stream is AudioStreamMP3:
		music_stream.loop = true # This forces the mp3 to loop infinitely!
	bgm_player.stream = music_stream
	bgm_player.volume_db = -42.0 # Keep it quiet
	bgm_player.play()
	
	# 2. Footsteps
	footstep_player = AudioStreamPlayer.new()
	footstep_player.volume_db = -26.0
	add_child(footstep_player)
	for i in range(1, 7):
		var sound_path := "res://sounds/footstep_%d.wav" % i
		footstep_sounds.append(load(sound_path))
		
	# 3. Jump Sound
	jump_player = AudioStreamPlayer.new()
	add_child(jump_player)
	jump_player.volume_db = -6.0
	jump_player.stream = preload("res://sounds/jump.wav") 
	
	# 4. Harvest
	harvestboi = AudioStreamPlayer.new()
	add_child(harvestboi)
	harvestboi.volume_db = -6.0
	harvestboi.stream = preload("res://sounds/harvest.wav") 
	
	# 5. Plant
	plantboi = AudioStreamPlayer.new()
	add_child(plantboi)
	plantboi.volume_db = -6.0
	plantboi.stream = preload("res://sounds/plant.wav")

func play_footstep() -> void:
	footstep_player.stream = footstep_sounds[current_footstep_index]
	footstep_player.play()
	current_footstep_index = (current_footstep_index + 1) % footstep_sounds.size()

func play_jump() -> void:
	jump_player.play()
	

func play_harvest():
	harvestboi.play()
	
	
func play_plant():
	plantboi.play()
