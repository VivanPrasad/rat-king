extends CharacterBody2D

@onready var tree: AnimationTree = $AnimationTree
@onready var sprite: Sprite2D = $Sprite2D
@onready var ray: RayCast2D = $RayCast2D
@onready var collision: CollisionShape2D = $CollisionShape2D

const SPEED := 120.0
const JUMP_VELOCITY := -350.0
const RAY_LENGTH := 40.0

enum State {RUN, JUMP, FALL}
@export var state: State = State.RUN
@export var direction: int = 0 # 1 = left, 0 = right

func _physics_process(delta: float) -> void:
	var go := Vector2(-1 if direction else 1, 0)
	ray.target_position.x = go.x * RAY_LENGTH
	collision.position.x = go.x * 15.0
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
