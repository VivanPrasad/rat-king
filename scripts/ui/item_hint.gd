class_name ItemHint extends Area2D

@onready var sprite: Sprite2D = $Sprite2D

const TILES = preload("uid://drrjqkhudsrej")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var atlas = AtlasTexture.new()
	atlas.atlas = TILES.duplicate()
	var rect = Rect2()
	match Game.item_selected:
		Game.Item.CHEESE:
			rect = Rect2(0,128,128,128)
		Game.Item.GARLIC:
			rect = Rect2(384, 128, 128, 128)
		Game.Item.SPRING:
			rect = Rect2(512, 128, 128, 128)
	atlas.set_region(rect)
	sprite.set_texture(atlas)
	modulate.a = 0.8
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	set_position(mouse_pos.snapped(Vector2.ONE * 128 ))
	var level = (get_parent() as Game).get_level()
	if level.local_to_map(global_position) + Vector2i(0,-1) in level.get_used_cells():
		modulate = Color.LIME
		modulate.a = 0.8
	else:
		modulate = Color.RED
		modulate.a = 0.8
		
func _input(event) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			queue_free()
