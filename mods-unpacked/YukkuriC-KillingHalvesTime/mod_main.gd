extends Node

const MOD_DIR := "YukkuriC-KillingHalvesTime"
const LOG_NAME := MOD_DIR + ":Main"

func _init() -> void:
	ModLoaderLog.info("Init", LOG_NAME)

func _ready() -> void:
	if not SignalBus.enemy_died.is_connected(_on_enemy_died):
		SignalBus.enemy_died.connect(_on_enemy_died)

func _on_enemy_died(_enemy: Enemy) -> void:
	# Path A: Halve the cumulative speedrun timer
	if is_instance_valid(G.ui) and is_instance_valid(G.ui.speedrun_timer):
		G.ui.speedrun_timer.time *= 0.5

	# Path C: Halve the elapsed time of the acid circle storm,
	# pushing the circle back to the size it would have at half the elapsed time.
	if is_instance_valid(G.level_generator):
		var acid_circle := G.level_generator.get_node_or_null("acid_circle")
		if is_instance_valid(acid_circle):
			# elapsed = time_limit - remaining; halve elapsed, then remaining = time_limit - elapsed/2
			acid_circle.remaining = (acid_circle.time_limit + acid_circle.remaining) * 0.5
