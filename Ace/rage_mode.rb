#==============================================================================
#    Pear Rage Mode
#    Version: 1.0.0
#    Author: pearcoding
#    Date: 10.08.2015
#==============================================================================
#
# Implements a TP based mode and state method for use in battles
#

# Inspired by the Yanfly Engine Ace - TP Manager

$imported = {} if $imported.nil?
$imported["Pear_RageMode"] = 1.0

module Pear
  module RageMode
    TP_LIMIT = 100
    DEFAULT_MODE = 0
    DEFAULT_UNLOCKS = [0]
    
    MENU_NAME = "Modes"
    MENU_SWITCH = 0
    SWITCH_DEFAULT_ENABLE = true
    CHANGE_TP_RESET = true
    EQUIPPED_COLOR = 17
    
    MODES = {
     0 => {
      :name         => "Normal",
      :icon         => 121,
      :description  => "No special power.",
      :init_tp      => "rand * 25",
      :regen_tp     => "100 * trg",
      :take_hp_dmg  => "0",
      :deal_hp_dmg  => "0",
      :heal_hp_dmg  => "0",
      :ally_hp_dmg  => "0",
      :deal_mp_dmg  => "0",
      :heal_mp_dmg  => "0",
      :ally_mp_dmg  => "0",
      :deal_state   => "0",
      :gain_state   => "0",
      :kill_ally    => "0",
      :kill_enemy   => "0",
      :only_alive   => "0",
      :evasion      => "0",
      :state        => 0,
      },
     1 => {
      :name         => "Tier 1",
      :icon         => 121,
      :description  => "First step of the tier tree.",
      :init_tp      => "rand * 50",
      :regen_tp     => "200 * trg",
      :take_hp_dmg  => "10",
      :deal_hp_dmg  => "0",
      :heal_hp_dmg  => "0",
      :ally_hp_dmg  => "0",
      :deal_mp_dmg  => "0",
      :heal_mp_dmg  => "0",
      :ally_mp_dmg  => "0",
      :deal_state   => "0",
      :gain_state   => "0",
      :kill_ally    => "0",
      :kill_enemy   => "0",
      :only_alive   => "0",
      :evasion      => "0",
      :state        => 21,
      },
     2 => {
      :name         => "Tier 2",
      :icon         => 121,
      :description  => "The next form.",
      :init_tp      => "rand * 50",
      :regen_tp     => "200 * trg",
      :take_hp_dmg  => "10",
      :deal_hp_dmg  => "5",
      :heal_hp_dmg  => "0",
      :ally_hp_dmg  => "0",
      :deal_mp_dmg  => "0",
      :heal_mp_dmg  => "0",
      :ally_mp_dmg  => "0",
      :deal_state   => "0",
      :gain_state   => "0",
      :kill_ally    => "0",
      :kill_enemy   => "0",
      :only_alive   => "0",
      :evasion      => "0",
      :state        => 22,
      },
     3 => {
      :name         => "Tier 3",
      :icon         => 121,
      :description  => "Strong form.",
      :init_tp      => "rand * 50",
      :regen_tp     => "200 * trg",
      :take_hp_dmg  => "10",
      :deal_hp_dmg  => "5",
      :heal_hp_dmg  => "0",
      :ally_hp_dmg  => "0",
      :deal_mp_dmg  => "0",
      :heal_mp_dmg  => "0",
      :ally_mp_dmg  => "0",
      :deal_state   => "0",
      :gain_state   => "0",
      :kill_ally    => "0",
      :kill_enemy   => "0",
      :only_alive   => "0",
      :evasion      => "0",
      :state        => 23,
      },
     4 => {
      :name         => "Tier 4",
      :icon         => 121,
      :description  => "A very strong form.",
      :init_tp      => "25 + rand * 50",
      :regen_tp     => "400 * trg",
      :take_hp_dmg  => "10",
      :deal_hp_dmg  => "5",
      :heal_hp_dmg  => "0",
      :ally_hp_dmg  => "0",
      :deal_mp_dmg  => "0",
      :heal_mp_dmg  => "0",
      :ally_mp_dmg  => "0",
      :deal_state   => "0",
      :gain_state   => "0",
      :kill_ally    => "0",
      :kill_enemy   => "0",
      :only_alive   => "0",
      :evasion      => "0",
      :state        => 24,
      },
     5 => {
      :name         => "Tier 5",
      :icon         => 121,
      :description  => "Ultimate form.",
      :init_tp      => "50 + rand * 50",
      :regen_tp     => "500 * trg",
      :take_hp_dmg  => "20",
      :deal_hp_dmg  => "10",
      :heal_hp_dmg  => "0",
      :ally_hp_dmg  => "0",
      :deal_mp_dmg  => "0",
      :heal_mp_dmg  => "0",
      :ally_mp_dmg  => "0",
      :deal_state   => "0",
      :gain_state   => "0",
      :kill_ally    => "0",
      :kill_enemy   => "0",
      :only_alive   => "0",
      :evasion      => "0",
      :state        => 25,
      },
    }
  end
