#==============================================================================
#    Pear Dynamic Tiles
#    Version: 1.0.0
#    Author: pearcoding
#    Date: 11.08.2015
#==============================================================================
#
# Implements special tiles with regions and without using tons of events.
#
#=============================================================================
# TODO:	Add damage function and fix sound problem.
#=============================================================================

$imported = {} if $imported.nil?
$imported["Pear_DynamicTiles"] = 1.0

module Pear
  module DynamicTiles
    SLIDE_FRAME         = 2
    DAMAGE_FLASH_COLOR  = Color.new(255,0,0,255)
    DAMAGE_FLASH_DUR    = 0
  end
end

#==============================================================================
# Everything after this is not for casual editing.
#==============================================================================

module Pear
  module REGEXP
    module TILESET
      SLIPPERY_TILE = /<(?:SLIPPERY_TILE|slippery tile):\s*(\d+(?:\s*,\s*\d+)*)\s*>/i
      UP_TILE = /<(?:UP_TILE|up tile):\s*(\d+(?:\s*,\s*\d+)*)\s*>/i
      DOWN_TILE = /<(?:DOWN_TILE|down tile):\s*(\d+(?:\s*,\s*\d+)*)\s*>/i
      RIGHT_TILE = /<(?:RIGHT_TILE|right tile):\s*(\d+(?:\s*,\s*\d+)*)\s*>/i
      LEFT_TILE = /<(?:LEFT_TILE|left tile):\s*(\d+(?:\s*,\s*\d+)*)\s*>/i
      DAMAGE_TILE = /<(?:DAMAGE_TILE|damage tile):\s*(\d+(?:\s*,\s*\d+)*)\s*;\s*(\d+)\s*>/i
    end
  end
end

#==============================================================================
# DataManager
#==============================================================================

module DataManager
  class <<self; alias load_database_dt load_database; end
  def self.load_database
    load_database_dt
    load_notetags_dt
  end

  def self.load_notetags_dt
    groups = [$data_tilesets]
    for group in groups
      for obj in group
        next if obj.nil?
        obj.load_notetags_dt
      end
    end
  end
end

#==============================================================================
# RPG::Tileset
#==============================================================================

class RPG::Tileset
  attr_accessor :slippery_tiles
  attr_accessor :up_tiles
  attr_accessor :down_tiles
  attr_accessor :right_tiles
  attr_accessor :left_tiles
  attr_accessor :damage_tiles
  attr_accessor :damage_hp_tiles
  
  def load_notetags_dt
    @slippery_tiles = []
    @up_tiles = []
    @down_tiles = []
    @right_tiles = []
    @left_tiles = []
    @damage_tiles = []
    @damage_hp_tiles = []
    
    self.note.split(/[\r\n]+/).each { |line|
      case line
      when Pear::REGEXP::TILESET::SLIPPERY_TILE
        $1.scan(/\d+/).each { |num| 
        @slippery_tiles.push(num.to_i) if num.to_i > 0 }
      when Pear::REGEXP::TILESET::UP_TILE
        $1.scan(/\d+/).each { |num| 
        @up_tiles.push(num.to_i) if num.to_i > 0 }
      when Pear::REGEXP::TILESET::DOWN_TILE
        $1.scan(/\d+/).each { |num| 
        @down_tiles.push(num.to_i) if num.to_i > 0 }
      when Pear::REGEXP::TILESET::RIGHT_TILE
        $1.scan(/\d+/).each { |num| 
        @right_tiles.push(num.to_i) if num.to_i > 0 }
      when Pear::REGEXP::TILESET::LEFT_TILE
        $1.scan(/\d+/).each { |num| 
        @left_tiles.push(num.to_i) if num.to_i > 0 }
      when Pear::REGEXP::TILESET::DAMAGE_TILE
        $1.scan(/\d+/).each { |num| 
        @damage_tiles.push(num.to_i) if num.to_i > 0
        @damage_hp_tiles.push($2.to_i) if num.to_i > 0}
      end
    }
  end
end

#==============================================================================
# Game_Map
#==============================================================================

class Game_Map
  def slippery_floor?(dx, dy)
    return (valid?(dx, dy) && slippery_tag?(dx, dy))
  end
	
  def move_floor?(dx, dy)
    return (valid?(dx, dy) && move_tag?(dx, dy))
  end
  
  def damage_floor?(dx, dy)
    return (valid?(dx, dy) && damage_tag?(dx, dy))
  end

  def slippery_tag?(dx, dy)
    return tileset.slippery_tiles.include?(terrain_tag(dx, dy))
  end

  def move_tag?(dx, dy)
    return true if tileset.up_tiles.include?(terrain_tag(dx, dy))
    return true if tileset.down_tiles.include?(terrain_tag(dx, dy))
    return true if tileset.right_tiles.include?(terrain_tag(dx, dy))
    return tileset.left_tiles.include?(terrain_tag(dx, dy))
  end

  def damage_tag?(dx, dy)
    return tileset.damage_tiles.include?(terrain_tag(dx, dy))
  end
	
	def force_move_direction(dx, dy)
    return 8 if tileset.up_tiles.include?(terrain_tag(dx, dy))
    return 2 if tileset.down_tiles.include?(terrain_tag(dx, dy))
    return 6 if tileset.right_tiles.include?(terrain_tag(dx, dy))
    return 4 if tileset.left_tiles.include?(terrain_tag(dx, dy))
  end
end

#==============================================================================
# Game_CharacterBase
#==============================================================================

class Game_CharacterBase
  def on_slippery_floor?; $game_map.slippery_floor?(@x, @y); end
  def on_move_floor?; $game_map.move_floor?(@x, @y); end
  def on_damage_floor?; $game_map.damage_floor?(@x, @y); end
  
  def slippery_pose?
    return false unless on_slippery_floor?
    return false if @step_anime
    return true
  end
end

#==============================================================================
# Game_Player
#==============================================================================

class Game_Player < Game_Character
  alias game_player_dash_dt dash?
  def dash?
    return false if on_slippery_floor?
    return false if on_move_floor?
    return game_player_dash_dt
  end

  alias game_player_update_dt update
  def update
    game_player_update_dt
    update_slippery_floor
		update_move_floor
    update_damage_floor
  end
  
  def update_slippery_floor
    return if $game_map.interpreter.running?
    return unless on_slippery_floor?
    return if moving?
    move_straight(@direction)
  end
  
  def update_move_floor
    return if $game_map.interpreter.running?
    return unless on_move_floor?
    return if moving?
    move_straight($game_map.force_move_direction(@x, @y))
  end
  
  def update_damage_floor
    return if $game_map.interpreter.running?
    return unless on_damage_floor?
    actor.sprite_effect_type = :blink
    Sound.play_actor_damage
  end
  
  def pattern
		#Better way to fix the last frame when stopped while on slippery frame?
    return Pear::DynamicTiles::SLIDE_FRAME if slippery_pose? && moving?
    return @pattern
  end
end

#==============================================================================
# Game_Follower
#==============================================================================

class Game_Follower < Game_Character
  def pattern 
    return Pear::DynamicTiles::SLIDE_FRAME if slippery_pose? && moving?
    return @pattern
  end
end