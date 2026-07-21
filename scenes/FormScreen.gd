extends Control
## Formulário (lead capture). Nome obrigatório, Email e Empresa opcionais.
## "CONTINUAR" só habilita com o nome preenchido.


var _name_field: LineEdit
var _email_field: LineEdit
var _company_field: LineEdit
var _continue_button: Button

func _ready() -> void:
	GameManager.current_state = GameManager.State.FORM
	UIStyle.style_bg(self)

	var outer := VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(outer)
	outer.add_child(UIStyle.make_brand_header())

	var center_wrap := CenterContainer.new()
	center_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(center_wrap)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 70)
	margin.add_theme_constant_override("margin_right", 70)
	margin.custom_minimum_size = Vector2(760, 0)
	center_wrap.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 26)
	margin.add_child(root)

	root.add_child(UIStyle.make_eyebrow("Passo 1 de 2"))
	root.add_child(UIStyle.make_title("Quem vai jogar?", 56))

	root.add_child(_spacer(10))

	root.add_child(_field_label("Nome *"))
	_name_field = UIStyle.make_text_field("Nome")
	_name_field.text_changed.connect(_on_any_text_changed)
	root.add_child(_name_field)

	root.add_child(_field_label("E-mail (opcional)"))
	_email_field = UIStyle.make_text_field("voce@empresa.com")
	root.add_child(_email_field)

	root.add_child(_field_label("Empresa (opcional)"))
	_company_field = UIStyle.make_text_field("Onde você trabalha")
	root.add_child(_company_field)

	root.add_child(_spacer(16))

	_continue_button = UIStyle.make_primary_button("CONTINUAR")
	_continue_button.disabled = true
	_continue_button.pressed.connect(_on_continue_pressed)
	root.add_child(_continue_button)

	var back_button := UIStyle.make_text_button("Voltar ao início")
	back_button.pressed.connect(func(): GameManager.go_home())
	var back_wrap := CenterContainer.new()
	back_wrap.add_child(back_button)
	root.add_child(back_wrap)

func _field_label(text: String) -> Label:
	var l := UIStyle.make_eyebrow(text, UIStyle.TEXT_MUTED)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return l

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

func _on_any_text_changed(_new_text: String) -> void:
	_continue_button.disabled = _name_field.text.strip_edges().is_empty()

func _on_continue_pressed() -> void:
	if _name_field.text.strip_edges().is_empty():
		return
	Audio.play_click()
	GameManager.submit_form(_name_field.text, _email_field.text, _company_field.text)
