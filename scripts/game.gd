extends Node2D

@onready var camera: Camera2D = $Camera2D
@onready var background: = $BG/Background
@onready var entities: Node2D = $Entities
@onready var level: TileMapLayer = $Level

const CAMERA_SCROLL_STR := 0.005

const BASE_RAT_COUNT := 20
var rat_count: int = BASE_RAT_COUNT

const MAX_ZOOM := 2.5
const MIN_ZOOM := 0.1

const RAT = preload("uid://dsk2bhusk47gt")

func _ready() -> void:
	spawn_rats()
	randomize_tiles()

func randomize_tiles() -> void:
	randomize()
	var used_cells = level.get_used_cells()
	for cell in used_cells:
		var random_tile = randi() % 5
		level.set_cell(cell, 0, Vector2(random_tile, 0))
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
	var screen_center = get_viewport().get_visible_rect().size / 2.0
	var offset = screen_center + (mouse_pos * CAMERA_SCROLL_STR)
	background.position = -(mouse_pos * CAMERA_SCROLL_STR) / 2.0
	camera.offset = offset
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
	
