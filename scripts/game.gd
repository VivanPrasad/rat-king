class_name Game extends Node2D

@onready var camera: Camera2D = $Camera2D
@onready var background: = $BG/Background
@onready var texture_rect: TextureRect = $BG/TextureRect
@onready var entities: Node2D = $Entities

@onready var play_button: TextureButton = $HUD/MarginContainer/PanelContainer3/Button
@onready var pause_button: TextureButton = $HUD/MarginContainer/HBoxContainer/PanelContainer/TextureButton2
@onready var retry_button: TextureButton = $HUD/MarginContainer/HBoxContainer/PanelContainer2/TextureButton


@onready var torch: PointLight2D = $Torch
@onready var timer: Timer = $Timer
@onready var info: RichTextLabel = $HUD/MarginContainer/PanelContainer2/HBoxContainer/Label
@onready var items: HBoxContainer = $HUD/MarginContainer/PanelContainer/VBoxContainer/Items
@onready var levels: Node2D = $Levels
@onready var objects: Node2D = $Objects
@onready var time_bar: TextureProgressBar = $HUD/MarginContainer/PanelContainer2/HBoxContainer/TimeBar

@onready var gold_label: RichTextLabel = $HUD/MarginContainer/PanelContainer/VBoxContainer/Gold

@onready var lighting: DirectionalLight2D = $DirectionalLight2D

const BASE_RAT_COUNT := 10
var rat_count: int = 0
var rat_returns: int = BASE_RAT_COUNT
var rat_deaths: int = 0

const MAX_ZOOM := 2.5
const MIN_ZOOM := 1.0

const CREDITS = preload("uid://xmcyfq0e5ksu")
const RAT = preload("uid://dsk2bhusk47gt")
const GOLD = preload("uid://cyubd1tbfy40k")
const GARLIC = preload("uid://tud78dncd262")
const ITEM_HINT = preload("uid://cdd7sitsj0bio")
const CHEESE = preload("uid://h0ca6ubx7u06")
const SPRING = preload("uid://ckwbdwrcgupds")
const TRAP = preload("uid://c0gploh4s2x81")
const RATHOLE = preload("uid://n5087ubsj2jj")
const TRANSITION = preload("uid://c4yexj8r26st2")

const RAT_ICON = preload("uid://blh4qyg52vtja")
const GOLD_ICON = preload("uid://daah0lgxpo0b7")
const OBJECTS = [GARLIC, CHEESE, SPRING, null, null, null, TRAP, GOLD, RATHOLE]

const RAT_INFO_TEXT := "%d  [img]res://assets/rat_icon.png[/img]\
	[color=40ff00]%d[/color]  [img]res://assets/rat_check_icon.png[/img]\
	[color=ff0040]%d[/color]  [img]res://assets/rat_cross_icon.png[/img]"

const TILE_SIZE = Vector2.ONE * 128 * 0.3
static var gold: int = 0
static var level: int = 0

var gold_used: int = 0
static var rat_hole: Vector2

const ITEM_COSTS := [5, 7, 10]
func _ready() -> void:
	spectrum = AudioServer.get_bus_effect_instance(2, 0) 
	for i in range(levels.get_child_count()):
		(levels.get_child(i) as TileMapLayer).enabled = false
		(levels.get_child(i)).show()
	info.get_parent().get_parent().hide()
	pause_button.hide()
	retry_button.hide()
	next_level()
	connect_items()
	connect_buttons()
	
	# Master bus, first effect


func game_over() -> void:
	var transition := TRANSITION.instantiate()
	transition.message = "Game Over"
	$HUD.add_child(transition)
	await transition.faded
	level = 0
	gold = 0
	gold_used = 0
	rat_count = 0
	rat_deaths = 0
	rat_returns = BASE_RAT_COUNT
	get_tree().change_scene_to_file("res://scenes/title.tscn")

func win() -> void:
	var transition := TRANSITION.instantiate()
	transition.message = "Thanks for playing!"
	$HUD.add_child(transition)
	await transition.faded
	level = 0
	gold = 0
	gold_used = 0
	rat_count = 0
	rat_deaths = 0
	rat_returns = BASE_RAT_COUNT
	get_tree().change_scene_to_file("res://scenes/ui/credits.tscn")

