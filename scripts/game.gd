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

@onready var gold_label: Label = $HUD/MarginContainer/Label

const CAMERA_SCROLL_STR := 0.0005

const BASE_RAT_COUNT := 20
var rat_count: int = BASE_RAT_COUNT

const MAX_ZOOM := 2.5
const MIN_ZOOM := 0.1

const RAT = preload("uid://dsk2bhusk47gt")
const GOLD = preload("uid://cyubd1tbfy40k")
const ITEM_HINT = preload("uid://cdd7sitsj0bio")

var gold: int = 10
var level: int = 1
func _ready() -> void:
	#generate_level()
	info.get_parent().hide()
	connect_items()
	randomize_tiles()

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
	add_child(gold_bag)
	
func randomize_tiles() -> void:
	randomize()
	var used_cells = get_level().get_used_cells()
	for cell in used_cells:
		var random_tile = randi() % 5
		if get_level().get_cell_atlas_coords(cell).y == 0:
			get_level().set_cell(cell, 0, Vector2(random_tile, 0))
		elif get_level().get_cell_atlas_coords(cell) == Vector2i.ONE:
			var gold_bag = GOLD.instantiate()
			gold_bag.position = get_level().to_global(cell) * 128 + Vector2.ONE * 20
			add_child(gold_bag)
	used_cells = background.get_used_cells()
	for cell in used_cells:
		var random_tile = randi() % 5
		background.set_cell(cell, 0, Vector2(random_tile, 0))

func spawn_rats() -> void:
	for i in range(rat_count):
		var rat := RAT.instantiate()
		rat.position = Vector2(80.0, 57.0)
		rat.direction = 0
		entities.add_child(rat)
		await get_tree().create_timer(0.5).timeout
	

func _process(_delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	#var screen_center = get_viewport().get_visible_rect().size / 2.0
	#var offset = screen_center + (mouse_pos * CAMERA_SCROLL_STR)
	torch.global_position = mouse_pos + Vector2.ONE * 10
	#background.position = -(mouse_pos * CAMERA_SCROLL_STR) / 2.0
	#camera.offset = offset
	
	if not timer.is_stopped():
		update_hud()

func update_hud() -> void:
	info.get_parent().show()
	info.text = "Time Left: %d\nRats Left: %d" % [ceil(timer.time_left), entities.get_child_count()]
	gold_label.text = "Gold %d" % gold


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed(&"scroll_up"):
		camera.zoom = clamp(camera.zoom + (Vector2.ONE * 0.1), Vector2.ONE * MIN_ZOOM, Vector2.ONE * MAX_ZOOM)
	elif Input.is_action_just_pressed(&"scroll_down"):
		camera.zoom = clamp(camera.zoom - (Vector2.ONE * 0.1), Vector2.ONE * MIN_ZOOM, Vector2.ONE * MAX_ZOOM)
		
	if Input.is_action_just_pressed("ui_accept"):
		if Engine.get_time_scale() == 1.0:
			Engine.set_time_scale(3.0)
		else:
			Engine.set_time_scale(1.0)
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if item_selected != Item.NONE:
				print("Left mouse button pressed")
			
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
	
func get_level() -> TileMapLayer:
	return levels.get_child(level - 1)
func _on_raid_started() -> void:
	button.hide()
	timer.start()
	spawn_rats()
	
