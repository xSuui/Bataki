class_name UIStyle
extends RefCounted
## Visual language extracted from the real Figma file (Bataki, Branch77).
## Palette, glow, and component styles all live here so re-tuning the look
## never requires touching screen logic.

# ---- Palette (from Figma) ----
const BG_COLOR := Color("0A0A0A")
const PANEL_COLOR := Color("161616")
const INPUT_COLOR := Color("141414")
const BORDER_MUTED := Color("2A2A2D")
const IDLE_BUTTON_COLOR := Color("1C1C1C")

const GREEN_LIGHT := Color("93FC56")
const GREEN := Color("6CE525")
const GREEN_DARK := Color("4BE000")
const GREEN_DEEP := Color("3DB800")      # base do degradê do alvo aceso
const GREEN_PALE := Color("DFFFCB")      # topo (highlight) do alvo aceso
const GREEN_MINT := Color("E9FFD7")      # verde bem claro (badges/realces sutis)
const GREEN_TINT := Color(0.424, 0.898, 0.145, 0.141)  # #6CE52524 (~14% alpha)
const GREEN_GLOW := Color(0.42, 0.898, 0.145, 0.35) # rgba(108,229,37,~) used for bloom/shadow

const TEXT_WHITE := Color("FFFFFF")
const TEXT_OFFWHITE := Color("F5F5F5")
const TEXT_MUTED := Color("858585")
const TEXT_MUTED_DARK := Color("5C5C5C")  # cinza mais escuro (rótulos/placeholders)
const TEXT_MUTED_LIGHT := Color("C0C2C8")
const HAIRLINE := Color(1, 1, 1, 0.024)   # #FFFFFF ~2.4% (linhas/bordas finíssimas)

const ERROR_COLOR := Color("E5453A")
const SUCCESS_COLOR := GREEN

# ---- Fonts ----
## Synthetic bold applied to headline text (titles, eyebrows, buttons) so it
## reads closer to the thick display font from Figma while we don't have the
## real font file installed. Swap this out entirely once you drop a real
## .ttf into res://fonts/ and tell me its name.
static var _bold_font_cache: FontVariation = null
static func _bold_font() -> FontVariation:
	if _bold_font_cache:
		return _bold_font_cache
	var fv := FontVariation.new()
	fv.base_font = ThemeDB.fallback_font
	fv.variation_embolden = 1.4
	_bold_font_cache = fv
	return fv

# ---- Background ----

## Preenche o fundo de uma tela. Se `bg_path` apontar para uma imagem de fundo
## exportada do Figma (só o gradiente/glow, sem textos), ela é usada esticada
## na tela toda. Caso o arquivo não exista (ex.: antes do editor reimportar),
## cai de volta no glow gerado por código — a tela nunca fica sem fundo.
static func style_bg(control: Control, bg_path: String = "res://assets/bg/bg_standard.png") -> void:
	# Base sólida sempre presente (garante #0A0A0A mesmo se a imagem falhar).
	var panel := ColorRect.new()
	panel.color = BG_COLOR
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.add_child(panel)
	control.move_child(panel, 0)

	if bg_path != "" and ResourceLoader.exists(bg_path):
		# Imagem de fundo do Figma cobrindo a tela inteira.
		var bg := TextureRect.new()
		bg.texture = load(bg_path)
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.anchor_right = 1.0
		bg.anchor_bottom = 1.0
		bg.offset_left = 0.0
		bg.offset_right = 0.0
		bg.offset_top = 0.0
		bg.offset_bottom = 0.0
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		control.add_child(bg)
		control.move_child(bg, 1)
		return

	# Fallback: glow radial verde gerado por código, descendo do topo.
	var glow := TextureRect.new()
	glow.texture = _radial_glow_texture()
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.anchor_left = 0.0
	glow.anchor_right = 1.0
	glow.anchor_top = 0.0
	glow.anchor_bottom = 0.0
	glow.offset_left = 0.0
	glow.offset_right = 0.0
	glow.offset_top = 0.0
	glow.offset_bottom = 700.0
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.add_child(glow)
	control.move_child(glow, 1)

