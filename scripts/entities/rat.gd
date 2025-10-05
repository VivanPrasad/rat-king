extends CharacterBody2D

@onready var tree: AnimationTree = $AnimationTree
@onready var sprite: Sprite2D = $Sprite2D
@onready var ray: RayCast2D = $RayCast2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var light: PointLight2D = $PointLight2D

const SPEED := 120.0
const JUMP_VELOCITY := -350.0
const RAY_LENGTH := 40.0

const POOF = preload("uid://cn5maweohnepm")


enum State {RUN, JUMP, FALL}
@export var state: State = State.RUN
@export var direction: int = 0 # 1 = left, 0 = right

func _ready() -> void:
	handle_lifetime()
	
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
	
	if ray.is_colliding() and is_on_floor() and ray.get_collider().name != "Gold":
		velocity.y = JUMP_VELOCITY
	
	if ray.is_colliding() and ray.get_collider().name == "Gold" and modulate != Color.YELLOW:
		modulate = Color.YELLOW
		light.show()
		direction = !direction
	
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
	get_parent().add_child(poof)
	create_tween().tween_property(poof, "scale", Vector2.ONE * 1.2, 0.8)
	create_tween().tween_property(poof.get_child(1), "energy", 0.0, 1.0)
	await create_tween().tween_property(poof, "modulate:a", 0.0, 1.0).finished
	poof.queue_free()
	queue_free()
