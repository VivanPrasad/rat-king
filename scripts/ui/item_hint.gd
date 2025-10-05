class_name ItemHint extends Area2D

@onready var sprite: Sprite2D = $Sprite2D

const TILES = preload("uid://drrjqkhudsrej")

const ITEM_COORDS = [Vector2i(3,1), Vector2i(0,1), Vector2i(4,1)]
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

	if Game.gold < Game.ITEM_COSTS[Game.item_selected]:
		modulate = Color.RED
		modulate.a = 0.8
	elif level.local_to_map(position / 0.3) in level.get_used_cells():
		modulate = Color.RED
		modulate.a = 0.8
	elif level.local_to_map(position / 0.3) + Vector2i(0,1) in level.get_used_cells():
		modulate = Color(0,1,0,0.8)
	else:
		modulate = Color.RED
		modulate.a = 0.8
		
func _input(event) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			if modulate == Color(0,1,0,0.8):
				var level = (get_parent() as Game).get_level()
				var mouse_pos = get_viewport().get_mouse_position()
				set_position(mouse_pos.snapped(Vector2.ONE * 128 * 0.3))
				var pos = level.local_to_map(position / 0.3)
				level.set_cell(pos,0,ITEM_COORDS[Game.item_selected])
				Game.gold -= Game.ITEM_COSTS[Game.item_selected]
				get_parent().gold_label.text = "Gold: %d" % Game.gold
			queue_free()
			get_parent().items.show()
			Game.item_selected = Game.Item.NONE
