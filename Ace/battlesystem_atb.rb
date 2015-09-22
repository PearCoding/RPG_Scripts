#==============================================================================
#    Pear Battle System
#		 Module: Active Time Battle
#    Version: 1.0.0
#    Author: pearcoding
#    Date: 12.08.2015
#==============================================================================

$bs_module["ActiveTimeBattle"] = true

#==============================================================================
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# !!!          Everything after this is not for casual editing.            !!!
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#==============================================================================

# Check if active time battle is allowed
if Pear::BattleSystem::USE_ACTIVE_TIME_BATTLE_MODULE 
	
#==============================================================================
# ◆ RegExp expressions
#==============================================================================

module Pear
  module REGEXP    
    module USABLEITEM
			BATTLE_AVL_COST	= /<(?:BATTLE_AVL_COST|battle avl cost):\s*(\d+)\s*>/i
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
  class <<self; alias load_database_p_bs_atb load_database; end
  def self.load_database
    load_database_p_bs_atb
    load_notetags_p_bs_atb
  end

	#----------------------------------------------------------------------------
	# * load_notetags_p_bs_atb
	# Loads needed notetags from the
	# actors, enemies, skills, items, states and troops
	#----------------------------------------------------------------------------
  def self.load_notetags_p_bs_atb
    groups = [$data_skills, $data_items]
    for group in groups
      for obj in group
        next if obj.nil?
        obj.load_notetags_p_bs_atb
      end
    end
  end
end

#==============================================================================
# ■ RPG::UsableItem
#==============================================================================

class RPG::UsableItem < RPG::BaseItem
	attr_accessor :battle_avl_cost
  
	#----------------------------------------------------------------------------
	# * load_notetags_p_bs_atb
	# Loads notetags from the note section for the skill/item
	#----------------------------------------------------------------------------
  def load_notetags_p_bs_atb
		@battle_avl_cost	= Pear::BattleSystem::DEFAULT_BATTLE_AVL
    
    self.note.split(/[\r\n]+/).each { |line|
      case line
      when Pear::REGEXP::USABLEITEM::BATTLE_AVL_COST
        @battle_avl_cost = $1.to_i if $1.to_i >= 0
      end
    }
  end
end

#==============================================================================
# ◆ Management section
#==============================================================================

#==============================================================================
# ■ BattleManager
#==============================================================================

module BattleManager
	#--------------------------------------------------------------------------
  # ~ battle_start
	# Battle Start
  #--------------------------------------------------------------------------
  def self.battle_start
    $game_system.battle_count += 1
    $game_party.on_battle_start(@surprise)
    $game_troop.on_battle_start(@surprise)
    $game_troop.enemy_names.each do |name|
			$game_message.add(sprintf(Vocab::Emerge, name))
    end
		
    if @preemptive
      $game_message.add(sprintf(Vocab::Preemptive, $game_party.name))
    elsif @surprise
      $game_message.add(sprintf(Vocab::Surprise, $game_party.name))
    end
    wait_for_message
  end
	
	#----------------------------------------------------------------------------
	# ~ process_victory
	# Shows full window with after game processing. Like exp gain, etc!
	#----------------------------------------------------------------------------
	# TODO
	#----------------------------------------------------------------------------
	class <<self; alias todo_process_victory process_victory; end
	def self.process_victory
		todo_process_victory
	end
	
	#----------------------------------------------------------------------------
  # ~ next_command
	# No need to use this anymore
  #----------------------------------------------------------------------------
  def self.next_command
    return true
  end
	
  #----------------------------------------------------------------------------
  # ~ prior_command
	# No need to use this anymore
  #----------------------------------------------------------------------------
  def self.prior_command
    return true
  end
	
  #----------------------------------------------------------------------------
  # * add_enemy_order
	# Adds enemies
  #----------------------------------------------------------------------------
	def self.add_enemy_order(id)
    @action_battlers = [] unless @action_battlers.is_a?(Array)  
    @action_battlers << $game_troop.members[id]
  end
	
  #----------------------------------------------------------------------------
  # * add_ally_order
	# Adds allies
  #----------------------------------------------------------------------------
	def self.add_ally_order(id)
    @action_battlers = [] unless @action_battlers.is_a?(Array)  
    @action_battlers << $game_party.members[id]
  end
	
  #----------------------------------------------------------------------------
  # * add_actor_order
	# Adds the actor
	#----------------------------------------------------------------------------
	def self.add_actor_order
    @action_battlers = [] unless @action_battlers.is_a?(Array)  
    @action_battlers << self.actor
  end
	
  #----------------------------------------------------------------------------
  # * has_action?
	# Check if any actions are available
  #----------------------------------------------------------------------------
	def self.has_action?
    @action_battlers.empty? ? false : true
  end
	
	#----------------------------------------------------------------------------
  # ~ make_action_orders
	# We do not use any action orders
  #----------------------------------------------------------------------------
  def self.make_action_orders
    return
  end
	
  #----------------------------------------------------------------------------
  # * actor_index
	# ...
  #----------------------------------------------------------------------------
	def self.actor_index
		return @actor_index
	end
	
  #----------------------------------------------------------------------------
  # * set_actor_index
	# ...
  #----------------------------------------------------------------------------
	def self.set_actor_index(id)
		@actor_index = id
	end
