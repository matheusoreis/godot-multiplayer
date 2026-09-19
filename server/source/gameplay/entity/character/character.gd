extends Entity
class_name Character


var account_id: int

var role: int

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
	role: int,
	access_at: int,
	created_at: int,
	updated_at: int
) -> void:
	super(id, identifier, spritesheet, map, cell, facing)

	self.account_id = account_id
	self.role = role

	self.access_at = access_at
	self.created_at = created_at
	self.updated_at = updated_at


func is_admin() -> bool:
	return role >= Constants.ROLE_ADMIN


func is_moderator() -> bool:
	return role >= Constants.ROLE_MODERATOR


func move(direction: Vector2i) -> void:
	facing = direction
	cell += direction


func warp(map: int, cell: Vector2i, facing: Vector2i) -> void:
	self.map = map
	self.cell = cell
	self.facing = facing
