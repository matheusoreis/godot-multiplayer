extends Node
class_name Queue


var _capacity: int
var _head: int = 0
var _count: int = 0

var _buffer: Array


func _init(capacity: int) -> void:
	_capacity = capacity
	_buffer = []
	_buffer.resize(capacity)

func size() -> int:
	return _count


func is_empty() -> bool:
	return _count == 0


func is_full() -> bool:
	return _count == _capacity


func enqueue(value: Variant) -> bool:
	if _count == _capacity:
		return false
	var tail: int = (_head + _count) % _capacity
	_buffer[tail] = value
	_count += 1
	return true


func dequeue() -> Variant:
	if _count == 0:
		return null
	var value: Variant = _buffer[_head]
	_buffer[_head] = null
	_head = (_head + 1) % _capacity
	_count -= 1
	return value


func peek() -> Variant:
	if _count == 0:
		return null
	return _buffer[_head]


func at(idx: int) -> Variant:
	if idx < 0 or idx >= _count:
		return null
	return _buffer[(_head + idx) % _capacity]


func clear() -> void:
	for i: int in _count:
		_buffer[(_head + i) % _capacity] = null
	_head = 0
	_count = 0


func to_array() -> Array:
	var result: Array = []
	result.resize(_count)
	for i: int in _count:
		result[i] = _buffer[(_head + i) % _capacity]
	return result
