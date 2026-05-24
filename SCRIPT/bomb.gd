extends Area2D

@export var speed: float = 120.0 
var direction: Vector2 = Vector2.ZERO
var fuse_timer: float = 1.0 
var has_exploded: bool = false
# Explosion Radar Variables
var current_blast_radius: float = 0.0
var hit_enemies: Array = [] 
var is_exploding: bool = false
var explosion_lifespan: float = 2.0 
# Shrapnel Sync Variables
var wave_speed: float = 400.0 
var wave_min_speed: float = 100.0 
var wave_friction: float = 800.0

func _ready() -> void:
	area_entered.connect(_on_hit_something)
func _process(delta: float) -> void:
	if direction == Vector2.ZERO and not is_exploding:
		return 
		
	# 1. Normal Movement (Before Explosion)
	if not is_exploding:
		global_position += direction * speed * delta
		fuse_timer -= delta
		if fuse_timer <= 0.0:
			explode()
			
	# 2. Radar Expansion & Damage (During Explosion)
	if is_exploding:
		explosion_lifespan -= delta
		if explosion_lifespan <= 0.0:
			queue_free()
			return
			
		wave_speed = move_toward(wave_speed, wave_min_speed, wave_friction * delta)
		current_blast_radius += wave_speed * delta
		
		var all_enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in all_enemies:
			if enemy not in hit_enemies:
				var dist = global_position.distance_to(enemy.global_position)
				
				if dist <= current_blast_radius:
					hit_enemies.append(enemy) 
			
					if enemy.has_method("take_damage"):
						enemy.take_damage(2) 
						
					if enemy.has_method("apply_knockback"):
						var push_dir = global_position.direction_to(enemy.global_position)
						enemy.apply_knockback(push_dir, 350.0)
func _on_hit_something(area: Area2D) -> void:
	if area.is_in_group("enemies") and not is_exploding:
		explode()
func explode() -> void:
	if has_exploded:
		return
	has_exploded = true 
	
	# Safely disable collision during physics processing
	if has_node("CollisionShape2D"):
		get_node("CollisionShape2D").set_deferred("disabled", true)
	
	direction = Vector2.ZERO
	if has_node("Sprite2D"):
		get_node("Sprite2D").hide()

	# Spawn 144 shrapnel projectiles in a perfect ring
	if get_parent().has_node("bullet2"):
		var bullet2_template = get_parent().get_node("bullet2")
		bullet2_template.hide() 
		bullet2_template.process_mode = Node.PROCESS_MODE_DISABLED
		
		var base_angle = randf_range(0.0, TAU) 
		var angle_step = TAU / 144.0 
		
		for i in range(144):
			var shrapnel = bullet2_template.duplicate() 
			var current_angle = base_angle + (i * angle_step)
			var current_dir = Vector2(cos(current_angle), sin(current_angle))
			
			shrapnel.rotation = current_angle
			shrapnel.set("direction", current_dir)
			shrapnel.global_position = self.global_position
			
			shrapnel.show()
			shrapnel.process_mode = Node.PROCESS_MODE_INHERIT
			shrapnel.z_index = 10 
			
			if shrapnel.has_node("Sprite2D"):
				shrapnel.get_node("Sprite2D").show()
				shrapnel.get_node("Sprite2D").modulate.a = 1.0
			
			get_tree().current_scene.call_deferred("add_child", shrapnel)

	is_exploding = true
