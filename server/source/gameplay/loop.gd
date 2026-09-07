extends Node
class_name Loop


class LoopTask extends RefCounted:
	var identifier: StringName
	var interval: float
	var callback: Callable
	var accumulator: float = 0.0

	func _init(identifier: StringName, interval: float, callback: Callable) -> void:
		self.identifier = identifier
		self.interval = interval
		self.callback = callback


var _tasks: Dictionary[StringName, LoopTask] = {}


func add(identifier: StringName, interval: float, callback: Callable) -> void:
	_tasks[identifier] = LoopTask.new(identifier, interval, callback)


func remove(identifier: StringName) -> void:
	_tasks.erase(identifier)


func has(identifier: StringName) -> bool:
	return _tasks.has(identifier)


func set_interval(identifier: StringName, interval: float) -> void:
	var task: LoopTask = _tasks.get(identifier)

	if task:
		task.interval = interval


func tick(delta: float) -> void:
	for task: LoopTask in _tasks.values():
		task.accumulator += delta

		if task.accumulator >= task.interval:
			var elapsed: float = task.accumulator
			task.accumulator = 0.0
			task.callback.call(elapsed)
