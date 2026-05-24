extends CharacterBody2D

@export var speed: float = 200.0
@export var fire_rate: float = 0.01
@export var max_health: int = 10
@export var bomb_rate: float = 2

var current_health: int
var fire_timer: float = 0.0
var bomb_timer: float = 0.0
var last_direction: Vector2 = Vector2.RIGHT
var is_holding_bomb: bool = false
var is_holding_shoot: bool = false
var is_holding_bounce: bool = false
var bounce_state: String = "READY"
var bounce_burst_timer: float = 0.0
var bounce_cooldown_timer: float = 0.0
var bounce_rate_timer: float = 0.0
var bounce_fire_rate: float = 0.01 
var locked_bounce_aim: Vector2 = Vector2.ZERO
var is_invincible: bool = false

func _ready() -> void:
	current_health = max_health
	update_health_bar()
# --- THE MASTER TRIGGER SWITCHES ---
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot"):
		is_holding_shoot = true
	elif event.is_action_released("shoot"):
		is_holding_shoot = false
		
	if event.is_action_pressed("bomb"):
		is_holding_bomb = true
	elif event.is_action_released("bomb"):
		is_holding_bomb = false
		
	# 3. Bounce Bullet Switch
	if event.is_action_pressed("bounce"):
		is_holding_bounce = true
		# WE DELETED THE RESET LINE HERE!
	elif event.is_action_released("bounce"):
		is_holding_bounce = false
# --- THE MASTER PHYSICS & SHOOTING LOOP ---
func _physics_process(delta: float) -> void:
	# --- 1. MOVEMENT ---
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if bounce_state == "FIRING":
		velocity = Vector2.ZERO
	else:
		velocity = direction * speed
		if direction != Vector2.ZERO:
			last_direction = direction.normalized()
			
	move_and_slide()
	global_position.x = clamp(global_position.x, 0, 320)
	global_position.y = clamp(global_position.y, 0, 180)

	# --- 2. TIMER TICK-DOWN ---
	if fire_timer > 0.0: fire_timer -= delta
	if bomb_timer > 0.0: bomb_timer -= delta
	
	# --- 3. NORMAL WEAPONS (Only if not firing the heavy stream) ---
	if bounce_state != "FIRING":
		if is_holding_shoot and fire_timer <= 0.0:
			shoot_bullet()
			fire_timer = fire_rate
			
		if is_holding_bomb and bomb_timer <= 0.0:
			shoot_bomb()
			# Timer is reset inside shoot_bomb(), but we reset here for safety
			bomb_timer = bomb_rate
			
	# --- 4. BOUNCE WEAPON STATE MACHINE ---
	if bounce_state == "READY":
		if is_holding_bounce:
			bounce_state = "FIRING"
			bounce_burst_timer = 0.8
			bounce_rate_timer = 0.0
			locked_bounce_aim = last_direction
			
			var active_enemies = get_tree().get_nodes_in_group("enemies")
			if active_enemies.size() > 0:
				var closest_enemy = active_enemies[0]
				var min_dist = global_position.distance_to(closest_enemy.global_position)
				for e in active_enemies:
					var dist = global_position.distance_to(e.global_position)
					if dist < min_dist:
						min_dist = dist
						closest_enemy = e
				locked_bounce_aim = global_position.direction_to(closest_enemy.global_position)

	elif bounce_state == "FIRING":
		bounce_burst_timer -= delta
		bounce_rate_timer -= delta
		if bounce_rate_timer <= 0.0:
			shoot_bounce()
			bounce_rate_timer += bounce_fire_rate
			
		if bounce_burst_timer <= 0.0:
			bounce_state = "COOLDOWN"
			bounce_cooldown_timer = 0.4
			
	elif bounce_state == "COOLDOWN":
		bounce_cooldown_timer -= delta
		if bounce_cooldown_timer <= 0.0:
			if not is_holding_bounce:
				bounce_state = "READY"

	# --- 5. UI UPDATES (The very last thing!) ---
	# Update Burst Bar
	if has_node("BurstBar"):
		if bounce_state == "FIRING":
			get_node("BurstBar").show()
			get_node("BurstBar").value = bounce_burst_timer
		else:
			get_node("BurstBar").hide()
			
	if has_node("BurstLabel"):
		if bounce_state == "FIRING":
			get_node("BurstLabel").show()
			get_node("BurstLabel").text = "%0.1f" % bounce_burst_timer + "s"
		else:
			get_node("BurstLabel").hide()

	# Update Bomb Bar
	if has_node("BombReloadBar"):
		update_bomb_ui()
