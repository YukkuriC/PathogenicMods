# 生成于 GLM-5.1
extends Node

const MOD_DIR := "YukkuriC-SyncUnlocks"
const LOG_NAME := MOD_DIR + ":Main"

func _init() -> void:
	ModLoaderLog.info("Init", LOG_NAME)
	ModLoaderMod.add_hook(_force_brain_gate_open, "res://scn/environ/secret_path/brain_gate.gd", "_on_room_finished")

func _force_brain_gate_open(chain: ModLoaderHookChain) -> void:
	chain.execute_next()
	var gate = chain.reference_object
	if gate.solved:
		return
	gate.restore_open()
