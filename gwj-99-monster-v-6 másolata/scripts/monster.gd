extends CharacterBody3D

var player_path: NodePath
var base_player_speed:= 5.0
var detection_range:= 14.0
var field_of_view_degrees:= 180.0

@export_group("Spawning Rules")
@export var min_spawn_distance_from_player:= 10.0
@export var spawn_area_half_extents: Vector2 = Vector2(12.0, 12.0)
@export var max_spawn_attempts: int = 40

@export_group("Smooth Movement")
@export var acceleration:= 8.0
@export var deceleration:= 10.0
@export var turn_smoothness:= 8.0
@export var head_bob_amplitude:= 0.0
@export var head_bob_frequency:= 0.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var raycast: RayCast3D = $RayCast3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var visual_pivot: Node3D = $VisualPivot
@onready var animation_player: AnimationPlayer = $VisualPivot/AnimationPlayer
@onready var jumpscare_area: Area3D = $JumpscareArea

enum State { GRACE_PERIOD, PATROL, CHASE, SEARCHING, COOLDOWN, JUMPSCARE }
var current_state: State = State.GRACE_PERIOD

var state_timer:= 0.0
var grace_time:= 15.0
var active_patrol_time:= 25.0
var cooldown_time:= 20.0
var detection_penalty:= 15.0

var player: Node3D = null
var is_spawned: bool = false
var fallback_spawn_origin: Vector3
var exact_spawn_position: Vector3
var last_known_player_position: Vector3

var patrol_pause_timer:= 0.0
var look_around_base_yaw:= 0.0
var look_around_time:= 0.0
var search_timer:= 0.0
var stuck_timer:= 0.0
var last_position: Vector3

var smooth_velocity: Vector3 = Vector3.ZERO
var target_yaw:= 0.0
var bob_time:= 0.0

var saved_scene_path: String = ""

func _ready():
	fallback_spawn_origin = global_position
	exact_spawn_position = global_position
	last_position = global_position
	target_yaw = rotation.y
	
	if get_tree().current_scene:
		saved_scene_path = get_tree().current_scene.scene_file_path
	
	raycast.add_exception(self)
	call_deferred("_find_player")
	
	if not animation_player and has_node("VisualPivot/AnimationPlayer"):
		animation_player = $VisualPivot/AnimationPlayer
		
	if jumpscare_area and not jumpscare_area.is_connected("body_entered", Callable(self, "_on_jumpscare_body_entered")):
		jumpscare_area.body_entered.connect(_on_jumpscare_body_entered)
	
	current_state = State.GRACE_PERIOD
	state_timer = grace_time
	set_stalker_active(false)

func _find_player():
	if not player_path.is_empty():
		player = get_node_or_null(player_path)
	if not player:
		player = get_tree().get_first_node_in_group("player")

func _process(delta):
	if not visual_pivot:
		return
		
	if current_state == State.JUMPSCARE:
		return
		
	rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-turn_smoothness * delta))
	
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	if is_spawned and horizontal_speed > 0.2:
		bob_time += delta * head_bob_frequency * (horizontal_speed / 3.5)
		visual_pivot.position.y = sin(bob_time) * head_bob_amplitude
		var target_pitch = deg_to_rad(-4.0 * clamp(horizontal_speed / 4.0, 0.0, 1.0))
		visual_pivot.rotation.x = lerp_angle(visual_pivot.rotation.x, target_pitch, 1.0 - exp(-8.0 * delta))
	else:
		bob_time = 0.0
		visual_pivot.position.y = lerp(visual_pivot.position.y, 0.0, 1.0 - exp(-8.0 * delta))
		visual_pivot.rotation.x = lerp_angle(visual_pivot.rotation.x, 0.0, 1.0 - exp(-8.0 * delta))
		
	update_animations(horizontal_speed)

func update_animations(speed):
	if not animation_player or current_state == State.JUMPSCARE:
		return
		
	var anim_to_play = "MonsterIdle"
	
	if current_state == State.CHASE:
		anim_to_play = "MonsterRun"
	elif speed > 0.1:
		anim_to_play = "MonsterCrawl"
	else:
		anim_to_play = "MonsterIdle"
		
	play_anim(anim_to_play)

