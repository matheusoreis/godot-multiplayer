extends Node2D
class_name Entity


var id: int
var identifier: String

var spritesheet: String

var map: int
var cell: Vector2i
var facing: Vector2i


func setup(id: int, identifier: String, spritesheet: String, map: int, cell: Vector2i, facing: Vector2i) -> void:
	self.id = id
	self.identifier = identifier
	self.spritesheet = spritesheet
	self.map = map
	self.cell = cell
	self.facing = facing
