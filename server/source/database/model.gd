extends RefCounted
class_name Models


func from_row(row: Array, cols: PackedStringArray) -> void:
	for i in cols.size():
		set(cols[i], row[i])


func to_array() -> Array:
	return []


class AccountModel extends Models:
	var id: int
	var email: String
	var password: String
	var access_at: int
	var created_at: int
	var updated_at: int

	func to_array() -> Array:
		return [
			self.id,
			self.email,
			self.password,
			self.access_at,
			self.created_at,
			self.updated_at
		]


class CharacterModel extends Models:
	var id: int
	var identifier: String
	var account_id: int
	var spritesheet: String
	var map_id: int
	var cell_x: int
	var cell_y: int
	var facing_x: int
	var facing_y: int
	var access_at: int
	var created_at: int
	var updated_at: int

	func to_array() -> Array:
		return [
			self.id,
			self.identifier,
			self.account_id,
			self.spritesheet,
			self.map_id,
			self.cell_x,
			self.cell_y,
			self.facing_x,
			self.facing_y,
			self.access_at,
			self.created_at,
			self.updated_at
		]


class MapModel extends Models:
	var id: int
	var identifier: String
	var bgm: String
	var bgs: String
	var size_x: int
	var size_y: int
	var created_at: int
	var updated_at: int

	func to_array() -> Array:
		return [
			self.id,
			self.identifier,
			self.bgm,
			self.bgs,
			self.size_x,
			self.size_y,
			self.created_at,
			self.updated_at
		]


class MapCollisionModel extends Models:
	var map_id: int
	var cell_x: int
	var cell_y: int
	var flag: int

	func to_array() -> Array:
		return [
			self.map_id,
			self.cell_x,
			self.cell_y,
			self.flag
		]


class MapWarpModel extends Models:
	var map_id: int
	var cell_x: int
	var cell_y: int
	var to_map_id: int
	var to_cell_x: int
	var to_cell_y: int
	var to_facing_x: int
	var to_facing_y: int

	func to_array() -> Array:
		return [
			self.map_id,
			self.cell_x,
			self.cell_y,
			self.to_map_id,
			self.to_cell_x,
			self.to_cell_y,
			self.to_facing_x,
			self.to_facing_y
		]


class NpcModel extends Models:
	var id: int
	var identifier: String
	var spritesheet: String
	var map_id: int
	var cell_x: int
	var cell_y: int
	var facing_x: int
	var facing_y: int
	var can_walk: int
	var created_at: int
	var updated_at: int

	func to_array() -> Array:
		return [
			self.id,
			self.identifier,
			self.spritesheet,
			self.map_id,
			self.cell_x,
			self.cell_y,
			self.facing_x,
			self.facing_y,
			self.can_walk,
			self.created_at,
			self.updated_at
		]
