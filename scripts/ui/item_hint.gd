class_name ItemHint extends Area2D

@onready var sprite: Sprite2D = $Sprite2D

const TILES = preload("uid://drrjqkhudsrej")
const OFFSET :=  Vector2.ONE * 19.2
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var atlas = AtlasTexture.new()
	atlas.atlas = TILES.duplicate()
	var rect = Rect2()
	match Game.item_selected:
		Item.ID.CHEESE:
			rect = Rect2(128,128,128,128)
		Item.ID.GARLIC:
			rect = Rect2(0, 128, 128, 128)
		Item.ID.SPRING:
			rect = Rect2(256, 128, 128, 128)
	atlas.set_region(rect)
	sprite.set_texture(atlas)
	modulate.a = 0.8

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position() - OFFSET
	set_position(mouse_pos.snapped(Game.TILE_SIZE))
	var level = (get_parent() as Game).get_level()

	if Game.gold < Game.ITEM_COSTS[Game.item_selected]:
		modulate = Color.RED
		modulate.a = 0.8
	elif level.local_to_map(position / 0.3) in level.get_used_cells():
		modulate = Color.RED
		modulate.a = 0.8
	elif level.local_to_map(position / 0.3) \
			+ Vector2i(0,1) in level.get_used_cells():
		modulate = Color(0,1,0,0.8)
	else:
		modulate = Color.RED
		modulate.a = 0.8
		
func _input(event) -> void:
	var can_place := false
	var clicked := false
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			clicked = true
			if modulate == Color(0,1,0,0.8): can_place = true
		else: return
	else: return
	
	if can_place:
		var game := get_parent() as Game
		var level = game.get_level()
		var mouse_pos = get_viewport().get_mouse_position() \
			- Vector2.ONE * 19.2
		set_position(mouse_pos.snapped(Game.TILE_SIZE))
		var pos = level.local_to_map(position / 0.3)
		level.set_cell(pos,0,Vector2(Game.item_selected,1))
		game.spawn_tile_trigger(pos)
		Game.gold -= Game.ITEM_COSTS[Game.item_selected]
		game.gold_label.clear()
		game.gold_label.add_image(Game.GOLD_ICON)
		game.gold_label.add_text(" %d" % Game.gold)
		game.gold_used += Game.ITEM_COSTS[Game.item_selected]

	if clicked:
		queue_free()
		get_parent().items.show()
		Game.item_selected = Item.ID.NONE