end

#==============================================================================
# Everything after this is not for casual editing.
#==============================================================================

module Pear
  module REGEXP
    module ACTOR
      RAGE_MODE = /<(?:RAGE_MODE|rage mode):\s*(\d+)\s*>/i
      UNLOCK_MODE = /<(?:UNLOCK_MODE|unlock mode):\s*(\d+(?:\s*,\s*\d+)*)>/i
    end
    
    module ENEMY
      RAGE_MODE = /<(?:RAGE_MODE|rage mode):\s*(\d+)\s*>/i
    end
    
    module SKILL
      RAGE_MODE = /<(?:RAGE_MODE|rage mode):\s*(\d+)\s*>/i
      REQUIRES_MODE = /<(?:REQUIRES_MODE|requires mode):\s*(\d+(?:\s*,\s*\d+)*)>/i
    end
  end
end

#==============================================================================
# Switch
#==============================================================================

module Switch
  def self.rage_mode
    return true if Pear::RageMode::MENU_SWITCH <= 0
    return $game_switches[Pear::RageMode::MENU_SWITCH]
  end
  
  def self.rage_mode_set(item)
    return if Pear::RageMode::MENU_SWITCH <= 0
    $game_switches[Pear::RageMode::MENU_SWITCH] = item
  end
end

#==============================================================================
# DataManager
#==============================================================================

module DataManager
  class <<self; alias load_database_rm load_database; end
  def self.load_database
    load_database_rm
    load_notetags_rm
  end

  def self.load_notetags_rm
    groups = [$data_actors, $data_enemies, $data_skills]
    for group in groups
      for obj in group
        next if obj.nil?
        obj.load_notetags_rm
      end
    end
  end
  
  class <<self; alias setup_new_game_rm setup_new_game; end
  def self.setup_new_game
    setup_new_game_rm
    Switch.rage_mode_set(Pear::RageMode::SWITCH_DEFAULT_ENABLE)
  end
end


#==============================================================================
# RPG::Actor
#==============================================================================

class RPG::Actor < RPG::BaseItem
  attr_accessor :rage_mode
  attr_accessor :unlocked_rage_modes
  
  def load_notetags_rm
    @rage_mode = nil
    @unlocked_rage_modes = []
    
    self.note.split(/[\r\n]+/).each { |line|
      case line
      when Pear::REGEXP::ACTOR::RAGE_MODE
        @rage_mode = $1.to_i
      when Pear::REGEXP::ACTOR::UNLOCK_MODE
        $1.scan(/\d+/).each { |num| 
        @unlocked_rage_modes.push(num.to_i) if num.to_i >= 0 }
      end
    }
    
    @rage_mode = Pear::RageMode::DEFAULT_MODE if @rage_mode.nil?
    if @unlocked_rage_modes.empty?
      @unlocked_rage_modes = Pear::RageMode::DEFAULT_UNLOCKS.clone
    end
    @unlocked_rage_modes.push(@rage_mode) if @unlocked_rage_modes.include?(@rage_mode)
    @unlocked_rage_modes.uniq!
    @unlocked_rage_modes.sort!
  end
end

#==============================================================================
# RPG::Enemy
#==============================================================================

class RPG::Enemy < RPG::BaseItem
  attr_accessor :rage_mode

  def load_notetags_rm
    @rage_mode = Pear::RageMode::DEFAULT_MODE
    self.note.split(/[\r\n]+/).each { |line|
      case line
      when Pear::REGEXP::ENEMY::RAGE_MODE
        @rage_mode = $1.to_i
      end
    }
  end
end


#==============================================================================
# RPG::Skill
#==============================================================================

