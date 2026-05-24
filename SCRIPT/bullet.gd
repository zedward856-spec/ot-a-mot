extends Area2D

@export var speed: float = 200.0
var direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	# 1. Wire up the collision sensor instantly via code!
	area_entered.connect(_on_hit_something)
func _process(delta: float) -> void:
	# --- THE TEMPLATE LOCK ---
	if direction == Vector2.ZERO:
		return
		
	global_position += direction * speed * delta
		
	if global_position.x < -50 or global_position.x > 370 or global_position.y < -50 or global_position.y > 230:
		queue_free()
# 2. This triggers the exact microsecond the bullet touches another Area2D box
func _on_hit_something(area: Area2D) -> void:
	# Check if the object belongs to our dynamic enemy group
	if area.is_in_group("enemies"):
		if area.has_method("take_damage"):
			area.take_damage(1)
		queue_free()
