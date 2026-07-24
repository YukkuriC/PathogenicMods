extends Node

const MOD_DIR := "YukkuriC-ChooseAll"
const LOG_NAME := MOD_DIR + ":Main"

func _init() -> void:
	ModLoaderLog.info("Init", LOG_NAME)

	ModLoaderMod.add_hook(forceRewardChooseMulti, "res://scn/environ/pickups/bodypart_reward.gd", "_player_entered")

func forceRewardChooseMulti(chain: ModLoaderHookChain) -> void:
	var part = chain.reference_object as BodypartReward
	part.choose_one = false
	return chain.execute_next()
