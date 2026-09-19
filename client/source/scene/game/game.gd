extends Scene
class_name Game


var current_map: Map
var current_character: Character

var chat_active: bool = false


func _ready() -> void:
	_network.exec(&"map_data")


func _physics_process(_delta: float) -> void:
	_handle_input()


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("export"):
		return

	if current_map == null or current_character == null:
		return

	if not current_character.is_admin():
		return

	var collisions_data: Array = current_map.export_collisions()
	var warps_data: Array = current_map.export_warps()

	_network.exec(&"import_collisions", [collisions_data])
	_network.exec(&"import_warps", [warps_data])


func _handle_input() -> void:
	if not _can_process_input():
		return

	var direction: Vector2i = _get_movement_direction()
	if direction == Vector2i.ZERO:
		return

	_execute_movement(direction)


func _can_process_input() -> bool:
	if current_map == null or current_character == null:
		return false

	if chat_active:
		return false

	if current_character.is_transitioning():
		return false

	if current_character.is_warping():
		return false

	return true


func _get_movement_direction() -> Vector2i:
	if Input.is_action_pressed("move_up"):
		return Vector2i.UP
	elif Input.is_action_pressed("move_down"):
		return Vector2i.DOWN
	elif Input.is_action_pressed("move_left"):
		return Vector2i.LEFT
	elif Input.is_action_pressed("move_right"):
		return Vector2i.RIGHT

	return Vector2i.ZERO


func _execute_movement(direction: Vector2i) -> void:
	var new_cell: Vector2i = current_character.cell + direction

	if not current_map.is_within_bounds(new_cell):
		new_cell = current_map.normalize_cell(new_cell)
		if not current_map.is_within_bounds(new_cell):
			return

	if not current_map.can_pass(current_character.cell, direction):
		return

	current_character.move(direction)
	_network.exec(&"move_character", [direction])
