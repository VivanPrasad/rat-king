extends Node2D

@onready var camera: Camera2D = $Camera2D
@onready var background: TextureRect = $Background/TextureRect

const CAMERA_SCROLL_STR := 0.005

func _ready() -> void:
	pass
	
func _process(_delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	var screen_center = get_viewport().get_visible_rect().size / 2.0
	var offset = screen_center + (mouse_pos * CAMERA_SCROLL_STR)
	background.position = -(mouse_pos * CAMERA_SCROLL_STR) / 2.0
	camera.offset = offset
