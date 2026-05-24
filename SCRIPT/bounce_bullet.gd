extends Area2D

@export var speed: float = 250.0 
@export var damage: int = 10

var direction: Vector2 = Vector2.ZERO
# Fade & Bounce Variables
var lifespan: float = 4.0 
var max_lifespan: float = 4.0 

func _ready() -> void:
	area_entered.connect(_on_hit_something)
func _process(delta: float) -> void:
	if direction == Vector2.ZERO:
		return 
		
	# 1. Movement
	global_position += direction * speed * delta
	
	# 2. Bounce Math (320x180 Screen)
	var bounced := false
	
	if global_position.x <= 0 or global_position.x >= 320:
		global_position.x = clamp(global_position.x, 0, 320)
		direction.x *= -1
		bounced = true
		
	if global_position.y <= 0 or global_position.y >= 180:
		global_position.y = clamp(global_position.y, 0, 180)
		direction.y *= -1
		bounced = true
		
	if bounced:
		rotation = direction.angle()
		
	# 3. Slow Fade Out
	lifespan -= delta
	modulate.a = max(0.0, lifespan / max_lifespan)
	
	if lifespan <= 0.0:
		queue_free()
func _on_hit_something(area: Area2D) -> void:
	if area.is_in_group("enemies") and area.has_method("take_damage"):
		area.take_damage(damage)
