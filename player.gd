extends CharacterBody3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var speed = 8.0  # movement speed
var jump_speed = 6.0  # determines jump height
var mouse_sensitivity = 0.005  # turning speed
@onready var cam_parent = $cam_parent

func _init() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func get_input():
	var input = -Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

	var movement_dir = cam_parent.transform.basis * Vector3(input.x, 0, input.y)
	velocity.x = movement_dir.x * speed
	velocity.z = movement_dir.z * speed

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		cam_parent.rotate_y(-event.relative.x * mouse_sensitivity)
		cam_parent.rotation.x += event.relative.y * mouse_sensitivity
		cam_parent.rotation.x = clamp(cam_parent.rotation.x, -PI/2, PI/2) 
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_speed
	if Input.is_action_just_pressed("escape"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta):
	velocity.y += -gravity * delta
	get_input()
	move_and_slide()