func play_anim(anim_name: String):
	if not animation_player:
		return
		
	var target_anim = anim_name
	
	if not animation_player.has_animation(target_anim):
		var found = false
		for lib in animation_player.get_animation_library_list():
			var full_name = str(lib) + "/" + anim_name
			if animation_player.has_animation(full_name):
				target_anim = full_name
				found = true
				break
		if not found and "/" not in anim_name:
			if animation_player.has_animation("Animpack1/" + anim_name):
				target_anim = "Animpack1/" + anim_name
				
	if animation_player.has_animation(target_anim):
		if animation_player.current_animation != target_anim or not animation_player.is_playing():
			animation_player.play(target_anim)

func _on_jumpscare_body_entered(body):
	if current_state == State.JUMPSCARE:
		return
		
	if body == player or body.is_in_group("player") or (player and body == player):
		trigger_jumpscare()

func trigger_jumpscare():
	if current_state == State.JUMPSCARE:
		return
		
	current_state = State.JUMPSCARE
	smooth_velocity = Vector3.ZERO
	velocity = Vector3.ZERO
	
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
		
	play_anim("MonsterJumpscareAttack")
	
	if player:
		if player.has_method("disable_movement"):
			player.disable_movement()
		if player.has_method("look_at_target"):
			player.look_at_target(global_position)
	
	var anim_length = 1.5
	var target_anim = "MonsterJumpscareAttack"
	if not animation_player.has_animation(target_anim):
		for lib in animation_player.get_animation_library_list():
			if animation_player.has_animation(str(lib) + "/MonsterJumpscareAttack"):
				target_anim = str(lib) + "/MonsterJumpscareAttack"
				break
				
	if animation_player.has_animation(target_anim):
		var anim = animation_player.get_animation(target_anim)
		if anim:
			anim_length = max(anim.length, 1.0)
			
	var tree = get_tree()
	if tree:
		tree.create_timer(anim_length).timeout.connect(_on_jumpscare_finished)
	else:
		var main_tree = Engine.get_main_loop() as SceneTree
		if main_tree:
			main_tree.create_timer(anim_length).timeout.connect(_on_jumpscare_finished)

func _on_jumpscare_finished():
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		if not saved_scene_path.is_empty():
			tree.change_scene_to_file(saved_scene_path)
		else:
			tree.reload_current_scene()

func _physics_process(delta):
	if player and is_spawned and current_state != State.JUMPSCARE:
		if global_position.distance_to(player.global_position) < 1.3:
			trigger_jumpscare()
			return

	if current_state == State.JUMPSCARE:
		return
		
	if not player:
		_find_player()

	state_timer -= delta

	match current_state:
		State.GRACE_PERIOD:
			if state_timer <= 0.0:
				start_patrol()
				
		State.PATROL:
			patrol_behavior(delta)
			if state_timer <= 0.0:
				start_cooldown()
			elif check_player_detected():
				trigger_detection_penalty()
				
		State.CHASE:
			chase_behavior(delta)
			if state_timer <= 0.0:
				start_cooldown()
			elif check_player_detected():
				trigger_detection_penalty()
				
		State.SEARCHING:
			searching_behavior(delta)
			if state_timer <= 0.0:
				start_cooldown()
			elif check_player_detected():
				trigger_detection_penalty()
				
		State.COOLDOWN:
			if is_spawned:
				cooldown_behavior(delta)
				if state_timer <= 0.0:
					if check_player_detected():
						trigger_detection_penalty()
					elif check_out_of_line_of_sight():
						start_retreat_to_spawn()
			else:
				if state_timer <= 0.0:
					start_patrol()

func set_stalker_active(active: bool):
	is_spawned = active
	visible = active
	if collision_shape:
		collision_shape.set_deferred("disabled", not active)
	if not active:
		smooth_velocity = Vector3.ZERO
		velocity = Vector3.ZERO

func force_spawn():
	if not is_spawned:
		start_patrol()

func start_patrol():
	var valid_spawn = find_valid_random_spawn_position()
	exact_spawn_position = valid_spawn
	global_position = valid_spawn
	last_position = valid_spawn
	var random_yaw = randf_range(-PI, PI)
	rotation.y = random_yaw
	target_yaw = random_yaw
	
	set_stalker_active(true)
	current_state = State.PATROL
	state_timer = active_patrol_time
	patrol_pause_timer = 0.0
	pick_new_patrol_target()