end

#==============================================================================
# ◆ Game section
#==============================================================================

#==============================================================================
# ■ Game_Unit
#==============================================================================

class Game_Unit
	#--------------------------------------------------------------------------
  # ~ on_battle_start
	# Processing at Start of Battle
  #--------------------------------------------------------------------------
  def on_battle_start(surprise=false)
    members.each {|member| member.on_battle_start(surprise) }
    @in_battle = true
  end
end

#==============================================================================
# ■ Game_BattlerBase
#==============================================================================

class Game_BattlerBase
	attr_accessor :battle_avl
	
	#--------------------------------------------------------------------------
  # + initialize
	# Initialize parameters
  #--------------------------------------------------------------------------
	alias game_battlerbase_initialize_p_bt_atb initialize
	def initialize
    game_battlerbase_initialize_p_bt_atb
		init_avl
  end
	
	#----------------------------------------------------------------------------
  # * init_avl
	# Setups availability based on surprise
  #----------------------------------------------------------------------------
	def init_avl(surprise=false)
		if surprise
			@battle_avl = Pear::BattleSystem::MAX_AVL
		else
			@battle_avl = 0.0
		end
	end
	
	#----------------------------------------------------------------------------
	# * is_available?
	# Checks if battler is able to act based on the time of the last action
	#----------------------------------------------------------------------------
	def is_available?
		return @battle_avl >= Pear::BattleSystem::MAX_AVL
	end
	
	#----------------------------------------------------------------------------
	# * avl_percentage
	# Returns percentage of availability full
	#----------------------------------------------------------------------------
	def avl_percentage
		return @battle_avl/Pear::BattleSystem::MAX_AVL
	end
	
	#--------------------------------------------------------------------------
  # * useable_item_avl_cost
	# Calculate Skill's or Item's AVL Cost
  #--------------------------------------------------------------------------
  def useable_item_avl_cost(item)
    return item.battle_avl_cost
  end
	
	#--------------------------------------------------------------------------
  # * useable_item_avl_available?
	# Returns if Skill/Item can be used with AVL
  #--------------------------------------------------------------------------
  def useable_item_avl_available?(item)
    return @battle_avl >= useable_item_avl_cost(item)
  end
	
	#--------------------------------------------------------------------------
  # + usable_item_conditions_met
	# Determine if cost of the agility of using Skill/Item can be paid
  #--------------------------------------------------------------------------
	alias game_battlerbase_usable_item_conditions_met_p_bs_atb usable_item_conditions_met?
  def usable_item_conditions_met?(item)
    return game_battlerbase_usable_item_conditions_met_p_bs_atb(item) &&
				useable_item_avl_available?(item)
  end
end

#==============================================================================
# ■ Game_Battler
#==============================================================================

class Game_Battler < Game_BattlerBase	
	#----------------------------------------------------------------------------
  # + revive
	# Sets parameter after revive
  #----------------------------------------------------------------------------
	alias game_battler_revive_p_bs_atb revive
  def revive
		game_battler_revive_p_bs_atb
    @battle_avl = 0.0 if @hp == 0
  end
	
	#----------------------------------------------------------------------------
  # + on_battle_start
	# Setups parameter before battle starts
  #----------------------------------------------------------------------------
	alias game_battler_on_battle_start_p_bs_atb on_battle_start
  def on_battle_start(surprise=false)
    game_battler_on_battle_start_p_bs_atb
		init_avl(surprise)
  end
	
	#----------------------------------------------------------------------------
  # * increment_avl
	# Increase the avl
  #----------------------------------------------------------------------------
	def increment_avl
		@battle_avl =
		[@battle_avl +
			Pear::BattleSystem::MAX_AVL_PER_STEP*(agi.to_f/Pear::BattleSystem::MAX_AGI),
				Pear::BattleSystem::MAX_AVL].min
	end
	
	#--------------------------------------------------------------------------
  # + use_item
  # Decrement availability costs
  #--------------------------------------------------------------------------
	alias game_battler_use_item_p_bs_atb use_item
  def use_item(item)
    game_battler_use_item_p_bs_atb(item)
		@battle_avl = [0,
			 @battle_avl - item.battle_avl_cost].max
  end
