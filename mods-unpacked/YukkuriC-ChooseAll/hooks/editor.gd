# 生成于 GLM-5.1
extends RefCounted

const _TARGET := "res://scn/ui/editor.gd"

# Multi-select state for level-up mutations
var _taken_indices: Dictionary = {}
var _skip_button: Button = null
var _processing_mutation := false
var _editor_ref: Editor = null


func hook_all() -> void:
	ModLoaderMod.add_hook(hook_level_up, _TARGET, "level_up")
	ModLoaderMod.add_hook(hook_on_mutation_pressed, _TARGET, "_on_mutation_pressed")
	ModLoaderMod.add_hook(hook_generate_mutations, _TARGET, "generate_mutations")


func hook_level_up(chain: ModLoaderHookChain) -> void:
	var editor = chain.reference_object as Editor
	_editor_ref = editor
	_ensure_skip_button(editor)

	var was_choosing = editor.is_choosing_mutation()

	chain.execute_next()

	# Only initialize multi-select for a fresh level-up (not a queued one
	# that just incremented pending_level_ups)
	if not was_choosing and is_instance_valid(editor) and editor.is_choosing_mutation():
		_taken_indices.clear()
		_processing_mutation = false

		var is_evo_level := false
		if is_instance_valid(G.player):
			is_evo_level = G.player.get_evolution_levels().has(G.player.level)

		_skip_button.visible = not is_evo_level


func hook_on_mutation_pressed(chain: ModLoaderHookChain, index: int) -> void:
	var editor = chain.reference_object as Editor
	_editor_ref = editor

	# Same guards as vanilla
	if editor.state != G.EditorState.ACTIVE:
		return
	if index >= editor.mutations.size() or editor.mutations[index] == null:
		return
	if editor.mutations[index] is Evolution and editor.active_bodypart != null:
		return

	# Evolution slot: use vanilla behavior (pending/confirm flow)
	if editor._is_evolution_slot_active():
		chain.execute_next([index])
		return

	# --- Plain mutation multi-select path ---
	if _taken_indices.has(index):
		return
	if _processing_mutation:
		return

	# Revert any pending selection (safety; plain mutations normally have
	# pending_mutation_index == -1)
	if editor.pending_mutation_index >= 0:
		editor._revert_pending_selection()

	# Mark card as taken
	_taken_indices[index] = true
	var mb: BaseButton = editor.mutation_buttons[index]
	mb.disabled = true
	mb.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Pause float tween and reset position
	if index < editor._mutation_float_tweens.size():
		var t: Tween = editor._mutation_float_tweens[index]
		if t and t.is_valid():
			t.pause()
	mb.position.y = 0.0
	mb.modulate = Color(0.35, 0.35, 0.35, 0.6)
	mb.scale = Vector2.ONE * 0.85

	# Apply mutation asynchronously (detached coroutine — the hook returns
	# immediately so the ModLoader wrapper can complete)
	_processing_mutation = true
	_apply_mutation_async(editor, index)


func hook_generate_mutations(chain: ModLoaderHookChain, parent_seed: int, exclude: Array = []) -> void:
	# Reset tracking when mutations are regenerated (reroll, or new level-up)
	_taken_indices.clear()
	_processing_mutation = false

	await chain.execute_next_async([parent_seed, exclude])

	var editor = chain.reference_object as Editor
	if not is_instance_valid(editor):
		return

	# Reset card visuals in case this is a reroll during multi-select
	for i in range(editor.mutation_buttons.size()):
		var mb: BaseButton = editor.mutation_buttons[i]
		mb.disabled = false
		mb.modulate = Color.WHITE
		mb.scale = Vector2.ONE
		mb.position.y = 0.0
		mb.mouse_filter = Control.MOUSE_FILTER_STOP
		if i < editor._mutation_float_tweens.size():
			var t: Tween = editor._mutation_float_tweens[i]
			if t and t.is_valid():
				t.play()

	# Update skip button visibility
	if is_instance_valid(_skip_button):
		var is_evo_level := false
		if is_instance_valid(G.player):
			is_evo_level = G.player.get_evolution_levels().has(G.player.level)
		_skip_button.visible = not is_evo_level and editor.is_choosing_mutation()


