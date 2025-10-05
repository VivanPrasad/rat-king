extends CharacterBody2D

@onready var tree: AnimationTree = $AnimationTree
@onready var sprite: Sprite2D = $Sprite2D
@onready var ray: RayCast2D = $RayCast2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var light: PointLight2D = $PointLight2D
@onready var area_2d: Area2D = $Area2D

const SPEED := 120.0
const JUMP_VELOCITY := -350.0
const RAY_LENGTH := 30.0

const POOF = preload("uid://cn5maweohnepm")

enum State {RUN, JUMP, FALL}
@export var state: State = State.RUN
@export var direction: int = 0 # 1 = left, 0 = right

var gold: int = 0
func _ready() -> void:
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
			velocity.x = 0.5 * SPEED
	
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	
	if ray.is_colliding() and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if velocity.y > 0:
		state = State.FALL
	elif velocity.y < 0:
		state = State.JUMP
	
	if go and velocity.y == 0:
		state = State.RUN

	move_and_slide()

func handle_lifetime() -> void:
	modulate.g = randf_range(0.8,1.0)
	modulate.b = randf_range(0.8,1.0)
	await get_tree().create_timer(30.0 + randf_range(-0.25, 1.0)).timeout
	hide()
	set_physics_process(false)
	var poof := POOF.instantiate()
	poof.position = position
	get_parent().get_parent().add_child(poof)
	create_tween().tween_property(poof, "scale", Vector2.ONE * 1.2, 0.8)
	create_tween().tween_property(poof.get_child(1), "energy", 0.0, 1.0)
	await create_tween().tween_property(poof, "modulate:a", 0.0, 1.0).finished
	poof.queue_free()
	queue_free()


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area is Entity:
		match (area as Entity).id:
			1:
				modulate = Color.YELLOW
				light.show()
				gold += 1
			3:
				direction = !direction
			6:
				Game.gold += self.gold
				$"/root/Game".rat_returns += 1
				queue_free()
				