class RPG::Skill < RPG::UsableItem
  attr_accessor :to_rm_mode
  attr_accessor :requires_modes

  def load_notetags_rm
    @to_rm_mode = nil
    @requires_modes = []
    
    self.note.split(/[\r\n]+/).each { |line|
      case line
      when Pear::REGEXP::SKILL::RAGE_MODE
        @to_rm_mode = $1.to_i
      when Pear::REGEXP::SKILL::REQUIRES_MODE
        $1.scan(/\d+/).each { |num| 
        @requires_modes.push(num.to_i) if num.to_i >= 0 }
      end
    }
    @requires_modes.uniq!
    @requires_modes.sort!
  end
end

#==============================================================================
# Game_BattlerBase
#==============================================================================

class Game_BattlerBase
  attr_accessor :rage_mode
  attr_accessor :unlocked_rage_modes
  
  def max_tp; return Pear::RageMode::TP_LIMIT; end
  
  def rage_mode; return 0; end
  def unlocked_rage_modes; return [0]; end
  
  def rm_setting(setting)
    return Pear::RageMode::MODES[rage_mode][setting]
  end
  
  alias game_battlerbase_skill_conditions_met_rm skill_conditions_met?
  def skill_conditions_met?(skill)
    return game_battlerbase_skill_conditions_met_rm(skill) &&
    (skill.requires_modes.empty? || skill.requires_modes.include?(rage_mode))
  end
end

#==============================================================================
# Game_Battler
#==============================================================================

class Game_Battler < Game_BattlerBase
  attr_accessor :rage_mode_before # Mode before the battle
  
  def init_tp
    self.tp = eval(rm_setting(:init_tp))
  end

  def charge_tp_by_damage(damage_rate)
    self.tp += eval(rm_setting(:take_hp_dmg))
  end
  
  def charge_tp_by_mp_damage(damage_rate)
    self.tp += eval(rm_setting(:take_mp_dmg))
  end
  
  def regenerate_tp
    self.tp += eval(rm_setting(:regen_tp))
    if friends_unit.alive_members.size == 1
      self.tp += eval(rm_setting(:only_alive))
    end
  end
  
  alias game_battler_execute_damage_rm execute_damage
  def execute_damage(user)
    game_battler_execute_damage_rm(user)
    return unless $game_party.in_battle
    if @result.hp_damage > 0
      user.tp += eval(user.rm_setting(:deal_hp_dmg))
      gain_tp_ally_hp_damage
    elsif @result.hp_damage < 0
      user.tp += eval(user.rm_setting(:heal_hp_dmg))
    end
    if @result.mp_damage > 0
      user.tp += eval(user.rm_setting(:deal_mp_dmg))
      gain_tp_ally_mp_damage
      charge_tp_by_mp_damage(@result.mp_damage)
    elsif @result.mp_damage < 0
      user.tp += eval(user.rm_setting(:heal_mp_dmg))
    end
    user.tp += eval(user.rm_setting(:kill_enemy)) if self.hp == 0
    gain_tp_kill_ally if self.hp == 0
  end
  
  alias game_battler_item_effect_recover_hp_rm item_effect_recover_hp
  def item_effect_recover_hp(user, item, effect)
    game_battler_item_effect_recover_hp_rm(user, item, effect)
    return unless $game_party.in_battle
    if @result.hp_damage > 0
      user.tp += eval(user.rm_setting(:deal_hp_dmg))
      gain_tp_ally_hp_damage
    elsif @result.hp_damage < 0
      user.tp += eval(user.rm_setting(:heal_hp_dmg))
    end
  end
  
  alias game_battler_item_effect_recover_mp_rm item_effect_recover_mp
  def item_effect_recover_mp(user, item, effect)
    game_battler_item_effect_recover_mp_rm(user, item, effect)
    return unless $game_party.in_battle
    if @result.mp_damage > 0
      user.tp += eval(user.rm_setting(:deal_mp_dmg))
      gain_tp_ally_mp_damage
      charge_tp_by_mp_damage(@result.mp_damage)
    elsif @result.mp_damage < 0
      user.tp += eval(user.rm_setting(:heal_mp_dmg))
    end
  end
  
  def gain_tp_ally_hp_damage
    for member in friends_unit.alive_members
      next if member == self
      member.tp += eval(member.rm_setting(:ally_hp_dmg))
    end
  end
  
  def gain_tp_ally_mp_damage
    for member in friends_unit.alive_members
      next if member == self
      member.tp += eval(member.rm_setting(:ally_mp_dmg))
    end
  end
  
  def gain_tp_kill_ally
    for member in friends_unit.alive_members
      next if member == self
      member.tp += eval(member.rm_setting(:kill_ally))
    end
  end
  
  alias game_battler_item_effect_add_state_rm item_effect_add_state
  def item_effect_add_state(user, item, effect)
    original_states = states.clone
    game_battler_item_effect_add_state_rm(user, item, effect)
    return unless $game_party.in_battle
    if original_states != states && opponents_unit.members.include?(user)
      user.tp += eval(user.rm_setting(:deal_state))
      self.tp += eval(rm_setting(:gain_state))
    end
  end
  
  alias game_battler_item_apply_rm item_apply
  def item_apply(user, item)
    game_battler_item_apply_rm(user, item)
    return unless $game_party.in_battle
    return if @result.hit?
    self.tp += eval(rm_setting(:evasion))
  end
  
  alias game_battler_item_test_rm item_test
  def item_test(user, item)
    return false if item.for_dead_friend? != dead?
    return true if item.is_a?(RPG::Skill) && item.to_rm_mode != nil
    return game_battler_item_test_rm(user, item)
  end
  
  alias game_battler_item_user_effect_rm item_user_effect
  def item_user_effect(user, item)
    game_battler_item_user_effect_rm(user, item)
    if item.is_a?(RPG::Skill) && item.to_rm_mode != nil
      user.change_rage_mode(item.to_rm_mode)
      @result.success = true
    end
  end
  
  alias game_battler_on_battle_start_rm on_battle_start
  def on_battle_start
    game_battler_on_battle_start_rm
    @rage_mode_before = @rage_mode
    add_state(rm_setting(:state)) if rm_setting(:state) != 0
  end
  
  alias game_battler_on_battle_end_rm on_battle_end
  def on_battle_end
    remove_state(rm_setting(:state)) if rm_setting(:state) != 0
    @rage_mode = @rage_mode_before
    game_battler_on_battle_end_rm
  end
