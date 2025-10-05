class_name Game extends Node2D

@onready var camera: Camera2D = $Camera2D
@onready var background: = $BG/Background
@onready var entities: Node2D = $Entities
@onready var button: Button = $HUD/MarginContainer/Button
@onready var torch: PointLight2D = $Torch
@onready var timer: Timer = $Timer
@onready var info: Label = $HUD/MarginContainer/ColorRect/Label
@onready var items: HBoxContainer = $HUD/MarginContainer/Items
@onready var levels: Node2D = $Levels
@onready var objects: Node2D = $Objects

@onready var gold_label: Label = $HUD/MarginContainer/Label

const BASE_RAT_COUNT := 20
var rat_count: int = 0
var rat_returns: int = BASE_RAT_COUNT

const MAX_ZOOM := 2.5
const MIN_ZOOM := 0.1

const RAT = preload("uid://dsk2bhusk47gt")
const GOLD = preload("uid://cyubd1tbfy40k")
const GARLIC = preload("uid://tud78dncd262")
const ITEM_HINT = preload("uid://cdd7sitsj0bio")
const CHEESE = preload("uid://h0ca6ubx7u06")
const SPRING = preload("uid://ckwbdwrcgupds")
const TRAP = preload("uid://c0gploh4s2x81")
const RATHOLE = preload("uid://n5087ubsj2jj")
const TRANSITION = preload("uid://c4yexj8r26st2")

const OBJECTS = [CHEESE, GOLD, TRAP, GARLIC, SPRING, RATHOLE]
static var gold: int = 10
static var level: int = 0

static var rat_hole: Vector2

const ITEM_COSTS := [10, 15, 20]
func _ready() -> void:
	#generate_level()
	for i in range(levels.get_child_count()):
		(levels.get_child(i) as TileMapLayer).enabled = false
		(levels.get_child(i)).show()
	next_level()
	connect_items()

func game_over() -> void:
	var transition := TRANSITION.instantiate()
	transition.message = "Game Over"
	$HUD.add_child(transition)
	await transition.faded
	level = 0
	gold = 10
	rat_count = 0
	rat_returns = BASE_RAT_COUNT
	get_tree().change_scene_to_file("res://scenes/title.tscn")

func next_level() -> void:
	can_leave = false
	timer.stop()
	var transition := TRANSITION.instantiate()
	transition.message = "Level %d" % [level + 1]
	$HUD.add_child(transition)
	await transition.faded
	levels.get_children()[level - 1].enabled = false
	levels.get_children()[level].enabled = true
	level += 1
	info.get_parent().hide()
	for child in objects.get_children():
		child.queue_free()
	randomize_tiles()
	if level == 1:
		items.get_child(1).hide()
		items.get_child(2).hide()
	if level == 3:
		items.get_child(1).show()
		items.get_child(2).show()
	rat_count = rat_returns
	rat_returns = 0
	button.show()
	set_process(true)
	
	
func generate_level() -> void:
	get_level().clear()
	for x in range(-2,31):
		get_level().set_cell(Vector2i(x, -2), 0, Vector2.ZERO)
		get_level().set_cell(Vector2i(x, 17), 0, Vector2.ZERO)
		get_level().set_cell(Vector2i(x, 18), 0, Vector2.ZERO)

	# Vertical borders (left and right)
	for y in range(-2,18):
		get_level().set_cell(Vector2i(-2, y), 0, Vector2.ZERO)
		get_level().set_cell(Vector2i(-1, y), 0, Vector2.ZERO)
		get_level().set_cell(Vector2i(30, y), 0, Vector2.ZERO)
		get_level().set_cell(Vector2i(31, y), 0, Vector2.ZERO)
	for y in range(1,17):
		for x in range(1, 29):
			if randi() % 5 == 0:
				get_level().set_cell(Vector2(x,y), 0, Vector2.ZERO)
	
	var cell = get_level().get_used_cells().pick_random()
	while cell.x < 1 or cell.x > 28 or cell.y < 1 or cell.y > 16:
		cell = get_level().get_used_cells().pick_random()
	get_level().set_cell(cell, 0, Vector2(1,1))
	var gold_bag = GOLD.instantiate()
	gold_bag.position = get_level().to_global(cell)
	objects.add_child(gold_bag)
	
