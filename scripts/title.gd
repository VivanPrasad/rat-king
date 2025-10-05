extends Control

@onready var buttons: VBoxContainer = $Buttons
const GAME = preload("uid://q4j5knjnfbxn")
const TUTORIAL = preload("uid://doirtr655e1no")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect_buttons()

func connect_buttons() -> void:
	for child in buttons.get_children():
		child.mouse_entered.connect(_on_button_hovered.bind(child))
		child.mouse_exited.connect(_on_button_exited.bind(child))
		child.pressed.connect(_on_button_pressed.bind(child))

func _on_button_hovered(button: TextureButton) -> void:
	create_tween().tween_property(button,"modulate", Color(1.3, 1.3, 1.3, 1.0), 0.1)
func _on_button_exited(button: TextureButton) -> void:
	create_tween().tween_property(button,"modulate", Color.WHITE , 0.1)
	
func _on_button_pressed(button: TextureButton) -> void:
	match button.name:
		&"Play":
			get_tree().change_scene_to_packed(TUTORIAL)
		&"Quit":
			get_tree().quit()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
