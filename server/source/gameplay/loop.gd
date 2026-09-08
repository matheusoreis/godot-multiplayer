extends Node
class_name Loop


class Task:
	var interval: float
	var callback: Callable

	func _init(interval: float, callback: Callable) -> void:
		self.interval = interval
		self.callback = callback


var _tasks: Dictionary[StringName, Task] = {}


func add(identifier: StringName, interval: float, callback: Callable) -> void:
	remove(identifier)

	var task: Task = Task.new(interval, callback)
	_tasks[identifier] = task

	_schedule(identifier)


func remove(identifier: StringName) -> void:
	_tasks.erase(identifier)


func _schedule(identifier: StringName) -> void:
	var task: Task = _tasks.get(identifier)

	if not task:
		return

	var timer: SceneTreeTimer = get_tree().create_timer(task.interval, false)
	timer.timeout.connect(_on_timeout.bind(identifier))


func _on_timeout(identifier: StringName) -> void:
	var task: Task = _tasks.get(identifier)

	if not task:
		return

	task.callback.call(task.interval)

	_schedule(identifier)
