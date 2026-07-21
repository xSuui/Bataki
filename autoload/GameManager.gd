extends Node
## GameManager
## -----------
## Central authority for game STATE and RULES. Contains zero UI code on purpose:
## every screen script (Home.gd, FormScreen.gd, etc.) only ever *reads* from this
## singleton or calls its methods — it never reaches into UI nodes from here.
## This is the "lógica de jogo separada da lógica de interface" split asked for
## in the test brief.

enum State { HOME, FORM, RULES, GAME, SCORE }

signal score_changed(new_score: int, streak: int, multiplier: int)
signal combo_triggered(multiplier: int)
signal round_time_changed(seconds_left: float)
signal round_finished

# ---- session / lead data (captured on the Formulário screen) ----
var player_name: String = ""
var player_email: String = ""
var player_company: String = ""

# ---- round data ----
var current_state: int = State.HOME
var score: int = 0
var streak: int = 0
var best_streak: int = 0
var multiplier: int = 1
var hits: int = 0
var misses: int = 0
var reaction_times: Array = [] # seconds, for the optional "avg reaction time" stat

var active_index: int = -1 # which of the 9 grid buttons is currently lit
var last_target_change_msec: int = 0

const GRID_SIZE: int = 9
const GAME_DURATION: float = 30.0
const IDLE_TIMEOUT: float = 20.0
const POINTS_PER_HIT: int = 10
const STREAK_BONUS_EVERY: int = 5

var round_time_left: float = GAME_DURATION
var _round_running: bool = false

var _idle_timer: Timer
var _round_timer: Timer

func _ready() -> void:
	# Global idle watchdog: lives for the whole app lifetime, independent of
	# whichever scene is currently loaded.
	_idle_timer = Timer.new()
	_idle_timer.wait_time = IDLE_TIMEOUT
	_idle_timer.one_shot = true
	add_child(_idle_timer)
	_idle_timer.timeout.connect(_on_idle_timeout)
	_idle_timer.start()

	# Round countdown (30s), only ticking while a match is in progress.
	_round_timer = Timer.new()
	_round_timer.wait_time = 1.0
	_round_timer.one_shot = false
	add_child(_round_timer)
	_round_timer.timeout.connect(_on_round_tick)

func _input(event: InputEvent) -> void:
	# Any touch, click or key press anywhere resets the idle watchdog.
	if event is InputEventScreenTouch or event is InputEventMouseButton or event is InputEventKey or event is InputEventScreenDrag:
		register_activity()

func register_activity() -> void:
	if current_state != State.HOME:
		_idle_timer.start(IDLE_TIMEOUT)

func _on_idle_timeout() -> void:
	if current_state != State.HOME:
		go_home()

# ---------------- Navigation / state transitions ----------------

func go_home() -> void:
	_round_running = false
	_round_timer.stop()
	reset_session()
	current_state = State.HOME
	_change_scene("res://scenes/Home.tscn")

func start_form() -> void:
	current_state = State.FORM
	_idle_timer.start(IDLE_TIMEOUT)
	_change_scene("res://scenes/FormScreen.tscn")

func submit_form(p_name: String, p_email: String, p_company: String) -> void:
	player_name = p_name.strip_edges()
	player_email = p_email.strip_edges()
	player_company = p_company.strip_edges()
	current_state = State.RULES
	_change_scene("res://scenes/Rules.tscn")

func start_game() -> void:
	score = 0
	streak = 0
	best_streak = 0
	multiplier = 1
	hits = 0
	misses = 0
	reaction_times.clear()
	active_index = -1
	round_time_left = GAME_DURATION
	current_state = State.GAME
	_change_scene("res://scenes/Game.tscn")

func begin_round_timer() -> void:
	_round_running = true
	_round_timer.start(1.0)

func _on_round_tick() -> void:
	if not _round_running:
		return
	round_time_left = max(0.0, round_time_left - 1.0)
	round_time_changed.emit(round_time_left)
	if round_time_left <= 0.0:
		_round_running = false
		_round_timer.stop()
		round_finished.emit()
		end_game()

func end_game() -> void:
	current_state = State.SCORE
	Database.save_match(player_name, player_email, player_company, score)
	_change_scene("res://scenes/ScoreScreen.tscn")

func play_again() -> void:
	# "JOGAR DE NOVO": keeps it moving fast at the totem — goes straight back
	# into a fresh lead capture instead of the attract screen.
	score = 0
	streak = 0
	multiplier = 1
	start_form()

func reset_session() -> void:
	player_name = ""
	player_email = ""
	player_company = ""
	score = 0
	streak = 0
	multiplier = 1
	best_streak = 0
	hits = 0
	misses = 0
	reaction_times.clear()

func _change_scene(path: String) -> void:
	Transition.change_scene(path)

# ---------------- Grid / scoring logic (pure logic, no nodes) ----------------

func pick_new_target(exclude: int) -> int:
	var idx := exclude
	if GRID_SIZE <= 1:
		active_index = 0
		return 0
	while idx == exclude:
		idx = randi() % GRID_SIZE
	active_index = idx
	last_target_change_msec = Time.get_ticks_msec()
	return idx

## Call when the player touches the currently lit button.
## Returns a dictionary describing what happened, for the UI to react to.
func register_hit() -> Dictionary:
	var reaction_sec := 0.0
	if last_target_change_msec > 0:
		reaction_sec = (Time.get_ticks_msec() - last_target_change_msec) / 1000.0
		reaction_times.append(reaction_sec)

	hits += 1
	score += POINTS_PER_HIT * multiplier
	streak += 1
	best_streak = max(best_streak, streak)

	var combo := false
	if streak % STREAK_BONUS_EVERY == 0:
		multiplier += 1
		combo = true
		combo_triggered.emit(multiplier)

	score_changed.emit(score, streak, multiplier)
	return {"score": score, "streak": streak, "multiplier": multiplier, "combo": combo, "reaction": reaction_sec}

## Call when the player touches a button that is NOT lit (a miss).
## Per the brief: breaks the streak, but does not deduct points.
func register_miss() -> void:
	misses += 1
	streak = 0
	multiplier = 1
	score_changed.emit(score, streak, multiplier)

func get_average_reaction_time() -> float:
	if reaction_times.is_empty():
		return 0.0
	var total := 0.0
	for t in reaction_times:
		total += t
	return total / reaction_times.size()