func randomize_tiles() -> void:
	randomize()
	var used_cells = get_level().get_used_cells()
	for cell in used_cells:
		var random_tile = randi() % 5
		if get_level().get_cell_source_id(cell) == 1:
			rat_hole = get_level().to_global(cell + Vector2i(1,0)) * 128 + Vector2.ONE * 10
			var obj: Entity = OBJECTS[-1].instantiate()
			obj.global_position = get_level().to_global(cell) * 128 + Vector2.ONE * 20
			obj.id = 6
			objects.add_child(obj)
		elif get_level().get_cell_atlas_coords(cell).y == 0:
			get_level().set_cell(cell, 0, Vector2(random_tile, 0))
		else:
			spawn_tile_trigger(cell)
	used_cells = background.get_used_cells()
	for cell in used_cells:
		var random_tile = randi() % 5
		background.set_cell(cell, 0, Vector2(random_tile, 0))

func spawn_tile_trigger(cell: Vector2i) -> void:
	var coords = get_level().get_cell_atlas_coords(cell)
	match coords:
		_:
			var obj: Entity = OBJECTS[coords.x].instantiate()
			obj.global_position = get_level().to_global(cell) * 128 + Vector2.ONE * 20
			obj.id = coords.x
			objects.add_child(obj)

var can_leave: bool = false
func spawn_rats() -> void:
	for i in range(rat_count):
		var rat := RAT.instantiate()
		rat.position = rat_hole
		rat.direction = 0
		entities.add_child(rat)
		await get_tree().create_timer(0.5).timeout
	can_leave = true
	

func _process(_delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	#var screen_center = get_viewport().get_visible_rect().size / 2.0
	#var offset = screen_center + (mouse_pos * CAMERA_SCROLL_STR)
	torch.global_position = mouse_pos + Vector2.ONE * 10
	#background.position = -(mouse_pos * CAMERA_SCROLL_STR) / 2.0
	#camera.offset = offset
	
	if not timer.is_stopped():
		update_hud()
	
	if can_leave and entities.get_child_count() == 0 and rat_returns > 0:
		set_process(false)
		await get_tree().create_timer(1.0).timeout
		next_level()
	elif can_leave and entities.get_child_count() == 0 and rat_returns == 0:
		set_process(false)
		await get_tree().create_timer(1.0).timeout
		game_over()
	elif can_leave and timer.is_stopped() and rat_returns == 0:
		set_process(false)
		await get_tree().create_timer(1.0).timeout
		game_over()
	elif can_leave and timer.is_stopped() and rat_returns > 0:
		set_process(false)
		await get_tree().create_timer(1.0).timeout
		next_level()


func update_hud() -> void:
	info.get_parent().show()
	info.text = "Time Left: %d\nRats Left: %d" % [ceil(timer.time_left), entities.get_child_count()]
	gold_label.text = "Gold: %d" % gold


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed(&"scroll_up"):
		camera.zoom = clamp(camera.zoom + (Vector2.ONE * 0.1), Vector2.ONE * MIN_ZOOM, Vector2.ONE * MAX_ZOOM)
	elif Input.is_action_just_pressed(&"scroll_down"):
		camera.zoom = clamp(camera.zoom - (Vector2.ONE * 0.1), Vector2.ONE * MIN_ZOOM, Vector2.ONE * MAX_ZOOM)
		
	if Input.is_action_just_pressed("ui_accept"):
		if Engine.get_time_scale() == 1.0:
			Engine.set_time_scale(3.0)
		else:
			Engine.set_time_scale(1.0)
			
func connect_items() -> void:
	for item in items.find_children("*","TextureButton"):
		(item as TextureButton).pivot_offset = Vector2.ONE * 36
		(item as TextureButton).mouse_entered.connect(
			func(): create_tween().tween_property(item, "scale", Vector2.ONE * 1.1, 0.1)
		)
		(item as TextureButton).mouse_exited.connect(
			func(): create_tween().tween_property(item, "scale", Vector2.ONE, 0.1)
		)
		(item as TextureButton).pressed.connect(
			_on_item_selected.bind(item)
		)

enum Item {GARLIC, CHEESE, SPRING, NONE = -1}
static var item_selected: Item = Item.NONE
func _on_item_selected(item: TextureButton) -> void:
	item_selected = item.get_parent().get_index() as Item
	match item.name:
		_:
			var hint := ITEM_HINT.instantiate()
			add_child(hint)
			items.hide()
	
func get_level() -> TileMapLayer:
	return levels.get_child(level - 1)
	
func _on_raid_started() -> void:
	button.hide()
	timer.start()
	spawn_rats()
	
