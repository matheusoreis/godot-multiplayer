extends Entity
class_name Character


var account_id: int

var access_at: int
var created_at: int
var updated_at: int


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
