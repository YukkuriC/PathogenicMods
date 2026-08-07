# 生成于 GLM-5.1
extends Node

const MOD_DIR := "YukkuriC-SyncUnlocks"
const LOG_NAME := MOD_DIR + ":Main"

func _init() -> void:
	ModLoaderLog.info("Init", LOG_NAME)
	ModLoaderMod.add_hook(_hook_stat_save, "res://scn/metaprogression/stats/stat.gd", "save")

func _hook_stat_save(chain: ModLoaderHookChain) -> void:
	chain.execute_next()
	if not G.should_record_progress():
		return
	var stat := chain.reference_object as Stat
	if not stat:
		return
	var current_best = stat.get_best_value()
	if current_best == null:
		return
	for i in range(G.ParasiteType.MAX):
		if i == G.selected_parasite:
			continue
		var other_best = stat.load_best(i)
		var new_val = _sync_value(stat.aggregation, other_best, current_best)
		if new_val != other_best:
			SaveManager.save_custom("stats%s" % i, stat.get_id(), new_val)

# 按聚合类型将当前职业的 best 同步到其他职业的存档
# MAX/MIN: 取极值; SUM: 取各职业累计的最大值; ANY: 任一为真即为真
func _sync_value(aggregation, other, current):
	if other == null:
		return current
	match aggregation:
		Stat.Aggregation.MAX: return max(other, current)
		Stat.Aggregation.MIN: return min(other, current)
		Stat.Aggregation.SUM: return max(other, current)
		Stat.Aggregation.ANY: return other or current
	return current
