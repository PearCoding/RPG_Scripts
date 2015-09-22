#==============================================================================
#    Pear Battle System
#		 Module: Animation
#    Version: 1.0.0
#    Author: pearcoding
#    Date: 17.08.2015
#==============================================================================

$bs_module["Animation"] = true

#==============================================================================
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# !!!          Everything after this is not for casual editing.            !!!
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#==============================================================================

if Pear::BattleSystem::USE_ANIMATION_MODULE # Check if animation is allowed

#==============================================================================
# ◆ RegExp expressions
#==============================================================================

module Pear
	module REGEXP
		module ACTOR
			BATTLE_NAME			= /<(?:BATTLE_NAME|battle name):\s*(\w+)\s*>/i
			BATTLE_HUE	 		= /<(?:BATTLE_HUE|battle hue):\s*(\d+)\s*>/i
		end
			
    module ACTOR_ENEMY
      BATTLE_BOUNDARY = /<(?:BATTLE_BOUNDARY|battle boundary):\s*(\d+)\s*[,]?\s*(\d+)\s*>/i
			BATTLE_STAND 		= /<(?:BATTLE_STAND|battle stand):\s*(\d+)\s*>/i
			BATTLE_MOVE 		= /<(?:BATTLE_MOVE|battle move):\s*(\d+)\s*>/i
			BATTLE_DAMAGE		= /<(?:BATTLE_DAMAGE|battle damage):\s*(\d+)\s*>/i
			BATTLE_WEAK			= /<(?:BATTLE_WEAK|battle weak):\s*(\d+)\s*>/i
			BATTLE_DEAD			= /<(?:BATTLE_DEAD|battle dead):\s*(\d+)\s*>/i
			BATTLE_VICTORY	= /<(?:BATTLE_VICTORY|battle victory):\s*(\d+)\s*>/i
			BATTLE_CAST 		= /<(?:BATTLE_CAST|battle cast):\s*(\d+)\s*>/i
    end
    
    module USABLEITEM
			BATTLE_CAST 		= /<(?:BATTLE_CAST|battle cast):\s*(\d+)\s*>/i
			BATTLE_MOVIE 		= /<(?:BATTLE_MOVIE|battle movie):\s*(\w+)\s*>/i
    end
		
		module STATE
			BATTLE_EFFECT 	= /<(?:BATTLE_CAST|battle cast):\s*(\d+)\s*>/i
		end
		
		module TROOP
			BATTLE_ENEMY_POS 		= /<(?:BATTLE_ENEMY_POS|battle enemy pos):\s*(\d+)\s*[;]?\s*(\d+)\s*[,]?\s*(\d+)\s*>/i
			BATTLE_ALLY_POS 		= /<(?:BATTLE_ALLY_POS|battle ally pos):\s*(\d+)\s*[;]?\s*(\d+)\s*[,]?\s*(\d+)\s*>/i
			BATTLE_MIRROR_ENEMY = /<(?:BATTLE_MIRROR_ENEMY|battle enemy mirror):\s*(\d+)\s*>/i
			BATTLE_MIRROR_ALLY	= /<(?:BATTLE_MIRROR_ENEMY|battle ally mirror):\s*(\d+)\s*>/i
		end
  end
end

#==============================================================================
# ◆ Utility functions
#==============================================================================

module Pear
	module BattleSystem
		#--------------------------------------------------------------------------
		# * grid_to_px
		# Converts grid coordinates to actual pixel coordinates
		#--------------------------------------------------------------------------
		def self.grid_to_px(p)
			return [p[0]*GRID_TO_PX_X_FACTOR,
							p[1]*GRID_TO_PX_Y_FACTOR + GRID_Y_OFFSET]
		end
	end
end

#==============================================================================
# ◆ Database section
#==============================================================================

#==============================================================================
# ■ DataManager
#==============================================================================

module DataManager
	#----------------------------------------------------------------------------
	# + load_database
	# Loads needed notetags from the database
	#----------------------------------------------------------------------------
  class <<self; alias load_database_p_bs_a load_database; end
  def self.load_database
    load_database_p_bs_a
    load_notetags_p_bs_a
  end

	#----------------------------------------------------------------------------
	# * load_notetags_p_bs
	# Loads needed notetags from the
	# actors, enemies, skills, items, states and troops
	#----------------------------------------------------------------------------
  def self.load_notetags_p_bs_a
    groups = [$data_actors, $data_enemies, $data_skills,
							$data_items, $data_states, $data_troops]
    for group in groups
      for obj in group
        next if obj.nil?
        obj.load_notetags_p_bs_a
      end
    end
  end
end

