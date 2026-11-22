extends Interactable

var collected: bool = false

func _on_interaction() -> void:
	if not collected:
		collected = true
		SignalBus.key_collected.emit()
		queue_free()
