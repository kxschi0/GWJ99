extends Interactable

func _on_interaction() -> void:
	SignalBus.pills_collected.emit()
	call_deferred("queue_free")