end

#==============================================================================
# Game_Actor
#==============================================================================

class Game_Actor < Game_Battler
  alias game_actor_setup_rm setup
  def setup(actor_id)
    game_actor_setup_rm(actor_id)
    @rage_mode = actor.rage_mode
    @unlocked_rage_modes = actor.unlocked_rage_modes.clone
  end
  
  def rage_mode
    @rage_mode = actor.rage_mode if @rage_mode.nil?
    return @rage_mode
  end
  
  def unlocked_rage_modes
    if @unlocked_rage_modes.empty?
      @unlocked_rage_modes = actor.unlocked_rage_modes.clone
    end
    return @unlocked_rage_modes.uniq
  end
  
  def change_rage_mode(mode)
    remove_state(rm_setting(:state)) if rm_setting(:state) != 0
    @rage_mode = mode
    unlock_rage_mode(mode)
    self.tp = 0 if Pear::RageMode::CHANGE_TP_RESET
    add_state(rm_setting(:state)) if rm_setting(:state) != 0
  end
  
  def unlock_rage_mode(mode)
    if @unlocked_rage_modes.empty?
      @unlocked_rage_modes = actor.unlocked_rage_modes.clone
    end
    @unlocked_rage_modes.push(mode)
    @unlocked_rage_modes.uniq!
    @unlocked_rage_modes.sort!
  end
  
  def remove_rage_mode(mode)
    if @unlocked_rage_modes.empty?
      @unlocked_rage_modes = actor.unlocked_rage_modes.clone
    end
    @unlocked_rage_modes.delete(mode)
    @rage_mode = @unlocked_rage_modes[0] if @rage_mode == mode
  end
  
  def has_rage_mode?(mode)
    return @unlocked_rage_modes.include?(mode)
  end
end

#==============================================================================
# Game_Enemy
#==============================================================================

class Game_Enemy < Game_Battler
  def rage_mode
    return enemy.rage_mode
  end
    
  def change_rage_mode(mode)
    remove_state(rm_setting(:state)) if rm_setting(:state) != 0
    @rage_mode = mode
    self.tp = 0 if Pear::RageMode::CHANGE_TP_RESET
    add_state(rm_setting(:state)) if rm_setting(:state) != 0
  end
