#==============================================================================
#    Pear Battle System
#    Version: 1.0.0
#    Author: pearcoding
#    Date: 12.08.2015
#==============================================================================
#
# Implements an active time battle system with grid based battle and combat.
# Allows even repositioning of enemies and actors.
# Animation and Movies are included by cast aswell.
# A huge packet of awesomness.
#
# Inspired by: Chrono Trigger [Awesome game - check it out!]
#
# -----------------------------------------------------------------------------
# Script order: (Please use this order, and nothing else!)
# 
# - Config
# - Core
# - Active Time Battle
# - (Weather)
# - Animation
# - (GUI)
#
# -----------------------------------------------------------------------------
# Notetags:
#
# Only actor:
# <battle name: str>			Name of the battle sprite used in battles.
#													Default: Name of actor
#
# <battle hue: number>		Hue changes of the battle sprite.
#													Default: 0
#
# Only actor/enemy:
# <battle boundary: w h>	Will make the character appear as wxh sized structure
# 												Be sure to count in grids.
#													Default: 1 1
#
# <battle stand: id>		  Animation while standing or idle.
#													Default: 1
#
# <battle move: id>				Animation while moving towards the target.
#													Default: 2
#
# <battle damage: id>			Animation while getting damage/hurt.
#													Default: 3
#
# <battle weak: id>				Animation while being weak. eg. HP < 25%
#													Default: 4
#
# <battle dead: id>				Animation while passing away. Frame 3 will be frozen.
#													Default: 5
#
# <battle victory: id>		Animation while winning and victory screen shows.
#													Default: 6
#
# Only skill/item:
# <battle avl: cost>			Cost to cast skill/item. 'cost' is between 0 and 100.
#													Default: 100
#
# Only skill/item/actor/enemy:
# <battle cast: id>				Animation while casting skills or
#												 	(in actor/enemy) while normal attacking.
#													Default: 7 (actor/enemy)
#																	 0 (skill/item) [disabled]
#
# <battle movie: name>		Plays a movie before casting ability/skill.
#
# Only state:
# <battle effect: id>			Animation while in status. Based on priority.
#													'id' is the number from the animation tab!
#													Default: 0 [disabled]
#
# Only troop (in event page as comment [span = battle]):
# <battle enemy pos: nr; x, y>	Enemy 'nr' x,y position in the grid at start.
#
# <battle ally pos: nr; x, y>		Ally 'nr' x,y position in the grid at start.
#
# id = 0 means disabled.
#
# -----------------------------------------------------------------------------
# Default animation sheet:
# 	[7x3] [Should be left sized, will be mirrored if needed]
#   Rows are the ids. Every row consists of 3 frames each.
#
# 1. Stand/Idle
# 2. Move
# 3. Damage/When hit
# 4. Weak/HP critical
# 5. Dead
# 6. Victory
# 7. Basic Attack
# 8-n. Skill casts/User defined
#
# -----------------------------------------------------------------------------
# Code Documentation:
#
#   Function: * := New definition
#							+ := Alias/Improvement
#             ~ := Replacement
#

$imported = {} if $imported.nil?
$imported["Pear_BattleSystem"] = 1.0

$bs_module = {} if $bs_module.nil?
$bs_module["Config"] = true

#==============================================================================
# ◆ Configuration
#==============================================================================
module Pear
	module BattleSystem
		#--------------------------------------------------------------------------
		# Module
		#--------------------------------------------------------------------------
		USE_ACTIVE_TIME_BATTLE_MODULE = true
		USE_ANIMATION_MODULE 					= true
		USE_GUI_MODULE								= true
		
		#--------------------------------------------------------------------------
		# Core
		#--------------------------------------------------------------------------
		HP_WEAK	= 25 # in percent
		MP_WEAK	= 25 # in percent
		
		PARTY_SIZE = 8
		
		#--------------------------------------------------------------------------
		# Active Time Battle
		#--------------------------------------------------------------------------
		MAX_AGI		= 500
		
		MAX_AVL							= 100
		MAX_AVL_PER_STEP		= 20
		AVL_UPDATE_RATE 		= 2					# Update avl every second frame
		DEFAULT_BATTLE_AVL 	= MAX_AVL	
		
		#--------------------------------------------------------------------------
		# GUI
		#--------------------------------------------------------------------------
		STATUS_WINDOW_OFF_X 	= 0
		STATUS_WINDOW_OFF_Y 	= 0
		STATUS_WINDOW_HEIGHT 	= 100
		
		SHOW_AVL 	= true
		
		#--------------------------------------------------------------------------
		# Grid
		#--------------------------------------------------------------------------
		GRID_WIDTH 	= 20
		GRID_HEIGHT = 15
		
		# Can be grid size
		GRID_TO_PX_X_FACTOR = 32
		GRID_TO_PX_Y_FACTOR = 32
		GRID_Y_OFFSET				= 32 #Based on the status window height!
		
		#--------------------------------------------------------------------------
		# Default animations
		#--------------------------------------------------------------------------
		
		DEFAULT_BATTLE_BOUNDARY 	= [1, 1]
		DEFAULT_BATTLE_STAND			= 1
		DEFAULT_BATTLE_MOVE				= 2
		DEFAULT_BATTLE_DAMAGE			=	3
		DEFAULT_BATTLE_WEAK				= 4
		DEFAULT_BATTLE_DEAD				= 5
		DEFAULT_BATTLE_VICTORY		= 6
		DEFAULT_BATTLE_CAST_ACTOR	= 7 #Enemy aswell
		DEFAULT_BATTLE_CAST_SKILL	= 0 #Item aswell
		DEFAULT_BATTLE_MOVIE			= nil
		DEFAULT_BATTLE_EFFECT			= 0
		
		#--------------------------------------------------------------------------
		# Animation sheet
		#--------------------------------------------------------------------------
		
		DEFAULT_ANIMATION_RATE = 15
		
		DEFAULT_ANIMATION_SHEET = [
			#Frames, Loop?, Rate? (-1 = Default), Frame Start (index starts with 0)
			{:count => 2, :loop => true, :rate => -1, :start => 1},
			{:count => 3, :loop => true, :rate => 10, :start => 0}, 
			{:count => 3, :loop => false, :rate => -1, :start => 0}, 
			{:count => 3, :loop => true, :rate => -1, :start => 0}, 
			{:count => 3, :loop => false, :rate => -1, :start => 0}, 
			{:count => 3, :loop => true, :rate => -1, :start => 0}, 
			{:count => 3, :loop => false, :rate => -1, :start => 0},
		]
		
		#--------------------------------------------------------------------------
		# Actors
		#--------------------------------------------------------------------------
		
		# The default position of characters.
		# DEFAULT_ACTOR_POS[n] = [grid x, grid y]
		DEFAULT_ACTOR_POS 	 = []
		DEFAULT_ACTOR_POS[0] = [15, 2]
		DEFAULT_ACTOR_POS[1] = [15, 4]
		DEFAULT_ACTOR_POS[2] = [15, 6]
		DEFAULT_ACTOR_POS[3] = [15, 8]
	end
end