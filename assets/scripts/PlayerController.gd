# Camera Controls
extends Node3D

# Children
@onready var CAMERA := $PlayerCameraView
@onready var CAST_FORWARD := $CastForward
@onready var CAST_LEFT := $CastLeft
@onready var CAST_RIGHT := $CastRight
@onready var CAST_BACKWARDS := $CastBackwards
@onready var COMBAT_COMPONENT := $CombatComponent
@onready var FX_PLAYER: AudioStreamPlayer = $FXPlayer

# Constant Scalar Values
@export var GRID_SCALE = 2 # Factor for movement; constrains grid
@export var ROTATE_SCALE = PI/2 # Factor for rotation; constrains grid
@export var TWEEN_FACTOR = 0.3 # Affects camera interpolation speed
@export var REVIVE_LIFE: int # Health player will come back with

# Signals
signal turn_end
signal popup_interact
signal popup_close
signal portal_transition
signal restore_health
signal restore_focus
signal prompt_text_overlay
signal artifact_pickup
signal game_over

var fighter_is_active: bool = false
var mage_is_active: bool = false
var rouge_is_active: bool = false
var paladin_is_active: bool = false
var fighter_has_attacked: bool = false
var rouge_has_attacked: bool = false
var mage_has_attacked: bool = false
var paladin_has_attacked: bool = false

var tokens: int

var is_on_turn: bool
var has_moved: bool = false
var looking_at_popup: bool = false
var last_door_location: Vector3i

# Tweens
var motion_tween

func _ready():
	add_to_group("Player")
	last_door_location = position
	REVIVE_LIFE = 75

# returns true if persona has attacked when it needs to, or if mage is inactive
# else remove false
func if_mage_is_ready():
	if mage_is_active and mage_has_attacked:
		return true
	elif not mage_is_active:
		return true
	else:
		return false

# returns true if persona has attacked when it needs to, or if mage is inactive
# else remove false
func if_fighter_is_ready():
	if fighter_is_active and fighter_has_attacked:
		return true
	elif not fighter_is_active:
		return true
	else:
		return false

# returns true if persona has attacked when it needs to, or if mage is inactive
# else remove false
func if_rouge_is_ready():
	if rouge_is_active and rouge_has_attacked:
		return true
	elif not rouge_is_active:
		return true
	else:
		return false

# returns true if persona has attacked when it needs to, or if mage is inactive
# else remove false
func if_paladin_is_ready():
	if paladin_is_active and paladin_has_attacked:
		return true
	elif not paladin_is_active:
		return true
	else:
		return false

func _process(_delta):
	if has_moved or (if_mage_is_ready() and if_fighter_is_ready() and if_paladin_is_ready() and if_rouge_is_ready()):
		on_turn_end()
	if CAST_FORWARD.is_colliding() and CAST_FORWARD.get_collider().is_in_group("Portals"):
		emit_signal("popup_interact", "Interact [F] to continue forward...")
		looking_at_popup = true
	elif CAST_FORWARD.is_colliding() and CAST_FORWARD.get_collider().is_in_group("IceMachines"):
		emit_signal("popup_interact", "Some Ice would really help me focus... [F]")
		looking_at_popup = true
	elif CAST_FORWARD.is_colliding() and CAST_FORWARD.get_collider().is_in_group("SodaMachines"):
		emit_signal("popup_interact", "Soda is healthy... right? [F]")
		looking_at_popup = true
	elif $Area.has_overlapping_areas() and $Area.get_overlapping_areas()[0].get_parent().is_in_group("Artifacts"):
		$PickupFxPlayer.on_collect()
		emit_signal("artifact_pickup", $Area.get_overlapping_areas()[0].get_parent().identity)
		$Area.get_overlapping_areas()[0].get_parent().queue_free()
	elif $Area.has_overlapping_areas() and $Area.get_overlapping_areas()[0].get_parent().is_in_group("Coins"):
		$PickupFxPlayer.on_collect()
		tokens += 1
		$Area.get_overlapping_areas()[0].get_parent().queue_free()
	
	elif looking_at_popup == true:
		emit_signal("popup_close")
		looking_at_popup = false
		
	if COMBAT_COMPONENT.health == 0:	
		emit_signal("prompt_text_overlay", "You Died?...", 2)
		position = last_door_location
		COMBAT_COMPONENT.health = REVIVE_LIFE