#==============================================================================
# ■ RPG::Actor
#==============================================================================

class RPG::Actor < RPG::BaseItem
  attr_accessor :battle_boundary
  attr_accessor :battle_stand
  attr_accessor :battle_move
  attr_accessor :battle_damage
  attr_accessor :battle_weak
  attr_accessor :battle_dead
  attr_accessor :battle_victory
	attr_accessor :battle_cast
	attr_accessor :battle_name
	attr_accessor :battle_hue
	attr_accessor :battle_animation_sheet	
  
	#----------------------------------------------------------------------------
	# * load_notetags_p_bs_a
	# Loads notetags from the note section for the actor
	#----------------------------------------------------------------------------
  def load_notetags_p_bs_a
    @battle_boundary 	= Pear::BattleSystem::DEFAULT_BATTLE_BOUNDARY
		@battle_stand			= Pear::BattleSystem::DEFAULT_BATTLE_STAND
		@battle_move			= Pear::BattleSystem::DEFAULT_BATTLE_MOVE
		@battle_damage		= Pear::BattleSystem::DEFAULT_BATTLE_DAMAGE
		@battle_weak			= Pear::BattleSystem::DEFAULT_BATTLE_WEAK
		@battle_dead			= Pear::BattleSystem::DEFAULT_BATTLE_DEAD
		@battle_victory		= Pear::BattleSystem::DEFAULT_BATTLE_VICTORY
		@battle_cast			= Pear::BattleSystem::DEFAULT_BATTLE_CAST_ACTOR
		@battle_name			= @name
		@battle_hue				= 0
			
		@battle_animation_sheet = Pear::BattleSystem::DEFAULT_ANIMATION_SHEET
    
    self.note.split(/[\r\n]+/).each { |line|
      case line
      when Pear::REGEXP::ACTOR_ENEMY::BATTLE_BOUNDARY
        @battle_boundary = [$1.to_i, $2.to_i] if $1.to_i >= 0 && $2.to_i
      when Pear::REGEXP::ACTOR_ENEMY::BATTLE_STAND
        @battle_stand = $1.to_i if $1.to_i >= 0
      when Pear::REGEXP::ACTOR_ENEMY::BATTLE_MOVE
        @battle_move = $1.to_i if $1.to_i >= 0
      when Pear::REGEXP::ACTOR_ENEMY::BATTLE_DAMAGE
        @battle_damage = $1.to_i if $1.to_i >= 0
      when Pear::REGEXP::ACTOR_ENEMY::BATTLE_WEAK
        @battle_weak = $1.to_i if $1.to_i >= 0
      when Pear::REGEXP::ACTOR_ENEMY::BATTLE_DEAD
        @battle_dead = $1.to_i if $1.to_i >= 0
      when Pear::REGEXP::ACTOR_ENEMY::BATTLE_VICTORY
        @battle_victory = $1.to_i if $1.to_i >= 0
      when Pear::REGEXP::ACTOR_ENEMY::BATTLE_CAST
        @battle_cast = $1.to_i if $1.to_i >= 0
      when Pear::REGEXP::ACTOR::BATTLE_NAME
        @battle_name = $1.to_s
      when Pear::REGEXP::ACTOR::BATTLE_HUE
        @battle_hue = $1.to_i if $1.to_i >= 0
      end
    }
  end
end


#==============================================================================
# ■ RPG::Enemy
#==============================================================================

