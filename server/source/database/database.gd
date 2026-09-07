extends RefCounted
class_name Database


enum Codes {
	OK = 0, ERROR = 1, INTERNAL = 2, PERM = 3, ABORT = 4, BUSY = 5,
	LOCKED = 6, NOMEM = 7, READONLY = 8, INTERRUPT = 9, IOERR = 10,
	CORRUPT = 11, NOTFOUND = 12, FULL = 13, CANTOPEN = 14, PROTOCOL = 15,
	EMPTY = 16, SCHEMA = 17, TOOBIG = 18, CONSTRAINT = 19, MISMATCH = 20,
	MISUSE = 21, NOLFS = 22, AUTH = 23, FORMAT = 24, RANGE = 25,
	NOTADB = 26, NOTICE = 27, WARNING = 28, ROW = 100, DONE = 101,
	ABORT_ROLLBACK = 516, AUTH_USER = 279, BUSY_RECOVERY = 261,
	BUSY_SNAPSHOT = 517, BUSY_TIMEOUT = 773, CANTOPEN_CONVPATH = 1038,
	CANTOPEN_DIRTYWAL = 1294, CANTOPEN_FULLPATH = 782, CANTOPEN_ISDIR = 526,
	CANTOPEN_NOTEMPDIR = 270, CANTOPEN_SYMLINK = 1550, CONSTRAINT_CHECK = 275,
	CONSTRAINT_COMMITHOOK = 531, CONSTRAINT_DATATYPE = 3091,
	CONSTRAINT_FOREIGNKEY = 787, CONSTRAINT_FUNCTION = 1043,
	CONSTRAINT_NOTNULL = 1299, CONSTRAINT_PINNED = 2835,
	CONSTRAINT_PRIMARYKEY = 1555, CONSTRAINT_ROWID = 2579,
	CONSTRAINT_TRIGGER = 1811, CONSTRAINT_UNIQUE = 2067,
	CONSTRAINT_VTAB = 2323, CORRUPT_INDEX = 779, CORRUPT_SEQUENCE = 523,
	CORRUPT_VTAB = 267, ERROR_MISSING_COLLSEQ = 257, ERROR_RETRY = 513,
	ERROR_SNAPSHOT = 769, IOERR_ACCESS = 3338, IOERR_AUTH = 7178,
	IOERR_BEGIN_ATOMIC = 7434, IOERR_BLOCKED = 2826,
	IOERR_CHECKRESERVEDLOCK = 3594, IOERR_CLOSE = 4106,
	IOERR_COMMIT_ATOMIC = 7690, IOERR_CONVPATH = 6666,
	IOERR_CORRUPTFS = 8458, IOERR_DATA = 8202, IOERR_DELETE = 2570,
	IOERR_DELETE_NOENT = 5898, IOERR_DIR_CLOSE = 4362,
	IOERR_DIR_FSYNC = 1290, IOERR_FSTAT = 1802, IOERR_FSYNC = 1034,
	IOERR_GETTEMPPATH = 6410, IOERR_LOCK = 3850, IOERR_MMAP = 6154,
	IOERR_NOMEM = 3082, IOERR_RDLOCK = 2314, IOERR_READ = 266,
	IOERR_ROLLBACK_ATOMIC = 7946, IOERR_SEEK = 5642, IOERR_SHMLOCK = 5130,
	IOERR_SHMMAP = 5386, IOERR_SHMOPEN = 4618, IOERR_SHMSIZE = 4874,
}


var _aslet: Aslet
var _conn: AsletConn


func _init() -> void:
	_aslet = Aslet.new()


func poll(time: int) -> void:
	if _aslet:
		_aslet.poll(time)


func create(path: String, filename: String) -> Error:
	var full_path: String = "%s%s.db" % [path, filename]

	DirAccess.make_dir_recursive_absolute(path)

	var result: Array = _aslet.open(full_path).wait()
	if result.is_empty() || result[0] != OK:
		return FAILED

	_conn = result[1] as AsletConn

	_conn.exec("PRAGMA foreign_keys = ON;", []).wait()
	_conn.exec("PRAGMA journal_mode = WAL;", []).wait()

	return OK


func is_ready() -> bool:
	return _conn != null


func now() -> int:
	return int(Time.get_unix_time_from_system())


func rows(query: String, args: Array = [], ty: GDScript = null) -> Array[Models]:
	var result: Array = await _conn.fetch(query, args).done as Array
	if result[0] != OK:
		return []

	var cols: PackedStringArray = result[2] as PackedStringArray
	var values: Array[Models] = []

	for row: Array in result[1]:
		if ty == null:
			break

		var m: Models = ty.new() as Models
		m.from_row(row, cols)
		values.push_back(m)
	return values


func row(query: String, args: Array = [], ty: GDScript = null) -> Models:
	var result: Array = await _conn.fetch(query, args).done as Array
	if result[0] != OK || (result[1] as Array).size() == 0:
		return null

	if ty == null:
		return null

	var m: Models = ty.new() as Models
	m.from_row(result[1][0] as Array, result[2] as PackedStringArray)
	return m


func scalar(query: String, args: Array = []) -> Variant:
	var result: Array = await _conn.fetch(query, args).done as Array
	if result[0] != OK || (result[1] as Array).size() == 0:
		return null

	return (result[1] as Array)[0][0]


func scalar_or(query: String, args: Array = [], default: Variant = null) -> Variant:
	var value: Variant = await scalar(query, args)
	return default if value == null else value


func exec(query: String, params: Array = []) -> Error:
	var result: Array = await _conn.exec(query, params).done as Array
	if result[0] != OK:
		push_error("[SQLITE] Erro ao executar query: %s" % result[2])
		return result[0] as Error
	return OK