func _input(event):
	if is_on_turn:
		player_move(event)
		# Portals
		if event.is_action_pressed("Interact") and CAST_FORWARD.is_colliding() and CAST_FORWARD.get_collider().is_in_group("Portals"):
			emit_signal("popup_close")
			CAST_FORWARD.get_collider().warp(self)
			portal_transitionals()
			emit_signal("portal_transition")
		# Ice Machine
		if tokens > 0 and event.is_action_pressed("Interact") and CAST_FORWARD.is_colliding() and CAST_FORWARD.get_collider().is_in_group("IceMachines"):
			emit_signal("popup_close")
			$PickupFxPlayer.on_collect()
			COMBAT_COMPONENT.restore_focus()
			emit_signal("restore_focus")
			tokens -= 1
		# Soda Machine
		if tokens > 0 and event.is_action_pressed("Interact") and CAST_FORWARD.is_colliding() and CAST_FORWARD.get_collider().is_in_group("SodaMachines"):
			emit_signal("popup_close")
			$PickupFxPlayer.on_collect()
			COMBAT_COMPONENT.restore_health()
			emit_signal("restore_health")
			tokens -= 1

func _on_fighter_attack():
	if fighter_is_active == true and fighter_has_attacked == false and CAST_FORWARD.is_colliding() and CAST_FORWARD.get_collider().get_parent().get_parent().name == "UnitController":
		FX_PLAYER.on_attack_fx()
		COMBAT_COMPONENT.fighter_attack(CAST_FORWARD.get_collider().get_parent().find_child("CombatComponent"))
		fighter_has_attacked = true

func _on_rouge_attack():
	if rouge_is_active == true and rouge_has_attacked == false and CAST_FORWARD.is_colliding() and CAST_FORWARD.get_collider().get_parent().get_parent().name == "UnitController":
		FX_PLAYER.on_attack_fx()
		COMBAT_COMPONENT.rouge_attack(CAST_FORWARD.get_collider().get_parent().find_child("CombatComponent"))
		rouge_has_attacked = true

func _on_mage_attack():
	if mage_is_active == true and mage_has_attacked == false and CAST_FORWARD.is_colliding() and CAST_FORWARD.get_collider().get_parent().get_parent().name == "UnitController":
		FX_PLAYER.on_attack_fx()
		COMBAT_COMPONENT.mage_attack(CAST_FORWARD.get_collider().get_parent().find_child("CombatComponent"))
		mage_has_attacked = true

func _on_paladin_attack():
	if paladin_is_active == true and paladin_has_attacked == false and CAST_FORWARD.is_colliding() and CAST_FORWARD.get_collider().get_parent().get_parent().name == "UnitController":
		FX_PLAYER.on_attack_fx()
		COMBAT_COMPONENT.paladin_attack(CAST_FORWARD.get_collider().get_parent().find_child("CombatComponent"))
		paladin_has_attacked = true

func _on_fighter_focus_attack():
	if fighter_is_active == true and CAST_FORWARD.is_colliding() and CAST_FORWARD.get_collider().get_parent().get_parent().name == "UnitController":
		FX_PLAYER.on_attack_fx()
		COMBAT_COMPONENT.fighter_focus_attack(CAST_FORWARD.get_collider().get_parent().find_child("CombatComponent"))

func _on_rouge_focus_attack():
	if rouge_is_active == true and rouge_has_attacked == false and CAST_FORWARD.is_colliding() and CAST_FORWARD.get_collider().get_parent().get_parent().name == "UnitController":
		FX_PLAYER.on_attack_fx()
		COMBAT_COMPONENT.rouge_focus_attack(CAST_FORWARD.get_collider().get_parent().find_child("CombatComponent"))
		rouge_has_attacked = true

func _on_mage_focus_attack():
	if mage_is_active == true and mage_has_attacked == false and CAST_FORWARD.is_colliding() and CAST_FORWARD.get_collider().get_parent().get_parent().name == "UnitController":
		FX_PLAYER.on_attack_fx()
		COMBAT_COMPONENT.mage_focus_attack(CAST_FORWARD.get_collider().get_parent().find_child("CombatComponent"))
		if CAST_BACKWARDS.is_colliding() and CAST_BACKWARDS.get_collider().get_parent().find_child("CombatComponent") != null and CAST_BACKWARDS.get_collider().get_parent().is_in_group("Enemies"):
			COMBAT_COMPONENT.mage_focus_attack(CAST_BACKWARDS.get_collider().get_parent().find_child("CombatComponent"))
		if CAST_LEFT.is_colliding() and CAST_LEFT.get_collider().get_parent().find_child("CombatComponent") != null and CAST_LEFT.get_collider().get_parent().is_in_group("Enemies"):
			COMBAT_COMPONENT.mage_focus_attack(CAST_LEFT.get_collider().get_parent().find_child("CombatComponent"))
		if CAST_RIGHT.is_colliding() and CAST_RIGHT.get_collider().get_parent().find_child("CombatComponent") != null and CAST_RIGHT.get_collider().get_parent().is_in_group("Enemies"):
			COMBAT_COMPONENT.mage_focus_attack(CAST_RIGHT.get_collider().get_parent().find_child("CombatComponent"))
		COMBAT_COMPONENT.mage_focus -= 1 # Making an exception here for mage atk
		mage_has_attacked = true