func _apply_mutation_async(editor: Editor, index: int) -> void:
	var mutation = editor.mutations[index]

	# Hide tooltip and reset gene preview
	var mut_tooltip = editor.get_node_or_null("%MutationTooltip")
	if mut_tooltip:
		mut_tooltip.visible = false
		mut_tooltip.item = null

	G.dna_mesh.preview_gene(editor.empty_mutation)
	if is_instance_valid(G.player):
		G.player.set_boost_highlights(null)

	# Apply the mutation
	var picked: Mutation = mutation.duplicate_mutation()
	picked.cancellable = true
	if await G.player.add_mutation(picked, true) == false:
		# Placement cancelled — revert this card's taken state
		_taken_indices.erase(index)
		if is_instance_valid(editor):
			var mb: BaseButton = editor.mutation_buttons[index]
			mb.disabled = false
			mb.mouse_filter = Control.MOUSE_FILTER_STOP
			mb.modulate = Color.WHITE
			mb.scale = Vector2.ONE
			if index < editor._mutation_float_tweens.size():
				var t: Tween = editor._mutation_float_tweens[index]
				if t and t.is_valid():
					t.play()
		_processing_mutation = false
		return

	SignalBus.mutation_chosen.emit()
	AudioManager.upgrade.play()
	G.ui.dna_bar.mesh._update_multimesh()
	_processing_mutation = false

	# Check if all available cards are taken
	var all_taken := true
	for i in range(editor.mutations.size()):
		if editor.mutations[i] != null and not _taken_indices.has(i):
			all_taken = false
			break

	if all_taken:
		_finish_multi_select(editor)


func _on_skip_pressed() -> void:
	if not is_instance_valid(_editor_ref) or _processing_mutation:
		return
	_finish_multi_select(_editor_ref)


func _finish_multi_select(editor: Editor) -> void:
	# Hide mutation container and skip button
	editor.get_node("MutationContainer").visible = false
	if is_instance_valid(_skip_button):
		_skip_button.visible = false

	# Reset card visuals for the next level-up
	for i in range(editor.mutation_buttons.size()):
		var mb: BaseButton = editor.mutation_buttons[i]
		mb.disabled = false
		mb.mouse_filter = Control.MOUSE_FILTER_STOP
		mb.modulate = Color.WHITE
		mb.scale = Vector2.ONE
		mb.position.y = 0.0
		if i < editor._mutation_float_tweens.size():
			var t: Tween = editor._mutation_float_tweens[i]
			if t and t.is_valid():
				t.play()

	# Reset label and confirm button
	var label = editor.get_node_or_null("%MutationLabel")
	if label:
		label.visible = true
	var confirm = editor.get_node_or_null("%ConfirmButton")
	if confirm:
		confirm.visible = false

	# Reset mutation preview
	G.dna_mesh.preview_gene(editor.empty_mutation)
	if is_instance_valid(G.player):
		G.player.set_boost_highlights(null)

	# Clear tracking
	_taken_indices.clear()
	_processing_mutation = false

	# Process pending level-ups or close editor (mirrors vanilla
	# _commit_plain_mutation tail)
	if editor.pending_level_ups > 0:
		editor.pending_level_ups -= 1
		editor.level_up()
	elif not editor.active_bodypart:
		editor.animate_close()


func _ensure_skip_button(editor: Editor) -> void:
	if is_instance_valid(_skip_button):
		return

	var vbox := editor.get_node("MutationContainer/MutationPanel/MarginContainer/VBoxContainer")

	_skip_button = Button.new()
	_skip_button.name = "ChooseAllSkipButton"
	_skip_button.text = "Skip"
	_skip_button.visible = false
	_skip_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_skip_button.theme_type_variation = &"FullButton"

	# Add ButtonSfx child for audio feedback
	var sfx_scene = load("res://scn/ui/button_sfx.tscn")
	if sfx_scene:
		_skip_button.add_child(sfx_scene.instantiate())

	vbox.add_child(_skip_button)
	_skip_button.pressed.connect(_on_skip_pressed)
