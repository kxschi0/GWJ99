extends CharacterBody3D

var mouse_sensitivity: float = 0.002
@onready var player_camera: Camera3D = $PlayerCamera
@onready var interact_ray: ShapeCast3D = $PlayerCamera/InteractRay

var peek_transition: float = 0.0:
	set(value):
		peek_transition = clamp(value, 0.0, 1.0)
const peek_speed: float = 0.5

var madness: float = 0.0:
	set(value):
		madness = clamp(value, 0.0, 1.0)
		if madness == 1.0:
			SignalBus.madness_level_changed.emit(6)
		elif madness >= 0.8:
			SignalBus.madness_level_changed.emit(5)
		elif madness >= 0.6:
			SignalBus.madness_level_changed.emit(4)
		elif madness >= 0.4:
			SignalBus.madness_level_changed.emit(3)
		elif madness >= 0.2:
			SignalBus.madness_level_changed.emit(2)
		elif madness >= 0.1:
			SignalBus.madness_level_changed.emit(1)
		else:
			SignalBus.madness_level_changed.emit(0)
const madness_buildup_speed: float = 0.05

const speed: float = 6.0
var input_dir: Vector2 = Vector2.ZERO
var move_dir: Vector3 = Vector3.ZERO

var can_move: bool = true

var camera_relative: Vector2:
	set(value):
		update_camera(value)

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	SignalBus.pills_collected.connect(_on_pills_collected)

func _process(delta: float) -> void:
	if not can_move:
		return
	
	input_dir = Input.get_vector("Left", "Right","Forward","Backward")
	move_dir = Vector3(input_dir.x, 0.0, input_dir.y).rotated(Vector3.UP, rotation.y)
	
	if Input.is_action_pressed("Peek"):
		peek_transition += peek_speed * delta
		madness += madness_buildup_speed * delta
	elif peek_transition > 0.0:
		peek_transition -= 2.0 * peek_speed * delta
	
	if interact_ray.is_colliding() and interact_ray.enabled:
		for collision in interact_ray.get_collision_count():
			var collider: Object = interact_ray.get_collider(collision)
			if collider is Interactable:
				get_tree().current_scene.hud.show_interaction_text(collider.interaction_text)
				if Input.is_action_just_pressed("Interact"):
					interact(collider)
			else:
				if collision == 0:
					get_tree().current_scene.hud.hide_interaction_text()
				break
	elif interact_ray.enabled:
		get_tree().current_scene.hud.hide_interaction_text()

func _physics_process(delta: float) -> void:
	if not can_move:
		return
	
	if move_dir:
		velocity.x = move_dir.x * speed * remap(madness, 0.0, 1.0, 1.0, 0.4)
		velocity.z = move_dir.z * speed * remap(madness, 0.0, 1.0, 1.0, 0.4)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0
	
	move_and_slide()

func update_camera(relative: Vector2) -> void:
	if not can_move:
		return
	
	rotate_y(-relative.x * mouse_sensitivity)
	player_camera.rotate_x(-relative.y * mouse_sensitivity)
	player_camera.rotation_degrees.x = clamp(player_camera.rotation_degrees.x, -90.0, 90.0)

func interact(interactable: Interactable) -> void:
	interactable._on_interaction()

func _on_pills_collected() -> void:
	const pills_restoring_value: float = 0.3
	madness -= pills_restoring_value

func disable_movement():
	can_move = false
	velocity = Vector3.ZERO
	
	if player_camera:
		player_camera.fov = 80.0
		player_camera.position.z = 0.1

func look_at_target(target_global_position: Vector3):
	if player_camera:
		player_camera.look_at(target_global_position + Vector3(0, 1.4, 0), Vector3.UP)