func shoot_bullet() -> void:
	if get_parent().has_node("bullet"):
		var template = get_parent().get_node("bullet")
		var base_direction = last_direction
		
		var active_enemies = get_tree().get_nodes_in_group("enemies")
		if active_enemies.size() > 0:
			var closest_enemy = active_enemies[0]
			var min_dist = global_position.distance_to(closest_enemy.global_position)
			for e in active_enemies:
				var dist = global_position.distance_to(e.global_position)
				if dist < min_dist:
					min_dist = dist
					closest_enemy = e
			base_direction = global_position.direction_to(closest_enemy.global_position)
		
		var angles_in_degrees = [-10.0, 0.0, 10.0]
		for angle in angles_in_degrees:
			var new_bullet = template.duplicate()
			var final_direction = base_direction.rotated(deg_to_rad(angle))
			
			new_bullet.position = self.position + (final_direction * 12.0)
			new_bullet.show()
			new_bullet.process_mode = Node.PROCESS_MODE_INHERIT
			new_bullet.rotation = final_direction.angle()
			new_bullet.direction = final_direction
			get_parent().add_child(new_bullet)
func shoot_bounce() -> void:
	if get_parent().has_node("bounce_bullet"):
		var template = get_parent().get_node("bounce_bullet")
		var new_bullet = template.duplicate()
		
		# FIX 2: Only ONE block of shooting code!
		new_bullet.global_position = self.global_position + (locked_bounce_aim * 5.0)
		new_bullet.show()
		new_bullet.process_mode = Node.PROCESS_MODE_INHERIT
		
		new_bullet.rotation = locked_bounce_aim.angle() 
		new_bullet.direction = locked_bounce_aim
		get_parent().add_child(new_bullet)
func shoot_bomb() -> void:
	# 1. Check if the template exists in the scene
	if not get_parent().has_node("bomb"):
		print("Error: Bomb template not found in parent!")
		return
		
	# 2. Get the template and duplicate it
	var template = get_parent().get_node("bomb")
	var new_bomb = template.duplicate()
	
	# 3. Configure the bomb (Force visibility and Z-index)
	new_bomb.show()
	new_bomb.modulate.a = 1.0
	new_bomb.z_index = 10 
	new_bomb.process_mode = Node.PROCESS_MODE_INHERIT
	
	# --- NEW: FORCE THE SPRITE ITSELF TO BE VISIBLE ---
	if new_bomb.has_node("Sprite2D"):
		new_bomb.get_node("Sprite2D").show()
		new_bomb.get_node("Sprite2D").modulate.a = 1.0
	# 4. Math: Set the direction and position
	var target_direction = last_direction
	var active_enemies = get_tree().get_nodes_in_group("enemies")
	
	if active_enemies.size() > 0:
		var closest_enemy = active_enemies[0]
		var min_dist = global_position.distance_to(closest_enemy.global_position)
		for e in active_enemies:
			var dist = global_position.distance_to(e.global_position)
			if dist < min_dist:
				min_dist = dist
				closest_enemy = e
		target_direction = global_position.direction_to(closest_enemy.global_position)
		
	new_bomb.global_position = self.global_position + (target_direction * 16.0)
	new_bomb.direction = target_direction
	
	# 5. Add to scene and set cooldown
	get_parent().call_deferred("add_child", new_bomb)
	
	bomb_timer = bomb_rate
	update_bomb_ui()
	
	print("Bomb successfully spawned!")
func take_damage(amount: int) -> void:
	if is_invincible == true:
		return
	current_health -= amount
	update_health_bar()
	if current_health <= 0:
		get_tree().reload_current_scene()
	else:
		start_flashing()
func start_flashing() -> void:
	is_invincible = true
	if has_node("Sprite2D") and has_node("damaged"):
		var normal_sprite = get_node("Sprite2D")
		var damaged_sprite = get_node("damaged")
		var tween = create_tween()
		
		for i in range(5):
			tween.tween_callback(func():
				normal_sprite.hide()
				damaged_sprite.show()
			)
			tween.tween_interval(0.1)
			
			tween.tween_callback(func():
				damaged_sprite.hide()
				normal_sprite.show()
			)
			tween.tween_interval(0.1)
			
		tween.tween_callback(func():
			normal_sprite.hide()
			damaged_sprite.show()
		)
		tween.tween_interval(0.4)
		
		tween.tween_callback(func():
			damaged_sprite.hide()
			normal_sprite.show()
			is_invincible = false
		)
func update_health_bar() -> void:
	
	if has_node("PlayerHealthBar"):
		var health_bar = get_node("PlayerHealthBar") as ProgressBar
		health_bar.max_value = max_health
		health_bar.value = current_health
func update_bomb_ui() -> void:
	if has_node("BombReloadBar"):
		var bar = get_node("BombReloadBar") as ProgressBar
		# If bomb_timer is 1.0 (reloading), and bomb_rate is 1.0:
		# 1.0 - 1.0 = 0 (Empty)
		# When bomb_timer hits 0.0:
		# 1.0 - 0.0 = 1.0 (Full)
		bar.value = bomb_rate - bomb_timer
