extends Control
class_name ConfirmationUi


signal confirmed()
signal canceled()


func setup(message: String) -> void:
	%Message.text = message


func _on_confirm_pressed() -> void:
	confirmed.emit()


func _on_cancel_pressed() -> void:
	canceled.emit()
