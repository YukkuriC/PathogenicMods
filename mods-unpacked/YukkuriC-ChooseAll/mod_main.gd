extends Node

const MOD_DIR := "YukkuriC-ChooseAll"
const LOG_NAME := MOD_DIR + ":Main"

const _EditorHooks := preload("res://mods-unpacked/YukkuriC-ChooseAll/hooks/editor.gd")
var _eh: RefCounted

func _init() -> void:
	ModLoaderLog.info("Init", LOG_NAME)

	# Bodypart reward: allow picking all items in choose_one groups
	ModLoaderMod.add_hook(forceRewardChooseMulti, "res://scn/environ/pickups/bodypart_reward.gd", "_player_entered")

	# Level-up mutations: allow selecting all listed options + skip button
	_eh = _EditorHooks.new()
	_eh.hook_all()

func forceRewardChooseMulti(chain: ModLoaderHookChain) -> void:
	var part = chain.reference_object as BodypartReward
	part.choose_one = false
	return chain.execute_next()
