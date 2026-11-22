extends CharacterBody3D

var SPEED = 5.0
var JUMP_VELOCITY = 4.5

@onready var camera: Camera3D = $Camera3D if has_node("Camera3D") else get_node_or_null("Head/Camera3D")

var mouse_sensitivity := 0.003
var can_move: bool = true

var default_camera_pos: Vector3 = camera.position if camera else Vector3.ZERO
var default_fov: float = 75.0

func _ready():
	if camera:
		default_fov = camera.fov
	can_move = true
	velocity = Vector3.ZERO

	if not is_in_group("player"):
		add_to_group("player")
	
	call_deferred("_capture_mouse")

func disable_movement():
	can_move = false
	velocity = Vector3.ZERO
	
	if camera:
		camera.fov = 80.0
		camera.position.z = 0.1

func look_at_target(target_global_position: Vector3):
	if camera:
		camera.look_at(target_global_position + Vector3(0, 1.4, 0), Vector3.UP)

func _capture_mouse():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not can_move:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
	move_and_slide()

func _input(event: InputEvent):
	if not can_move:
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		if camera:
			camera.rotate_x(-event.relative.y * mouse_sensitivity)
			camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

	if event.is_action_pressed("esc"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