class RPG::Enemy < RPG::BaseItem
  attr_accessor :battle_boundary
  attr_accessor :battle_stand
  attr_accessor :battle_move
  attr_accessor :battle_damage
  attr_accessor :battle_weak
  attr_accessor :battle_dead
  attr_accessor :battle_victory
	attr_accessor :battle_cast
	attr_accessor :battle_animation_sheet	
  
	#----------------------------------------------------------------------------
	# * load_notetags_p_bs_a
	# Loads notetags from the note section for the enemy
	#----------------------------------------------------------------------------
  def load_notetags_p_bs_a
    @battle_boundary 	= Pear::BattleSystem::DEFAULT_BATTLE_BOUNDARY
		@battle_stand			= Pear::BattleSystem::DEFAULT_BATTLE_STAND
		@battle_move			= Pear::BattleSystem::DEFAULT_BATTLE_MOVE
		@battle_damage		= Pear::BattleSystem::DEFAULT_BATTLE_DAMAGE
		@battle_weak			= Pear::BattleSystem::DEFAULT_BATTLE_WEAK
		@battle_dead			= Pear::BattleSystem::DEFAULT_BATTLE_DEAD
		@battle_victory		= Pear::BattleSystem::DEFAULT_BATTLE_VICTORY
		@battle_cast			= Pear::BattleSystem::DEFAULT_BATTLE_CAST_ACTOR
			
		@battle_animation_sheet = Pear::BattleSystem::DEFAULT_ANIMATION_SHEET
    
    self.note.split(/[\r\n]+/).each { |line|
      case line
      when Pear::REGEXP::ACTOR_ENEMY::BATTLE_BOUNDARY
        @battle_boundary = [$1.to_i, $2.to_i] if $1.to_i >= 0 && $2.to_i
      when Pear::REGEXP::ACTOR_ENEMY::BATTLE_STAND
        @battle_stand = $1.to_i if $1.to_i >= 0
      when Pear::REGEXP::ACTOR_ENEMY::BATTLE_MOVE
        @battle_move = $1.to_i if $1.to_i >= 0
      when Pear::REGEXP::ACTOR_ENEMY::BATTLE_DAMAGE
        @battle_damage = $1.to_i if $1.to_i >= 0
      when Pear::REGEXP::ACTOR_ENEMY::BATTLE_WEAK
        @battle_weak = $1.to_i if $1.to_i >= 0
      when Pear::REGEXP::ACTOR_ENEMY::BATTLE_DEAD
        @battle_dead = $1.to_i if $1.to_i >= 0
      when Pear::REGEXP::ACTOR_ENEMY::BATTLE_VICTORY
        @battle_victory = $1.to_i if $1.to_i >= 0
      when Pear::REGEXP::ACTOR_ENEMY::BATTLE_CAST
        @battle_cast = $1.to_i if $1.to_i >= 0
      end
    }
  end
end

#==============================================================================
# ■ RPG::UsableItem
#==============================================================================

class RPG::UsableItem < RPG::BaseItem
	attr_accessor :battle_cast
	attr_accessor :battle_movie
  
	#----------------------------------------------------------------------------
	# * load_notetags_p_bs_a
	# Loads notetags from the note section for the skill/item
	#----------------------------------------------------------------------------
  def load_notetags_p_bs_a
		@battle_cast			= Pear::BattleSystem::DEFAULT_BATTLE_CAST_SKILL
		@battle_movie			= Pear::BattleSystem::DEFAULT_BATTLE_MOVIE
    
    self.note.split(/[\r\n]+/).each { |line|
      case line
      when Pear::REGEXP::USABLEITEM::BATTLE_CAST
        @battle_cast = $1.to_i if $1.to_i >= 0
      when Pear::REGEXP::USABLEITEM::BATTLE_MOVIE
        @battle_movie = $1.to_s
      end
    }
  end
end

#==============================================================================
# ■ RPG::State
#==============================================================================

class RPG::State < RPG::BaseItem
	attr_accessor :battle_effect
  
	#----------------------------------------------------------------------------
	# * load_notetags_p_bs_a
	# Loads notetags from the note section for the state
	#----------------------------------------------------------------------------
  def load_notetags_p_bs_a
		@battle_cast	= Pear::BattleSystem::DEFAULT_BATTLE_EFFECT
    
    self.note.split(/[\r\n]+/).each { |line|
      case line
      when Pear::REGEXP::STATE::BATTLE_EFFECT
        @battle_cast = $1.to_i if $1.to_i >= 0
      end
    }
  end
end

#==============================================================================
# ■ RPG::Troop
#==============================================================================