end

#==============================================================================
# ■ Game_Actor
#==============================================================================

class Game_Actor < Game_Battler	
	#----------------------------------------------------------------------------
  # + next_command
	# To next input action
  #----------------------------------------------------------------------------
	alias game_actor_next_command_p_bs_atb next_command
	def next_command
    return false unless is_available?
    game_actor_next_command_p_bs_atb
  end
	
	#----------------------------------------------------------------------------
  # + prior_command
	# To previous input action
  #----------------------------------------------------------------------------
	alias game_actor_prior_command_p_bs_atb prior_command
	def prior_command
    return false unless is_available?
    game_actor_prior_command_p_bs_atb
  end
end
 
#==============================================================================
# ◆ Scene section
#==============================================================================

#==============================================================================
# ■ Scene_Battle
#==============================================================================

class Scene_Battle
	attr_accessor :ally_array 	# Available allies
	attr_accessor :enemy_index	# Available enemy
	
	#----------------------------------------------------------------------------
  # + start
	# Initialize needed parameters
  #----------------------------------------------------------------------------
	alias scene_battle_start_p_bs_atb start
	def start
    @ally_array = []
		@enemy_index = -1
    scene_battle_start_p_bs_atb
  end
	
	#----------------------------------------------------------------------------
  # + update
	# Updates everything needed.
  #----------------------------------------------------------------------------
	alias scene_battle_update_p_bs_atb update
  def update
    update_availability if Graphics.frame_count % Pear::BattleSystem::AVL_UPDATE_RATE == 0
    scene_battle_update_p_bs_atb
  end
	
	#----------------------------------------------------------------------------
  # * update_availability
	# Updates the availability of characters
  #----------------------------------------------------------------------------
	def update_availability
		return if BattleManager.has_action?
		
		$game_troop.alive_members.each{|member|
			member.increment_avl
			if member.is_available?
				@enemy_index = $game_troop.members.index(member)
				BattleManager.add_enemy_order(@enemy_index)
				BattleManager.input_start
				turn_start
				return
			end
		}
		
		return unless @ally_array.empty?
		
		$game_party.alive_members.each{|member|
			member.increment_avl
			if member.is_available?
				@ally_array << $game_party.members.index(member)
				@status_window.refresh
				start_party_command_selection
				return
			end
		}
		
		@status_window.refresh
	end
	
	#----------------------------------------------------------------------------
  # + next_command
  #----------------------------------------------------------------------------
	alias scene_battle_next_command_p_bs_atb next_command
  def next_command
    if BattleManager.actor
      @ally_array.shift
      BattleManager.add_actor_order
    end
		
		BattleManager.set_actor_index(@ally_array.first) unless @ally_array.empty?
    scene_battle_next_command_p_bs_atb
  end
	
	#----------------------------------------------------------------------------
	# ~ prior_command
	#----------------------------------------------------------------------------
  def prior_command
    start_actor_command_selection
  end
	
	#----------------------------------------------------------------------------
  # + start_actor_command_selection
	# Start Actor Command Selection
  #----------------------------------------------------------------------------
	alias battle_scene_start_actor_command_selection_p_bs_atb start_actor_command_selection
	def start_actor_command_selection
    return turn_start if BattleManager.has_action?
    battle_scene_start_actor_command_selection_p_bs_atb
  end
	
	#----------------------------------------------------------------------------
  # ~ start_party_command_selection
	# Start Party Command Selection
  #----------------------------------------------------------------------------
  def start_party_command_selection
		refresh_status
    @status_window.unselect
    @status_window.open
    if @ally_array.empty?
      return
    end
    if BattleManager.input_start
      next_command
    else
      @party_command_window.deactivate
			turn_start
    end
	end
		
	#----------------------------------------------------------------------------
  # ~ create_all_windows
	# We have our own windows
  #----------------------------------------------------------------------------
  def create_all_windows
    create_message_window
    create_scroll_text_window
    create_log_window
    create_status_window
    create_info_viewport
    create_party_command_window
    create_actor_command_window
    create_help_window
    create_skill_window
    create_item_window
    create_actor_window
    create_enemy_window
  end
end
	
end # USE_ACTIVE_TIME_BATTLE_MODULE