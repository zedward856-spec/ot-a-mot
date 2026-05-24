extends Area2D

@export var speed: float = 400.0 
@export var minimum_speed: float = 100.0 
@export var friction: float = 800.0 

var direction: Vector2 = Vector2.ZERO
var lifespan: float = 2.0 

func _ready() -> void:
	# --- REACTIVATED: Tells the shrapnel to listen for collisions! ---
	area_entered.connect(_on_hit_something)
func _process(delta: float) -> void:
	if direction == Vector2.ZERO:
		return 
		
	lifespan -= delta
	if lifespan <= 0.0:
		queue_free()
		return 
		
	speed = move_toward(speed, minimum_speed, friction * delta)
	global_position += direction * speed * delta
# --- REACTIVATED: The Piercing Damage Math ---
func _on_hit_something(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		if area.has_method("take_damage"):
			area.take_damage(1) # Shrapnel deals 1 damage
			
		if area.has_method("apply_knockback"):
			var push_dir = global_position.direction_to(area.global_position)
			area.apply_knockback(push_dir, 200.0) # Light knockback
			
		# Notice there is no queue_free() here! 
		# It will pierce right through them and keep flying.
