extends Node
## Database
## --------
## Every SQL statement in the whole project lives in this one file.
## Uses the "godot-sqlite" GDExtension addon (2shady4u/godot-sqlite), which
## must be installed via AssetLib inside the Godot editor (see README).
## The addon exposes a global `SQLite` class once installed & enabled.

const DB_PATH := "user://bataki.db" # user:// = safe, writable, per-machine folder
# On Windows this resolves to %APPDATA%/Godot/app_userdata/Bataki/bataki.db

var _db # instance of SQLite, created lazily so the game still boots even if
		# the addon isn't installed yet (it will just log a clear error).
var _ready_ok := false

func _ready() -> void:
	# The addon registers SQLite as a regular engine class once installed +
	# enabled in Project Settings > Plugins. If it's missing, fail loudly
	# instead of crashing, so the rest of the app still boots for review.
	if not ClassDB.class_exists("SQLite"):
		push_error("[Database] Addon 'godot-sqlite' não encontrado/ativado. Instale via AssetLib (veja README) antes de rodar.")
		return
	_open()

func _open() -> void:
	_db = SQLite.new()
	_db.path = DB_PATH
	var opened: bool = _db.open_db()
	if not opened:
		push_error("[Database] Falha ao abrir o banco em %s" % DB_PATH)
		return
	_ready_ok = true
	_create_tables()

func _create_tables() -> void:
	_db.query("""
		CREATE TABLE IF NOT EXISTS matches (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			name TEXT NOT NULL,
			email TEXT,
			company TEXT,
			score INTEGER NOT NULL,
			played_at TEXT NOT NULL
		);
	""")

## Persists one finished match. Called once, right when the round ends.
func save_match(p_name: String, p_email: String, p_company: String, p_score: int) -> void:
	if not _ready_ok:
		push_warning("[Database] Banco indisponível, partida não foi salva.")
		return
	var timestamp := Time.get_datetime_string_from_system(false, true) # UTC, "YYYY-MM-DD HH:MM:SS"
	var row := {
		"name": p_name if p_name != "" else "Jogador",
		"email": p_email,
		"company": p_company,
		"score": p_score,
		"played_at": timestamp,
	}
	var ok: bool = _db.insert_row("matches", row)
	if not ok:
		push_error("[Database] Erro ao inserir partida: %s" % _db.error_message)

## Top N scores, descending. Used by the ScoreScreen ranking list.
func get_top_ranking(p_limit: int = 10) -> Array:
	if not _ready_ok:
		return []
	_db.query("SELECT name, score, played_at FROM matches ORDER BY score DESC, played_at ASC LIMIT %d;" % p_limit)
	return _db.query_result.duplicate(true)

## Player's rank position (1-based) among ALL matches ever played, used to
## highlight "you are #N" even when the player didn't make the visible top 10.
func get_rank_for_score(p_score: int) -> int:
	if not _ready_ok:
		return 0
	_db.query("SELECT COUNT(*) as better FROM matches WHERE score > %d;" % p_score)
	var res: Array = _db.query_result
	if res.is_empty():
		return 1
	return int(res[0]["better"]) + 1

## Optional stat used on the score screen / for the "diferenciais" bonus.
func get_best_streak_overall() -> int:
	# best_streak isn't persisted per row in this minimal schema (only final
	# score is required by the brief); kept here as an extension point if you
	# add a `best_streak` column later.
	return 0
