extends Control

@onready var buttons: VBoxContainer = $Buttons
const GAME = preload("uid://q4j5knjnfbxn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect_buttons()

func connect_buttons() -> void:
	for child in buttons.get_children():
		child.pressed.connect(_on_button_pressed.bind(child))

func _on_button_pressed(button: TextureButton) -> void:
	match button.name:
		&"Play":
			get_tree().change_scene_to_packed(GAME)
		&"Quit":
			get_tree().quit()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
