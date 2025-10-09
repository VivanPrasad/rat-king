extends CharacterBody2D

@onready var tree: AnimationTree = $AnimationTree
@onready var sprite: Sprite2D = $Sprite2D
@onready var ray: RayCast2D = $RayCast2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var area_2d: Area2D = $Area2D

@onready var squeak: AudioStreamPlayer2D = $Squeak
@onready var squeal: AudioStreamPlayer2D = $Squeal
@onready var gold_stack: Node2D = $GoldPile

const SPEED := 120.0
const JUMP_VELOCITY := -350.0
const RAY_LENGTH := 30.0

const GOLD_PILE = preload("uid://dfurfhfx1xq7t")
const POOF = preload("uid://cn5maweohnepm")

enum State {RUN, JUMP, FALL}
@export var state: State = State.RUN
@export var direction: int = 0 # 1 = left, 0 = right

var gold: int = 0
func _ready() -> void:
	create_tween().tween_property(sprite,^"scale",Vector2.ONE * 0.06, 0.3).from(Vector2.ONE * 0.001)
	area_2d.monitoring = false
	handle_lifetime()
	await get_tree().create_timer(0.5).timeout
	area_2d.monitoring = true
	
func _physics_process(delta: float) -> void:
	var go := Vector2(-1 if direction else 1, 0)
	ray.target_position.x = go.x * RAY_LENGTH
	collision.position.x = go.x * 12.0
	velocity.x = go.x * SPEED
	match state:
		State.RUN:
			tree.get(&"parameters/playback").travel("Run")
			tree.set(&"parameters/Run/blend_position", go.x)
		State.JUMP:
			tree.get(&"parameters/playback").travel("Jump")
			tree.set(&"parameters/Jump/blend_position", go.x)
		State.FALL:
			tree.get(&"parameters/playback").travel("Fall")
			tree.set(&"parameters/Fall/blend_position", go.x)
			velocity.x *= 0.9
	
	if randi() % 1000 == 0:
		squeak.pitch_scale = randf_range(1.2,1.25)
		squeak.play()
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	
	if ray.is_colliding() and ray.get_collider() is TileMapLayer and is_on_floor():
		velocity.y = JUMP_VELOCITY
		if randi() % 2 == 0:
			squeak.pitch_scale = randf_range(0.95,1.05)
			squeak.play()
	
	if velocity.y > 0:
		state = State.FALL
	elif velocity.y < 0:
		state = State.JUMP
	
	if go and velocity.y == 0:
		state = State.RUN

	move_and_slide()
	
@onready var timer: Timer = $Timer

func handle_lifetime() -> void:
	modulate.g = randf_range(0.8,1.0)
	modulate.b = randf_range(0.8,1.0)
	timer.wait_time += randf_range(-1.0, 1.5)
	await timer.timeout
	handle_poof()

func handle_poof() -> void:
	squeal.pitch_scale = randf_range(0.92,1.05)
	squeal.play()
	hide()
	set_physics_process(false)
	var poof := POOF.instantiate()
	poof.position = position + Vector2(randi_range(-10,10), randi_range(-10,10))
	get_parent().get_parent().add_child(poof)
	create_tween().tween_property(poof, "scale", Vector2.ONE * 1.2, 0.8)
	create_tween().tween_property(poof.get_child(1), "energy", 0.0, 1.0)
	await create_tween().tween_property(poof, "modulate:a", 0.0, 1.0).finished
	poof.queue_free()
	queue_free()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if not area is Item: return
	var item: Item = area as Item
	match item.id:
		Item.ID.CHEESE:
			timer.start()
		Item.ID.GOLD:
			gold += 1
			var pile = GOLD_PILE.instantiate()
			pile.position.y = -8 * gold
			gold_stack.add_child(pile)
			squeak.pitch_scale = randf_range(0.95,1.05)
			squeak.play()
		Item.ID.TRAP:
			$"/root/Game".rat_deaths += 1
			handle_poof()
		Item.ID.GARLIC:
			direction = !direction
			squeak.pitch_scale = randf_range(0.6,0.7)
			squeak.play()
		Item.ID.SPRING:
			velocity.y = JUMP_VELOCITY * 2
			#velocity.x *= 4.0
			squeak.pitch_scale = randf_range(0.9,0.95)
			squeak.play()
		Item.ID.RATHOLE:
			Game.gold += self.gold
			$"/root/Game".rat_returns += 1
			var gold_label = $"/root/Game/HUD/MarginContainer/PanelContainer/VBoxContainer/Gold"
			create_tween().tween_property(gold_stack,^"global_position",gold_label.global_position, 0.5)
			await create_tween().tween_property(sprite,^"scale",Vector2.ONE * 0.001, 0.5).finished
			queue_free()
		
func _on_area_2d_area_exited(_area: Area2D) -> void:
	pass