func start_retreat_to_spawn():
	current_state = State.COOLDOWN
	var nav_map = get_world_3d().navigation_map
	nav_agent.target_position = NavigationServer3D.map_get_closest_point(nav_map, exact_spawn_position)

func find_valid_random_spawn_position():
	var nav_map = get_world_3d().navigation_map
	var space_state = get_world_3d().direct_space_state
	var best_fallback_pos = fallback_spawn_origin
	var best_fallback_dist = -1.0
	
	for i in range(max_spawn_attempts):
		var rand_x = randf_range(-spawn_area_half_extents.x, spawn_area_half_extents.x)
		var rand_z = randf_range(-spawn_area_half_extents.y, spawn_area_half_extents.y)
		var candidate = Vector3(rand_x, 0.5, rand_z)
		
		var nav_point = NavigationServer3D.map_get_closest_point(nav_map, candidate)
		if Vector2(candidate.x, candidate.z).distance_to(Vector2(nav_point.x, nav_point.z)) > 1.5:
			continue
			
		if player:
			var dist_to_player = nav_point.distance_to(player.global_position)
			if dist_to_player < min_spawn_distance_from_player:
				continue
				
		var floor_query = PhysicsRayQueryParameters3D.create(nav_point + Vector3(0, 0.5, 0), nav_point + Vector3(0, -1.5, 0))
		floor_query.exclude = [self.get_rid()]
		var floor_hit = space_state.intersect_ray(floor_query)
		if floor_hit.is_empty():
			continue
			
		var grounded_pos = floor_hit.position + Vector3(0, 0.05, 0)
		
		if player:
			var d = grounded_pos.distance_to(player.global_position)
			if d > best_fallback_dist:
				best_fallback_dist = d
				best_fallback_pos = grounded_pos
				
		var sphere = SphereShape3D.new()
		sphere.radius = 0.4
		var shape_params = PhysicsShapeQueryParameters3D.new()
		shape_params.shape = sphere
		shape_params.transform = Transform3D(Basis.IDENTITY, grounded_pos + Vector3(0, 0.9, 0))
		shape_params.exclude = [self.get_rid()]
		var collisions = space_state.intersect_shape(shape_params, 1)
		if collisions.is_empty():
			return grounded_pos
			
	return best_fallback_pos

func pick_new_patrol_target():
	var nav_map = get_world_3d().navigation_map
	var random_dir = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized()
	var desired_point = global_position + random_dir * randf_range(8.0, 18.0)
	var valid_point = NavigationServer3D.map_get_closest_point(nav_map, desired_point)
	nav_agent.target_position = valid_point
	stuck_timer = 0.0

func patrol_behavior(delta):
	var stalker_speed = base_player_speed * 0.7
	
	if patrol_pause_timer > 0.0:
		patrol_pause_timer -= delta
		look_around_time += delta
		target_yaw = look_around_base_yaw + sin(look_around_time * 2.2) * deg_to_rad(55.0)
		decelerate_to_stop(delta)
		return
		
	if nav_agent.is_navigation_finished():
		patrol_pause_timer = randf_range(0.8, 1.5)
		look_around_base_yaw = target_yaw
		look_around_time = 0.0
		pick_new_patrol_target()
		return
		
	navigate_smoothly(delta, stalker_speed)
	check_if_stuck(delta)

func chase_behavior(delta):
	var stalker_speed = base_player_speed * 0.7 * 1.15
	
	if check_player_detected():
		last_known_player_position = player.global_position
		var nav_map = get_world_3d().navigation_map
		nav_agent.target_position = NavigationServer3D.map_get_closest_point(nav_map, last_known_player_position)
	else:
		current_state = State.SEARCHING
		search_timer = 3.5
		look_around_base_yaw = target_yaw
		look_around_time = 0.0
		var nav_map = get_world_3d().navigation_map
		nav_agent.target_position = NavigationServer3D.map_get_closest_point(nav_map, last_known_player_position)
		
	navigate_smoothly(delta, stalker_speed)

func searching_behavior(delta):
	var stalker_speed = base_player_speed * 0.7
	
	if nav_agent.is_navigation_finished() or global_position.distance_to(last_known_player_position) < 1.2:
		search_timer -= delta
		look_around_time += delta
		target_yaw = look_around_base_yaw + sin(look_around_time * 3.0) * deg_to_rad(75.0)
		decelerate_to_stop(delta)
		if search_timer <= 0.0:
			current_state = State.PATROL
			pick_new_patrol_target()
	else:
		navigate_smoothly(delta, stalker_speed)

