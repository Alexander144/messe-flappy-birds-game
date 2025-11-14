extends Node2D

# Export the 3 spark sprites so they can be assigned in the editor
@export var spark1: Sprite2D
@export var spark2: Sprite2D
@export var spark3: Sprite2D

# Spark effect settings
@export var spark_duration_min: float = 0.05
@export var spark_duration_max: float = 0.15
@export var spark_interval_min: float = 0.1
@export var spark_interval_max: float = 0.4
@export var spark_enabled: bool = true

var active_sparks: Array[Sprite2D] = []
var spark_timers: Dictionary = {}

func _ready() -> void:
	# Initialize all sparks as hidden
	if spark1:
		spark1.visible = false
		active_sparks.append(spark1)
	if spark2:
		spark2.visible = false
		active_sparks.append(spark2)
	if spark3:
		spark3.visible = false
		active_sparks.append(spark3)
	
	# Start the sparking effect
	if spark_enabled:
		_start_random_spark()

func _start_random_spark() -> void:
	if not spark_enabled or active_sparks.is_empty():
		return
	
	# Pick a random spark
	var spark = active_sparks.pick_random()
	
	# Show the spark
	spark.visible = true
	
	# Random duration for this spark
	var duration = randf_range(spark_duration_min, spark_duration_max)
	
	# Hide after duration
	await get_tree().create_timer(duration).timeout
	if spark:
		spark.visible = false
	
	# Wait random interval before next spark
	var interval = randf_range(spark_interval_min, spark_interval_max)
	await get_tree().create_timer(interval).timeout
	
	# Trigger next spark
	_start_random_spark()

func start_sparking() -> void:
	spark_enabled = true
	_start_random_spark()

func stop_sparking() -> void:
	spark_enabled = false
	# Hide all sparks
	for spark in active_sparks:
		if spark:
			spark.visible = false
