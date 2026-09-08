extends Node2D
class_name Scene


signal network_ready(network: Network.Client)


var _network: Network.Client

@export_category("Controls")
@export var _interfaces: Dictionary[StringName, Control]


func _setup(network: Network.Client) -> void:
	_network = network
	network_ready.emit(network)


func get_interface(identifier: StringName) -> Control:
	return _interfaces.get(identifier, null)


func toggle_interface(identifier: StringName) -> void:
	var interface: Control = get_interface(identifier)
	if interface == null:
		return

	if interface.visible:
		interface.visible = false
		return

	_release_interface_focus()
	interface.visible = true


func show_interface(identifier: StringName) -> void:
	var interface: Control = get_interface(identifier)
	if interface == null:
		return

	_release_interface_focus()
	interface.visible = true


func hide_interface(identifier: StringName) -> void:
	var interface: Control = get_interface(identifier)
	if interface == null:
		return

	interface.visible = false


func _release_interface_focus() -> void:
	get_viewport().gui_release_focus()
