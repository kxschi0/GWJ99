extends Node3D

var player: CharacterBody3D
var monster: CharacterBody3D
var trigger_area: Area3D

func _ready():
	if not player:
		player = get_node_or_null("player")
	if not monster:
		monster = get_node_or_null("monster")
	if not trigger_area:
		trigger_area = get_node_or_null("monster_or_puzzle_trigger")

	if trigger_area:
		if not trigger_area.is_connected("body_entered", _on_trigger_body_entered):
			trigger_area.body_entered.connect(_on_trigger_body_entered)
		if not trigger_area.is_connected("area_entered", _on_trigger_area_entered):
			trigger_area.area_entered.connect(_on_trigger_area_entered)
		print("Trigger sikeresen bekötve a Main scriptbe!")

func _on_trigger_body_entered(body: Node3D):
	if body == player or (body and body.is_in_group("player")):
		spawn_monster()

func _on_trigger_area_entered(area: Node3D):
	if area == player or (area and area.is_in_group("player")) or (area and area.get_parent() == player):
		spawn_monster()

func spawn_monster():
	if monster:
		if monster.has_method("force_spawn"):
			monster.force_spawn()