end
  
#==============================================================================
# Game_Interpreter
#==============================================================================

class Game_Interpreter
  def change_rage_mode(actor_id, mode)
    $game_actors[actor_id].change_rage_mode(mode)
  end
  
  def unlock_rage_mode(actor_id, mode)
    $game_actors[actor_id].unlock_rage_mode(mode)
  end
  
  def remove_rage_mode(actor_id, mode)
    $game_actors[actor_id].remove_rage_mode(mode)
  end  
  
  def has_rage_mode?(actor_id, mode)
    return $game_actors[actor_id].has_rage_mode?(mode)
  end  
end

#==============================================================================
# Window_SkillCommand
#==============================================================================

class Window_SkillCommand < Window_Command
  alias window_skillcommand_make_command_list_rm make_command_list
  def make_command_list
    return unless @actor
    window_skillcommand_make_command_list_rm
    add_rm_modes
  end
  
  def add_rm_modes
    return unless Switch.rage_mode
    return unless SceneManager.scene_is?(Scene_Skill)
    add_command(Pear::RageMode::MENU_NAME, :rage_mode, true, :rage_mode)
  end
end

#==============================================================================
# Window_SkillList
#==============================================================================

class Window_SkillList < Window_Selectable
  def rage_mode?
    @stype_id == :rage_mode
  end
  
  def rage_mode
    return nil unless rage_mode?
    return @data[index]
  end
  
  alias window_skilllist_make_item_list_rm make_item_list
  def make_item_list
    if rage_mode?
      @data = @actor.unlocked_rage_modes
      @data.sort!
    else
      window_skilllist_make_item_list_rm
    end
  end
  
  alias window_skilllist_draw_item_rm draw_item
  def draw_item(index)
    if rage_mode?
      draw_rage_mode_item(index)
    else
      window_skilllist_draw_item_rm(index)
    end
  end
  
  def draw_rage_mode_item(index)
    rage_mode = @data[index]
    return unless Pear::RageMode::MODES.include?(rage_mode)
    rect = item_rect(index)
    rect.width -= 4
    icon = Pear::RageMode::MODES[rage_mode][:icon]
    draw_icon(icon, rect.x, rect.y)
    change_color(rage_mode_colour(rage_mode))
    name = Pear::RageMode::MODES[rage_mode][:name]
    draw_text(rect.x+24, rect.y, rect.width-24, line_height, name)
  end
  
  def rage_mode_colour(mode)
    if @actor.rage_mode == mode
      return text_color(Pear::RageMode::EQUIPPED_COLOR)
    else
      return normal_color
    end
  end
  
  alias window_skilllist_current_item_enabled current_item_enabled?
  def current_item_enabled?
    if rage_mode?
      return @actor.rage_mode != @data[index]
    else
      return window_skilllist_current_item_enabled
    end
  end
  
  alias window_skilllist_update_help_rm update_help
  def update_help
    if rage_mode?
      rage_mode = @data[index]
      if Pear::RageMode::MODES.include?(rage_mode)
        text = Pear::RageMode::MODES[rage_mode][:description]
      else
        text = ""
      end
      @help_window.set_text(text)
    else
      window_skilllist_update_help_rm
    end
  end
end

#==============================================================================
# Scene_Skill [Better put this into the book
#==============================================================================

class Scene_Skill < Scene_ItemBase
  alias scene_skill_create_command_window_rm create_command_window
  def create_command_window
    scene_skill_create_command_window_rm
    @command_window.set_handler(:rage_mode,    method(:command_skill))
  end
  
  alias scene_skill_on_item_ok_rm on_item_ok# Really need that one??
  def on_item_ok
    if @item_window.rage_mode?
      @status_window.refresh
      @item_window.refresh
      @item_window.activate
    else
      scene_skill_on_item_ok_rm
    end
  end
end

#==============================================================================
# Window_BattleStatus [DEBUG]
#==============================================================================

#class Window_BattleStatus < Window_Selectable
#  alias window_battlestatus_draw_item_rm draw_item
#  def draw_item(index)
#    window_battlestatus_draw_item_rm(index)
#    actor = $game_party.battle_members[index]
#    draw_text(100, 0, 100, 20, Pear::RageMode::MODES[actor.rage_mode][:name])
#  end
#end