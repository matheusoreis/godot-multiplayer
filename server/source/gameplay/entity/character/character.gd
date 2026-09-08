extends Entity
class_name Character


var account_id: int

var access_at: int
var created_at: int
var updated_at: int

var _next_move_at: int = 0


func _init(
	id: int,
	identifier: String,
	spritesheet: String,
	map: int,
	cell: Vector2i,
	facing: Vector2i,
	account_id: int,
	access_at: int,
	created_at: int,
	updated_at: int
) -> void:
	super(id, identifier, spritesheet, map, cell, facing)

	self.account_id = account_id

	self.access_at = access_at
	self.created_at = created_at
	self.updated_at = updated_at


func move(direction: Vector2i) -> void:
	facing = direction
	cell += direction


func warp(map: int, cell: Vector2i, facing: Vector2i) -> void:
	self.map = map
	self.cell = cell
	self.facing = facing


func can_move_now() -> bool:
	return Time.get_ticks_msec() >= _next_move_at


func consume_move(interval_ms: int) -> void:
	_next_move_at = Time.get_ticks_msec() + interval_ms
