extends Node2D

@onready var shard_1: Polygon2D = $Shard1
@onready var shard_2: Polygon2D = $Shard2
@onready var shard_3: Polygon2D = $Shard3
@onready var shard_4: Polygon2D = $Shard4
@onready var shard_5: Polygon2D = $Shard5
@onready var shard_6: Polygon2D = $Shard6

func _ready() -> void:
	SignalBus.madness_level_changed.connect(_on_madness_level_changed)

func _on_madness_level_changed(level: int) -> void:
	shard_1.visible = level >= 1
	shard_2.visible = level >= 2
	shard_3.visible = level >= 3
	shard_4.visible = level >= 4
	shard_5.visible = level >= 5
	shard_6.visible = level >= 6