static var _glow_tex: GradientTexture2D = null
static func _radial_glow_texture() -> GradientTexture2D:
	if _glow_tex:
		return _glow_tex
	var gradient := Gradient.new()
	gradient.set_color(0, Color(GREEN.r, GREEN.g, GREEN.b, 0.16))
	gradient.set_color(1, Color(GREEN.r, GREEN.g, GREEN.b, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = 512
	tex.height = 512
	_glow_tex = tex
	return tex

# ---- Branding header (BRANCH77 wordmark, pinned top on every screen but Home) ----

static func make_brand_header() -> Control:
	var box := HBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)

	# Vector approximation of the Branch77 mark (two angled parallelogram
	# strokes forming a stylized "arrow up-right"), drawn in code so we don't
	# depend on exporting the layer from the Figma file.
	var mark := BrandMark.new()
	mark.custom_minimum_size = Vector2(54, 46)
	box.add_child(mark)

	var brand := Label.new()
	brand.text = "BRANCH"
	brand.add_theme_color_override("font_color", TEXT_WHITE)
	brand.add_theme_font_size_override("font_size", 36)
	brand.add_theme_font_override("font", _bold_font())
	box.add_child(brand)

	var num := Label.new()
	num.text = "77"
	num.add_theme_color_override("font_color", GREEN)
	num.add_theme_font_size_override("font_size", 36)
	num.add_theme_font_override("font", _bold_font())
	box.add_child(num)

	var header_wrap := MarginContainer.new()
	header_wrap.add_theme_constant_override("margin_top", 44)
	header_wrap.add_theme_constant_override("margin_bottom", 14)
	header_wrap.add_child(box)
	return header_wrap

# ---- Text ----

static func make_title(text: String, size: int = 96, color: Color = TEXT_WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_font_override("font", _bold_font())
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

static func make_label(text: String, size: int = 36, color: Color = TEXT_WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", size)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

## Small tracked-out uppercase label, like "PASSO 1 DE 2" / "COMO JOGAR".
static func make_eyebrow(text: String, color: Color = GREEN) -> Label:
	var l := Label.new()
	l.text = _add_letter_spacing(text.to_upper())
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_font_override("font", _bold_font())
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

static func _add_letter_spacing(text: String) -> String:
	var out := ""
	for i in range(text.length()):
		out += text[i]
		if i < text.length() - 1:
			out += " "
	return out

# ---- Buttons ----

static func make_primary_button(text: String, min_h: int = 140) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, min_h)
	b.add_theme_font_size_override("font_size", 46)
	b.add_theme_font_override("font", _bold_font())
	b.add_theme_color_override("font_color", Color.BLACK)
	b.add_theme_color_override("font_hover_color", Color.BLACK)
	b.add_theme_color_override("font_pressed_color", Color.BLACK)
	b.add_theme_color_override("font_disabled_color", Color(0, 0, 0, 0.35))

	# Fundo em pílula: StyleBoxFlat dá cantos arredondados + a sombra/glow
	# verde do Figma de forma nítida em qualquer tamanho. Usa #6CE525, a cor
	# central do degradê #4BE000→#93FC56 do Figma (praticamente idêntica na
	# pílula); hover clareia pra #93FC56, pressed escurece pra #4BE000.
	var normal := StyleBoxFlat.new()
	normal.bg_color = GREEN
	normal.set_corner_radius_all(int(min_h / 2.0))
	normal.shadow_color = GREEN_GLOW
	normal.shadow_size = 26

	var hover := normal.duplicate()
	hover.bg_color = GREEN_LIGHT

	var pressed := normal.duplicate()
	pressed.bg_color = GREEN_DARK

	var disabled := normal.duplicate()
	disabled.bg_color = GREEN.darkened(0.55)
	disabled.shadow_size = 0

	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("disabled", disabled)
	return b

static func make_secondary_button(text: String, min_h: int = 110) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, min_h)
	b.add_theme_font_size_override("font_size", 34)
	b.add_theme_font_override("font", _bold_font())
	b.add_theme_color_override("font_color", TEXT_WHITE)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	normal.set_corner_radius_all(int(min_h / 2.0))
	normal.border_width_left = 2
	normal.border_width_right = 2
	normal.border_width_top = 2
	normal.border_width_bottom = 2
	normal.border_color = BORDER_MUTED

	var hover := normal.duplicate()
	hover.border_color = TEXT_MUTED

	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	return b

## Plain text "link" button, like "VOLTAR AO INÍCIO" / "SAIR". Visually
## small on purpose, but the tappable area is kept finger-sized (min 64px
## tall) so it's still comfortable to hit on a touchscreen.
static func make_text_button(text: String) -> Button:
	var b := Button.new()
	b.text = _add_letter_spacing(text.to_upper())
	b.custom_minimum_size = Vector2(0, 64)
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", TEXT_MUTED)
	b.add_theme_color_override("font_hover_color", TEXT_MUTED_LIGHT)
	var empty := StyleBoxEmpty.new()
	b.add_theme_stylebox_override("normal", empty)
	b.add_theme_stylebox_override("hover", empty)
	b.add_theme_stylebox_override("pressed", empty)
	b.add_theme_stylebox_override("focus", empty)
	return b

# ---- Grid target button ----

static func make_grid_button() -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(220, 220)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	set_grid_button_idle(b)
	return b

## Lit (green, glowing) grid button — glossy orb from Figma:
## radial-gradient(at 50% 38%, #DFFFCB → #6CE525 → #3DB800).
static func set_grid_button_lit(b: Button, color: Color = GREEN) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(400)
	# Anti-aliasing das bordas arredondadas — sem isso o círculo fica
	# serrilhado no renderer GL Compatibility.
	box.anti_aliasing = true
	box.anti_aliasing_size = 2.0
	box.corner_detail = 16
	box.shadow_color = Color(color.r, color.g, color.b, 0.55)
	box.shadow_size = 40
	b.add_theme_stylebox_override("normal", box)
	b.add_theme_stylebox_override("hover", box.duplicate())
	b.add_theme_stylebox_override("pressed", box.duplicate())
	# Overlay esférico só quando aceso com o verde padrão (não no flash de
	# acerto/erro, que passam cores sólidas próprias).
	if color == GREEN:
		_set_orb_overlay(b, true)
	else:
		_set_orb_overlay(b, false)

static func set_grid_button_idle(b: Button) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = IDLE_BUTTON_COLOR
	box.set_corner_radius_all(400)
	box.anti_aliasing = true
	box.anti_aliasing_size = 2.0
	box.corner_detail = 16
	box.border_width_left = 2
	box.border_width_right = 2
	box.border_width_top = 2
	box.border_width_bottom = 2
	box.border_color = HAIRLINE
	b.add_theme_stylebox_override("normal", box)
	b.add_theme_stylebox_override("hover", box.duplicate())
	b.add_theme_stylebox_override("pressed", box.duplicate())
	_set_orb_overlay(b, false)

## Textura radial do orbe (highlight claro no alto, verde no meio, verde
## escuro na borda). Cacheada.
static var _orb_tex: GradientTexture2D = null
static func _orb_texture() -> GradientTexture2D:
	if _orb_tex:
		return _orb_tex
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.58, 1.0])
	g.colors = PackedColorArray([GREEN_PALE, GREEN, GREEN_DEEP])  # #DFFFCB, #6CE525, #3DB800
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.38)  # highlight deslocado pra cima, como no Figma
	tex.fill_to = Vector2(0.5, 0.38 + 0.7965)  # raio ~79.65%
	tex.width = 256
	tex.height = 256
	_orb_tex = tex
	return tex