func navigate_smoothly(delta, max_speed):
	nav_agent.max_speed = max_speed
	
	if nav_agent.is_navigation_finished():
		if current_state == State.PATROL:
			pick_new_patrol_target()
		return
		
	var next_path_pos = nav_agent.get_next_path_position()
	var to_next = next_path_pos - global_position
	to_next.y = 0.0
	
	if to_next.length() > 0.05:
		var desired_dir = to_next.normalized()
		target_yaw = atan2(-desired_dir.x, -desired_dir.z)
		
		var current_forward = Vector3(-sin(rotation.y), 0.0, -cos(rotation.y))
		var turn_factor = clamp((current_forward.dot(desired_dir) + 1.0) * 0.5, 0.4, 1.0)
		var intended_velocity = desired_dir * (max_speed * turn_factor)
		
		apply_smooth_movement(intended_velocity, delta)
	else:
		decelerate_to_stop(delta)

func apply_smooth_movement(target_vel: Vector3, delta):
	var vertical_vel = velocity.y
	if not is_on_floor():
		vertical_vel -= 9.8 * delta
	else:
		vertical_vel = 0.0
		
	var target_horizontal = Vector3(target_vel.x, 0.0, target_vel.z)
	var accel_rate = acceleration if target_horizontal.length() > smooth_velocity.length() else deceleration
	
	smooth_velocity = smooth_velocity.lerp(target_horizontal, 1.0 - exp(-accel_rate * delta))
	
	velocity.x = smooth_velocity.x
	velocity.y = vertical_vel
	velocity.z = smooth_velocity.z
	move_and_slide()

func decelerate_to_stop(delta):
	apply_smooth_movement(Vector3.ZERO, delta)

func check_if_stuck(delta):
	if current_state == State.PATROL and global_position.distance_to(last_position) < 0.015:
		stuck_timer += delta
		if stuck_timer > 0.8:
			pick_new_patrol_target()
	else:
		stuck_timer = 0.0
	last_position = global_position

func start_cooldown():
	current_state = State.COOLDOWN
	state_timer = cooldown_time
	if check_out_of_line_of_sight():
		start_retreat_to_spawn()

func cooldown_behavior(delta):
	if check_player_detected():
		trigger_detection_penalty()
		return

	var dist_to_spawn = global_position.distance_to(exact_spawn_position)
	if dist_to_spawn < 1.5 or nav_agent.is_navigation_finished():
		despawn()
	else:
		navigate_smoothly(delta, base_player_speed * 0.7)

func check_player_detected():
	if not player or not is_spawned:
		return false
		
	var to_player = player.global_position - global_position
	var dist = to_player.length()
	
	if dist <= detection_range:
		var forward = Vector3(-sin(rotation.y), 0.0, -cos(rotation.y))
		var dir_to_player = Vector3(to_player.x, 0.0, to_player.z).normalized()
		var angle_deg = rad_to_deg(forward.angle_to(dir_to_player))
		
		if angle_deg <= (field_of_view_degrees * 0.5) or dist <= 4.0:
			var space_state = get_world_3d().direct_space_state
			var from_pos = global_position + Vector3(0, 1.3, 0)
			var to_pos = player.global_position + Vector3(0, 1.0, 0)
			var query = PhysicsRayQueryParameters3D.create(from_pos, to_pos)
			query.exclude = [self.get_rid()]
			var result = space_state.intersect_ray(query)
			if result and (result.collider == player or result.collider.is_in_group("player")):
				return true
	return false

func trigger_detection_penalty():
	if current_state != State.CHASE:
		state_timer = active_patrol_time + detection_penalty
	current_state = State.CHASE
	last_known_player_position = player.global_position

func check_out_of_line_of_sight() -> bool:
	if not player:
		return true
	var space_state = get_world_3d().direct_space_state
	var from_pos = global_position + Vector3(0, 1.3, 0)
	var to_pos = player.global_position + Vector3(0, 1.0, 0)
	var query = PhysicsRayQueryParameters3D.create(from_pos, to_pos)
	query.exclude = [self.get_rid()]
	var result = space_state.intersect_ray(query)
	if result and (result.collider == player or result.collider.is_in_group("player")):
		return false
	return true

func despawn():
	set_stalker_active(false)
	state_timer = cooldown_time
