class_name Transition extends Control
@onready var label: Label = $ColorRect/Label
signal finished
signal faded
@export_multiline var message: String
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.visible_ratio = 0.0
	label.text = message
	modulate.a = 0.0
	create_tween().tween_property(label,"visible_ratio",1.0,0.8)
	await create_tween().tween_property(self, "modulate:a", 1.0, 0.4).finished
	await get_tree().create_timer(1.6).timeout
	emit_signal("faded")
	if message == "Game Over" or message == "Thanks for playing!": return
	await get_tree().create_timer(1.0).timeout
	await create_tween().tween_property(self, "modulate:a", 0.0, 0.4).finished
	emit_signal("finished")
	queue_free()