func next_level() -> void:
	play_button.hide()
	items.hide()
	can_leave = false
	timer.stop()
	if (level + 1) > levels.get_child_count():
		win()
		return
	var transition := TRANSITION.instantiate()
	transition.message = "Level %d" % [level + 1]
	$HUD.add_child(transition)
	if level != 0:
		levels.get_children()[level - 1].enabled = true
	levels.get_children()[level].enabled = true
	levels.get_children()[level].position.y = 648
	texture_rect.position.y = 0
	if level != 0:
		levels.get_children()[level - 1].position.y = 0
		create_tween().tween_property(levels.get_children()[level - 1],^"position:y",-648,2.0).set_trans(Tween.TRANS_CUBIC)
	create_tween().tween_property(texture_rect,^"position:y",-384.0,2.0).set_trans(Tween.TRANS_CUBIC)
	create_tween().tween_property(levels.get_children()[level],^"position:y",0,2.0).set_trans(Tween.TRANS_CUBIC)
	await transition.faded
	if level != 0:
		levels.get_children()[level - 1].enabled = false
		levels.get_children()[level - 1].position.y = 0
	texture_rect.position.y = 0
	level += 1
	info.get_parent().get_parent().hide()
	time_bar.hide()
	for child in entities.get_children(): child.queue_free()
	for child in objects.get_children(): child.queue_free()
	randomize_tiles()
	if level == 1:
		items.get_child(1).hide()
		items.get_child(2).hide()
	if level == 3:
		items.get_child(1).show()
		items.get_child(2).show()
	rat_count = rat_returns
	create_tween().tween_property($Music,^"pitch_scale", 1.0 - (level * 0.05), 2.0)
	var luma = 1.0 - ((level - 1) * 0.12)
	texture_rect.self_modulate = Color(luma,luma,luma)
	rat_returns = 0
	rat_deaths = 0
	gold_used = 0
	play_button.show()
	pause_button.hide()
	retry_button.hide()
	items.show()
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
		var random_tile = randi() % 8
		if get_level().get_cell_source_id(cell) == 1:
			rat_hole = get_level().to_global(cell + Vector2i(1,0)) * 128 + Vector2.ONE * 10
			var obj: Item = OBJECTS[-1].instantiate()
			obj.global_position = get_level().to_global(cell) * 128 + Vector2.ONE * 20
			obj.id = Item.ID.RATHOLE
			objects.add_child(obj)
		elif get_level().get_cell_atlas_coords(cell).y == 0:
			get_level().set_cell(cell, 0, Vector2(random_tile, 0))
		else:
			spawn_tile_trigger(cell)
	used_cells = background.get_used_cells()
	for cell in used_cells:
		var random_tile = randi() % 8
		background.set_cell(cell, 0, Vector2(random_tile, 0))

func spawn_tile_trigger(cell: Vector2i) -> void:
	var coords = get_level().get_cell_atlas_coords(cell)
	if not OBJECTS[coords.x]: return
	match coords:
		_:
			var obj: Item = OBJECTS[coords.x].instantiate()
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
		await get_tree().create_timer(randf_range(0.4,0.6)).timeout
	can_leave = true
	

func _process(_delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	torch.global_position = mouse_pos + Vector2.ONE * 10
	
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
	
	if not spectrum: return
	volume = spectrum.get_magnitude_for_frequency_range(0, 10000).length()
	if volume > 0.01:
		lighting.energy = 1.0 - (volume * 7)
	else:
		lighting.energy = 1.0

func update_hud() -> void:
	info.get_parent().get_parent().show()
	time_bar.show()
	info.text = RAT_INFO_TEXT % [entities.get_child_count(), rat_returns, rat_deaths]
	gold_label.clear()
	gold_label.add_image(GOLD_ICON)
	gold_label.add_text("%d" % gold)
	
	time_bar.value = timer.time_left
	time_bar.get_child(0).text = "%d" % round(timer.time_left)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed(&"scroll_up"):
		camera.zoom = clamp(camera.zoom + (Vector2.ONE * 0.1), Vector2.ONE * MIN_ZOOM, Vector2.ONE * MAX_ZOOM)
	elif Input.is_action_just_pressed(&"scroll_down"):
		camera.zoom = clamp(camera.zoom - (Vector2.ONE * 0.1), Vector2.ONE * MIN_ZOOM, Vector2.ONE * MAX_ZOOM)

func connect_buttons() -> void:
	for node in [play_button, pause_button, retry_button]:
		var button: TextureButton = node as TextureButton
		button.get_parent().pivot_offset = Vector2(24,24)
		button.mouse_entered.connect(
			func(): create_tween().tween_property(
				button.get_parent(), "scale", Vector2.ONE * 1.2, 0.05))
		button.mouse_exited.connect(
			func(): create_tween().tween_property(
				button.get_parent(), "scale", Vector2.ONE, 0.05))
		
func connect_items() -> void:
	for item in items.get_children():
		(item as TextureButton).pivot_offset = Vector2.ONE * 36
		(item as TextureButton).mouse_entered.connect(
			func(): create_tween().tween_property(
				item, "scale", Vector2.ONE * 1.1, 0.1))
		(item as TextureButton).mouse_exited.connect(
			func(): create_tween().tween_property(
				item, "scale", Vector2.ONE, 0.1))
		(item as TextureButton).pressed.connect(
			_on_item_selected.bind(item))
		var label: RichTextLabel = item.get_child(0) as RichTextLabel
		label.clear()
		label.add_text("%d" % ITEM_COSTS[item.get_index()])
		label.add_image(GOLD_ICON,28)

static var item_selected: Item.ID = Item.ID.NONE
func _on_item_selected(item: TextureButton) -> void:
	item_selected = item.get_index() as Item.ID
	if ITEM_COSTS[item_selected] > gold: return
	match item.name:
		_:
			var hint := ITEM_HINT.instantiate()
			add_child(hint)
			items.hide()
	
func get_level() -> TileMapLayer:
	return levels.get_child(level - 1)
	
func _on_raid_started() -> void:
	play_button.hide()
	retry_button.show()
	pause_button.show()
	if not get_tree().is_paused():
		spawn_rats()
		timer.start()
	else:
		get_tree().paused = false

func _on_raid_paused() -> void:
	get_tree().paused = true
	play_button.show()
	pause_button.hide()

func _on_raid_retry() -> void:
	get_tree().paused = false
	pause_button.hide()
	retry_button.hide()
	rat_returns = 0
	level -= 1
	gold += gold_used
	if level == 0: gold = 0
	get_tree().reload_current_scene()

var spectrum: AudioEffectInstance
var volume: float
