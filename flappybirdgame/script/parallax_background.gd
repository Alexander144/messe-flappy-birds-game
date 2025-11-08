extends ParallaxBackground

@export var scroll_speed: float = 100.0

func _ready() -> void:
	# Get the ParallaxLayer
	var layer = get_child(0) as ParallaxLayer
	if layer:
		print("Found ParallaxLayer: ", layer.name)

func _process(delta: float) -> void:
	# Move each ParallaxLayer directly
	for child in get_children():
		if child is ParallaxLayer:
			var sprite = child.get_child(0) as Sprite2D
			if sprite:
				sprite.position.x -= scroll_speed * delta
				
				# Reset position when it scrolls too far
				if sprite.position.x < -7081:
					sprite.position.x += 7081
				
	