func _on_paladin_focus_attack():
	if paladin_is_active == true and paladin_has_attacked == false and CAST_FORWARD.is_colliding() and CAST_FORWARD.get_collider().get_parent().get_parent().name == "UnitController":
		COMBAT_COMPONENT.paladin_focus_attack(CAST_FORWARD.get_collider().get_parent().find_child("CombatComponent"))
		paladin_has_attacked = true

func _on_attack_all_pressed():
	_on_fighter_attack()
	_on_rouge_attack()
	_on_paladin_attack()
	_on_mage_attack()

func player_move(event):
	if motion_tween is Tween: # Halt another tween if one is running
		if motion_tween.is_running():
			return
	# Tween forwards
	if event.is_action_pressed("Move_Forward") and not CAST_FORWARD.is_colliding():
		motion_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		motion_tween.tween_property(self, "transform", transform.translated(CAMERA.get_global_transform().basis.z * -1 * GRID_SCALE), TWEEN_FACTOR)
		await motion_tween.finished
		has_moved = true
	elif event.is_action_pressed("Move_Forward") and CAST_FORWARD.is_colliding():
		FX_PLAYER.on_wall_collide()
	# Tween backwards
	elif event.is_action_pressed("Move_Back") and not CAST_BACKWARDS.is_colliding():
		motion_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		motion_tween.tween_property(self, "transform", transform.translated(CAMERA.get_global_transform().basis.z * 1 * GRID_SCALE), TWEEN_FACTOR)
		await motion_tween.finished
		has_moved = true
	elif event.is_action_pressed("Move_Back") and CAST_BACKWARDS.is_colliding():
		FX_PLAYER.on_wall_collide()
	elif event.is_action_pressed("Move_Left") and not CAST_LEFT.is_colliding():
		motion_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		motion_tween.tween_property(self, "transform", transform.translated(CAMERA.get_global_transform().basis.x * -1 * GRID_SCALE), TWEEN_FACTOR)
		await motion_tween.finished
		has_moved = true
	elif event.is_action_pressed("Move_Left") and CAST_LEFT.is_colliding():
		FX_PLAYER.on_wall_collide()
	elif event.is_action_pressed("Move_Right") and not CAST_RIGHT.is_colliding():
		motion_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		motion_tween.tween_property(self, "transform", transform.translated(CAMERA.get_global_transform().basis.x * 1 * GRID_SCALE), TWEEN_FACTOR)
		await motion_tween.finished
		has_moved = true
	elif event.is_action_pressed("Move_Right") and CAST_RIGHT.is_colliding():
		FX_PLAYER.on_wall_collide()
	# Tween rotate left
	if event.is_action_pressed("Rotate_Left"):
		motion_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		motion_tween.tween_property(self, "transform:basis", transform.basis.rotated(Vector3.UP, ROTATE_SCALE), TWEEN_FACTOR)
	# Tween rotate right
	elif event.is_action_pressed("Rotate_Right"):
		motion_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		motion_tween.tween_property(self, "transform:basis", transform.basis.rotated(Vector3.UP, -1 * ROTATE_SCALE), TWEEN_FACTOR)

func _on_player_turn():
	is_on_turn = true

func on_turn_end():
	is_on_turn = false
	fighter_has_attacked = false
	rouge_has_attacked = false
	mage_has_attacked = false
	paladin_has_attacked = false
	has_moved = false
	emit_signal("turn_end")

func _on_skip_turn_pressed():
	on_turn_end()
# Change state to reflect a portal transition
func portal_transitionals():
	last_door_location = position
	fighter_is_active = false
	rouge_is_active = false
	paladin_is_active = false
	mage_is_active = false
