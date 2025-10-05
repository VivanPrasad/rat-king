extends CharacterBody2D

@onready var tree: AnimationTree = $AnimationTree
@onready var sprite: Sprite2D = $Sprite2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

enum State {RUN, JUMP, FALL}
@export var state: State = State.RUN
@export var direction: int = 0 # 1 = left, 0 = right

func _physics_process(delta: float) -> void:
	# Add the gravity.
	var go := Vector2(-1 if direction else 1, 0)
	if not is_on_floor():
		velocity += get_gravity() * delta
		tree.get(&"parameters/playback").travel("Fall")
		tree.set(&"parameters/Fall/blend_position", go.x)

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		tree.get(&"parameters/playback").travel("Jump")
		tree.set(&"parameters/Jump/blend_position", go.x)
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if go and is_on_floor():
		velocity.x = go.x * SPEED
		tree.get(&"parameters/playback").travel("Run")
		tree.set(&"parameters/Run/blend_position", go.x)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		# always false

	move_and_slide()