class RPG::Troop
	attr_accessor :battle_enemy_pos
	attr_accessor :battle_ally_pos
	attr_accessor :battle_enemy_mirror
	attr_accessor :battle_ally_mirror
  
	#----------------------------------------------------------------------------
	# * load_notetags_p_bs_a
	# Loads notetags from the event comment section for the troop
	#----------------------------------------------------------------------------
  def load_notetags_p_bs_a
		@battle_enemy_pos			= []
		@battle_ally_pos			= Pear::BattleSystem::DEFAULT_ACTOR_POS.dup
		@battle_enemy_mirror	= []
		@battle_ally_mirror		= []
    
		self.pages.each { |page|
			# Only scan pages were span is battle (not turn or moment)
			if page.span == 0 
				page.list.each { |command|
					if command.code == 108 || # 108 = Comment begin
						 command.code == 408		# 408 = Every next comment line
						case command.parameters[0]
						when Pear::REGEXP::TROOP::BATTLE_ENEMY_POS
							@battle_enemy_pos[$1.to_i - 1] =
									[
									$2.to_i,#x
									$3.to_i,#y
									] if $1.to_i >= 1
						when Pear::REGEXP::TROOP::BATTLE_ALLY_POS
							@battle_ally_pos[$1.to_i - 1] =
									[
									$2.to_i,#x
									$3.to_i,#y
									] if $1.to_i >= 1
						when Pear::REGEXP::TROOP::BATTLE_ENEMY_MIRROR
							@battle_enemy_mirror.push($1.to_i) if $1.to_i >= 1
						when Pear::REGEXP::TROOP::BATTLE_ALLY_MIRROR
							@battle_ally_mirror.push($1.to_i) if $1.to_i >= 1
						end
					end
				}
			end
		}
  end
	
	#----------------------------------------------------------------------------
	# * enemy_grid_pos
	# Returns enemy grid position
	#----------------------------------------------------------------------------
	def enemy_grid_pos(nr)
		return @battle_enemy_pos[nr-1]
	end
	
	#----------------------------------------------------------------------------
	# * ally_grid_pos
	# Returns enemy grid position
	#----------------------------------------------------------------------------
	def ally_grid_pos(nr)
		return @battle_ally_pos[nr-1]
	end
	
	#----------------------------------------------------------------------------
	# * mirror_enemy?
	# Returns if enemy (sprite) should be mirrored
	#----------------------------------------------------------------------------
	def mirror_enemy?(nr)
		@battle_enemy_mirror.include?(nr)
	end
	
	#----------------------------------------------------------------------------
	# * mirror_ally?
	# Returns if ally (sprite) should be mirrored
	#----------------------------------------------------------------------------
	def mirror_ally?(nr)
		@battle_ally_mirror.include?(nr)
	end
end
	
#==============================================================================
# ◆ Management section
#==============================================================================

#==============================================================================
# ■ BattleManager
#==============================================================================

module BattleManager
	#----------------------------------------------------------------------------
  # + setup
	# Setup battle
	#----------------------------------------------------------------------------
	class <<self; alias battlemanager_p_bs_a setup; end
  def self.setup(troop_id, can_escape = true, can_lose = false)
		battlemanager_p_bs_a(troop_id, can_escape, can_lose)
		$game_party.setup_battle(troop_id)
  end
end

#==============================================================================
# ◆ Game section
#==============================================================================

#==============================================================================
# ■ Game_Troop
#==============================================================================

class Game_Troop < Game_Unit
	
	#----------------------------------------------------------------------------
  # + setup
	# Setup with different positions
  #----------------------------------------------------------------------------
	alias game_troop_setup_p_bs_a setup
	def setup(troop_id)
    game_troop_setup_p_bs_a(troop_id)
		@enemies.each_with_index do |enemy, i|
			p = troop.enemy_grid_pos(i+1)
			if p
				p = Pear::BattleSystem::grid_to_px(p)
				enemy.screen_x = p[0]
				enemy.screen_y = p[1]
			end
		end
  end
end
	
#==============================================================================
# ■ Game_Party
#==============================================================================

class Game_Party < Game_Unit
	#----------------------------------------------------------------------------
  # * setup_battle
	# Setup battle with different positions
  #----------------------------------------------------------------------------
	def setup_battle(troop_id)
		troop = $data_troops[troop_id]
		battle_members.each_with_index do |ally, i|
			p = troop.ally_grid_pos(i+1)
			if p
				p = Pear::BattleSystem::grid_to_px(p)
				ally.screen_x = p[0]
				ally.screen_y = p[1]
			end
		end
  end
end

#==============================================================================
# ■ Game_Actor
#==============================================================================

class Game_Actor < Game_Battler
	attr_accessor :screen_x  # battle screen X coordinate
  attr_accessor :screen_y  # battle screen Y coordinate
	
	#----------------------------------------------------------------------------
	# + initialize
	# Setup additional x,y coordinates and battler names for battle scene
	#----------------------------------------------------------------------------
	alias game_actor_initialize_p_bs_a initialize
	def initialize(actor_id)
		@screen_x = 0
		@screen_y = 0
			
		game_actor_initialize_p_bs_a(actor_id)
			
		@battler_name = actor.battle_name
    @battler_hue 	= actor.battle_hue
	end
	
	#----------------------------------------------------------------------------
  # ~ use_sprite?
	# Use Sprites? Hell, yeah!
  #----------------------------------------------------------------------------
  def use_sprite?
    return true
  end
	
  #----------------------------------------------------------------------------
  # * screen_z
	# Get Battle Screen Z-Coordinate
  #----------------------------------------------------------------------------
  def screen_z
    return 75
  end
end
	
#==============================================================================
# ◆ Sprite/Rendering section
#==============================================================================

#==============================================================================
# ■ Spriteset_Battle
#==============================================================================

