extends Control
## Pontuação + Ranking: mostra o resultado, lê o Top 10 do banco SQL e
## destaca a posição do jogador atual.


func _ready() -> void:
	GameManager.current_state = GameManager.State.SCORE
	UIStyle.style_bg(self)

	var outer := VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(outer)
	outer.add_child(UIStyle.make_brand_header())

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 40)
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	var name_for_message := GameManager.player_name if GameManager.player_name != "" else "Jogador"
	root.add_child(UIStyle.make_eyebrow("Mandou bem, %s!" % name_for_message))

	root.add_child(UIStyle.make_label("Sua pontuação", 30, UIStyle.TEXT_MUTED_LIGHT))

	var score_label := UIStyle.make_title(str(GameManager.score), 110, UIStyle.GREEN)
	root.add_child(score_label)

	root.add_child(_spacer(10))

	var ranking_panel := PanelContainer.new()
	var panel_box := StyleBoxFlat.new()
	panel_box.bg_color = UIStyle.PANEL_COLOR
	panel_box.set_corner_radius_all(22)
	panel_box.content_margin_left = 24
	panel_box.content_margin_right = 24
	panel_box.content_margin_top = 24
	panel_box.content_margin_bottom = 24
	ranking_panel.add_theme_stylebox_override("panel", panel_box)
	ranking_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(ranking_panel)

	var panel_content := VBoxContainer.new()
	panel_content.add_theme_constant_override("separation", 12)
	ranking_panel.add_child(panel_content)

	panel_content.add_child(UIStyle.make_eyebrow("Ranking · Top 10", UIStyle.TEXT_MUTED))

	var list_scroll := ScrollContainer.new()
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_content.add_child(list_scroll)

	var list_box := VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 10)
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.add_child(list_box)

	_populate_ranking(list_box)

	root.add_child(_spacer(6))

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 20)

	var play_again := UIStyle.make_primary_button("JOGAR DE NOVO", 120)
	play_again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play_again.pressed.connect(func(): Audio.play_click(); GameManager.play_again())
	buttons.add_child(play_again)

	var home_button := UIStyle.make_secondary_button("INÍCIO", 120)
	home_button.custom_minimum_size.x = 220
	home_button.pressed.connect(func(): Audio.play_click(); GameManager.go_home())
	buttons.add_child(home_button)

	root.add_child(buttons)

	var stats := UIStyle.make_label(
		"Melhor sequência: %d   •   Reação média: %.2fs" % [GameManager.best_streak, GameManager.get_average_reaction_time()],
		18, UIStyle.TEXT_MUTED
	)
	root.add_child(stats)

func _populate_ranking(container: VBoxContainer) -> void:
	var top: Array = Database.get_top_ranking(10)
	var player_rank := Database.get_rank_for_score(GameManager.score)

	if top.is_empty():
		container.add_child(UIStyle.make_label("Sem partidas registradas ainda.", 22, UIStyle.TEXT_MUTED))
		return

	for i in range(top.size()):
		var row: Dictionary = top[i]
		var pos := i + 1
		var is_player: bool = (row.get("name", "") == GameManager.player_name) and (int(row.get("score", -1)) == GameManager.score) and pos == player_rank
		container.add_child(UIStyle.make_rank_row(pos, str(row.get("name", "—")), int(row.get("score", 0)), is_player))

	if player_rank > top.size():
		container.add_child(UIStyle.make_label("···", 20, UIStyle.TEXT_MUTED))
		var p_name := GameManager.player_name if GameManager.player_name != "" else "Você"
		container.add_child(UIStyle.make_rank_row(player_rank, p_name, GameManager.score, true))

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