## Adiciona/remove o overlay radial circular dentro do botão do grid.
static func _set_orb_overlay(b: Button, on: bool) -> void:
	var existing: TextureRect = b.get_node_or_null("OrbOverlay")
	if on:
		if existing:
			existing.visible = true
			return
		var orb := TextureRect.new()
		orb.name = "OrbOverlay"
		orb.texture = _orb_texture()
		orb.stretch_mode = TextureRect.STRETCH_SCALE
		orb.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		orb.set_anchors_preset(Control.PRESET_FULL_RECT)
		orb.anchor_right = 1.0
		orb.anchor_bottom = 1.0
		orb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		orb.material = _circle_mask_material()
		b.add_child(orb)
		b.move_child(orb, 0)
	elif existing:
		existing.visible = false

## Shader que recorta um TextureRect num círculo perfeito (para o orbe não
## ter cantos quadrados sobre o alvo redondo).
static var _circle_mat: ShaderMaterial = null
static func _circle_mask_material() -> ShaderMaterial:
	if _circle_mat:
		return _circle_mat
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
void fragment() {
	vec2 c = UV - vec2(0.5);
	float d = length(c);
	// Borda anti-serrilhada independente de resolução: a largura da
	// transição acompanha o tamanho real em pixels via fwidth().
	float aa = fwidth(d) * 1.5;
	float alpha = smoothstep(0.5, 0.5 - aa, d);
	COLOR = texture(TEXTURE, UV);
	COLOR.a *= alpha;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	_circle_mat = mat
	return mat

## Kept for backwards compatibility with existing call sites.
static func set_grid_button_color(b: Button, color: Color) -> void:
	if color == IDLE_BUTTON_COLOR:
		set_grid_button_idle(b)
	else:
		set_grid_button_lit(b, color)

# ---- HUD boxes (PONTOS / TEMPO) ----

static func make_hud_box(label_text: String, value_text: String, value_color: Color = TEXT_WHITE) -> PanelContainer:
	var panel := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = PANEL_COLOR
	box.set_corner_radius_all(18)
	box.content_margin_left = 26
	box.content_margin_right = 26
	box.content_margin_top = 16
	box.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", box)
	panel.set_meta("style_box", box)

	var v := VBoxContainer.new()
	v.name = "VBoxContainer"
	v.add_theme_constant_override("separation", 2)
	panel.add_child(v)

	var lbl := make_eyebrow(label_text, TEXT_MUTED)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(lbl)

	var val := Label.new()
	val.name = "Value"
	val.text = value_text
	val.add_theme_color_override("font_color", value_color)
	val.add_theme_font_size_override("font_size", 48)
	val.add_theme_font_override("font", _bold_font())
	v.add_child(val)

	return panel

static func set_hud_box_danger(panel: PanelContainer, danger: bool) -> void:
	var box: StyleBoxFlat = panel.get_meta("style_box")
	box.bg_color = ERROR_COLOR if danger else PANEL_COLOR
	if panel.has_node("VBoxContainer/Value"):
		var val: Label = panel.get_node("VBoxContainer/Value")
		val.add_theme_color_override("font_color", TEXT_WHITE if danger else TEXT_WHITE)

# ---- Ranking rows ----

static func make_rank_row(pos: int, p_name: String, p_score: int, highlight: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = GREEN if highlight else PANEL_COLOR
	box.set_corner_radius_all(16)
	box.content_margin_left = 26
	box.content_margin_right = 26
	box.content_margin_top = 16
	box.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", box)

	var text_color := Color.BLACK if highlight else TEXT_WHITE
	var muted_color := TEXT_MUTED if not highlight else Color(0, 0, 0, 0.6)

	var row := HBoxContainer.new()
	panel.add_child(row)

	var pos_label := Label.new()
	pos_label.text = str(pos)
	pos_label.add_theme_color_override("font_color", muted_color)
	pos_label.add_theme_font_size_override("font_size", 28)
	pos_label.custom_minimum_size = Vector2(60, 0)
	row.add_child(pos_label)

	var name_label := Label.new()
	name_label.text = p_name
	name_label.add_theme_color_override("font_color", text_color)
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	var score_label := Label.new()
	score_label.text = str(p_score)
	score_label.add_theme_color_override("font_color", GREEN if not highlight else Color.BLACK)
	score_label.add_theme_font_size_override("font_size", 28)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(score_label)

	return panel

# ---- Numbered rule row (the "1 / 2 / 3" cards on the Regras screen) ----

static func make_rule_row(number: int, text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = PANEL_COLOR
	box.set_corner_radius_all(24)
	box.content_margin_left = 34
	box.content_margin_right = 34
	box.content_margin_top = 32
	box.content_margin_bottom = 32
	panel.add_theme_stylebox_override("panel", box)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 30)
	panel.add_child(row)

	var badge := PanelContainer.new()
	var badge_box := StyleBoxFlat.new()
	badge_box.bg_color = GREEN_TINT  # #6CE52524 exato do Figma
	badge_box.set_corner_radius_all(999)
	badge_box.content_margin_left = 26
	badge_box.content_margin_right = 26
	badge_box.content_margin_top = 16
	badge_box.content_margin_bottom = 16
	badge.add_theme_stylebox_override("panel", badge_box)
	badge.custom_minimum_size = Vector2(80, 80)
	var num_label := Label.new()
	num_label.text = str(number)
	num_label.add_theme_color_override("font_color", GREEN)
	num_label.add_theme_font_size_override("font_size", 38)
	num_label.add_theme_font_override("font", _bold_font())
	num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(num_label)
	row.add_child(badge)

	var body := make_label(text, 33, TEXT_OFFWHITE)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(body)

	return panel

# ---- Combo badge (x2, x3...) ----

static func make_combo_badge(multiplier: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = GREEN
	box.set_corner_radius_all(999)
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", box)
	var l := Label.new()
	l.text = "x%d" % multiplier
	l.add_theme_color_override("font_color", Color.BLACK)
	l.add_theme_font_size_override("font_size", 26)
	panel.add_child(l)
	return panel

# ---- Inputs ----

static func make_text_field(placeholder: String) -> LineEdit:
	var le := LineEdit.new()
	le.placeholder_text = placeholder
	le.custom_minimum_size = Vector2(0, 100)
	le.add_theme_font_size_override("font_size", 34)
	le.add_theme_color_override("font_color", TEXT_WHITE)
	le.add_theme_color_override("font_placeholder_color", TEXT_MUTED)

	var normal := StyleBoxFlat.new()
	normal.bg_color = INPUT_COLOR
	normal.set_corner_radius_all(16)
	normal.content_margin_left = 24
	normal.content_margin_right = 24
	normal.border_width_left = 2
	normal.border_width_right = 2
	normal.border_width_top = 2
	normal.border_width_bottom = 2
	normal.border_color = BORDER_MUTED

	var focus := normal.duplicate()
	focus.border_color = GREEN
	focus.shadow_color = GREEN_GLOW
	focus.shadow_size = 12

	le.add_theme_stylebox_override("normal", normal)
	le.add_theme_stylebox_override("focus", focus)
	return le

# ---- Branch77 vector mark ----

## Small self-drawn logo mark so the header shows a real graphic instead of a
## text glyph. It's a stylized "77 / arrow" built from two angled strokes in
## the brand green. Purely cosmetic; swap for a real SVG/PNG asset later by
## replacing make_brand_header()'s mark node.
class BrandMark extends Control:
	const G := Color("6CE525")
	const G_LIGHT := Color("93FC56")

	func _ready() -> void:
		# Redraw if the box is ever resized.
		resized.connect(queue_redraw)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		# Two slanted parallelogram bars going up-to-the-right, the taller/
		# brighter one in front — reads as the Branch77 angular mark.
		var thick := w * 0.26
		# Back bar (dimmer, lower)
		_slanted_bar(Vector2(w * 0.06, h * 0.94), Vector2(w * 0.58, h * 0.30), thick, G.darkened(0.15))
		# Front bar (brighter, higher)
		_slanted_bar(Vector2(w * 0.40, h * 0.94), Vector2(w * 0.94, h * 0.06), thick, G_LIGHT)

	## Draws a thick line from a to b as a filled quad (so it has real width).
	func _slanted_bar(a: Vector2, b: Vector2, thickness: float, color: Color) -> void:
		var dir := (b - a).normalized()
		var normal := Vector2(-dir.y, dir.x) * (thickness * 0.5)
		var quad := PackedVector2Array([
			a + normal, b + normal, b - normal, a - normal
		])
		draw_colored_polygon(quad, color)
