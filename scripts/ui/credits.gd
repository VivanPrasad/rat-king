extends Control


func _ready() -> void:
	modulate.a = 0.0
	await create_tween().tween_property(self, "modulate:a", 1.0, 0.4).finished
	await get_tree().create_timer(3.0).timeout
	await get_tree().create_timer(4.0).timeout
	await create_tween().tween_property(self, "modulate:a", 0.0, 0.4).finished
	get_tree().change_scene_to_file("res://scenes/title.tscn")