class Spriteset_Battle
	#--------------------------------------------------------------------------
  # ~ create_blurry_background_bitmap
	# Originally creates a blurry image of the map,
	# we will create an unblury one :)
  #--------------------------------------------------------------------------
  def create_blurry_background_bitmap
    source = SceneManager.background_bitmap
		bitmap = Bitmap.new(Graphics.width, Graphics.height)
    bitmap.rop_blt(0, 0, source, source.rect)
    bitmap
  end
	
	#--------------------------------------------------------------------------
  # ~ create_actors
  # Creates all actor Sprite_Battler instances.
	# We display the sprites. So use it the right way.
  #--------------------------------------------------------------------------
  def create_actors
    @actor_sprites = $game_party.battle_members.reverse.collect do |ally|
      Sprite_Battler.new(@viewport1, ally)
		end
  end
	
	#--------------------------------------------------------------------------
  # ~ update_actors
	# Updates all actors in the right way
  #--------------------------------------------------------------------------
  def update_actors
    @actor_sprites.each {|sprite| sprite.update }
  end
end

#==============================================================================
# ■ Sprite_Battler
#==============================================================================

class Sprite_Battler < Sprite_Base
	#----------------------------------------------------------------------------
  # + initialize
	# Update bitmap even without battler_name
	#----------------------------------------------------------------------------
	alias sprite_battler_initialize_p_bs_a initialize
	def initialize(viewport, battler = nil)
		sprite_battler_initialize_p_bs_a(viewport, battler)
			
		if battler
			if battler.actor?			
				@cw = battler.actor.battle_boundary[0]*Pear::BattleSystem::GRID_TO_PX_X_FACTOR
				@ch = battler.actor.battle_boundary[1]*Pear::BattleSystem::GRID_TO_PX_Y_FACTOR
				@animation_sheet = battler.actor.battle_animation_sheet
			else#enemy
				@cw = battler.enemy.battle_boundary[0]*Pear::BattleSystem::GRID_TO_PX_X_FACTOR
				@ch = battler.enemy.battle_boundary[1]*Pear::BattleSystem::GRID_TO_PX_Y_FACTOR
				@animation_sheet = battler.enemy.battle_animation_sheet
			end
		
			change_animation(0)
		end
	end
		
	#----------------------------------------------------------------------------
  # + update_bitmap
	# Update bitmap even without battler_name
  #----------------------------------------------------------------------------
	alias sprite_battler_update_bitmap_p_bs_a update_bitmap
  def update_bitmap
		sprite_battler_update_bitmap_p_bs_a
		if Graphics.frame_count % 
				(frame_info[:rate] > 0 ? frame_info[:rate] : Pear::BattleSystem::DEFAULT_ANIMATION_RATE) == 0
			update_battle_animation 
		end
	end
	
	#----------------------------------------------------------------------------
	# * change_animation
	# Changes the given animation
	#----------------------------------------------------------------------------
	def change_animation(id) # Remember id = row!
		@animation_index = id
		@frame = frame_info[:start]
		@animation_back = false	
			
		set_sprite_rect(@frame, @animation_index)
	end	
		
	#----------------------------------------------------------------------------
	# * set_sprite_rect
	# Set the viewing rect of the bitmap.
	#----------------------------------------------------------------------------
	def set_sprite_rect(x,y)
		self.src_rect.set(@cw*x, @ch*y, @cw, @ch)
	end	
	
	#----------------------------------------------------------------------------
  # ~ update_origin
	# I do not like the centered sprite rendering...
	# I'm a professional OpenGL developer, so back to "home" terrain xD
  #----------------------------------------------------------------------------
  def update_origin
    if bitmap
      self.ox = 0
			self.oy = 0
    end
	end
		
	#----------------------------------------------------------------------------
  # * update_battle_animation
	# Updates battle animations.
  #----------------------------------------------------------------------------
	def update_battle_animation
		@frame = @animation_back ? @frame - 1 : @frame + 1
			
		if @frame == frame_info[:count]
			if frame_info[:loop]
				@animation_back = true
				@frame = frame_info[:count] > 1 ? frame_info[:count] - 2 : 0 
			else
				@frame = frame_info[:count]-1
			end
		end
			
		if @animation_back && @frame < 0
			@animation_back = false
			@frame = frame_info[:count] > 1 ? 1 : 0
		end	
			
		set_sprite_rect(@frame, @animation_index)
	end
		
	#----------------------------------------------------------------------------
  # * frame_info
	# Returns current frame information from the sheet
  #----------------------------------------------------------------------------
	def frame_info
		return @animation_sheet[@animation_index]
	end
end
	
end # USE_ANIMATION_MODULE

