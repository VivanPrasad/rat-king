extends Control

const INTRO := [
	"This castle is asleep, but my night has just begun...",
	"After years and years, my rat army has been formed.",
	"I must raid the treasuries of five kingdoms.",
	"Bring them back to me with all the gold."
]
var tween: Tween
var line: int = -1
@onready var text: Label = $TextureRect/Label
@onready var label: Label =  $TextureRect/Label2

const GAME = preload("uid://q4j5knjnfbxn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	line = 0
	speak()
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func speak() -> void:
	if line > len(INTRO) - 1: 
		line = -1
		get_tree().change_scene_to_packed(GAME)
	text.visible_ratio = 0.0
	text.text = INTRO[line]
	tween = create_tween()
	tween.tween_property(text,^"visible_ratio",1.0,0.8)

func _process(_delta: float) -> void:
	label.visible = bool(text.visible_ratio == 1.0)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT and event.is_released() \
			and line != -1:
		if tween and tween.is_running():
			text.visible_ratio = 1.0
			tween.kill()
		else:
			line += 1
			speak()
