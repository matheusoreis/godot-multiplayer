extends Node
class_name Loop


class Task:
	var timer: Timer
	var callback: Callable
	var interval: float

	func _init(timer: Timer, interval: float, callback: Callable):
		self.timer = timer
		self.interval = interval
		self.callback = callback


var _tasks: Dictionary[StringName, Task] = {}


func add(identifier: StringName, interval: float, callback: Callable) -> void:
	remove(identifier)

	var timer = get_tree().create_timer(interval, false)
	var task = Task.new(timer, interval, callback)

	timer.timeout.connect(_on_timeout.bind(identifier))

	_tasks[identifier] = task


func remove(identifier: StringName) -> void:
	var task = _tasks.get(identifier)
	if not task:
		return

	task.timer.timeout.disconnect_all()
	task.timer.queue_free()
	_tasks.erase(identifier)


func _on_timeout(identifier: StringName) -> void:
	var task = _tasks.get(identifier)
	if not task:
		return

	task.callback.call(task.interval)
	task.timer.start(task.interval)
