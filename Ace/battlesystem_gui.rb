#==============================================================================
#    Pear Battle System
#    Module: GUI
#    Version: 1.0.0
#    Author: pearcoding
#    Date: 19.08.2015
#==============================================================================

$bs_module["GUI"] = true

#==============================================================================
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# !!!          Everything after this is not for casual editing.            !!!
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#==============================================================================

# Check if GUI is allowed
if Pear::BattleSystem::USE_GUI_MODULE 

#==============================================================================
# ◆ Window section
#==============================================================================

#==============================================================================
# ■ Window_BattleStatus
#==============================================================================

class Window_BattleStatus < Window_Selectable
  #----------------------------------------------------------------------------
  # + initialize
  # Object Initialization
  #----------------------------------------------------------------------------
  alias window_battlestatus_p_bs_gui initialize
  def initialize
    window_battlestatus_p_bs_gui
    self.arrows_visible = false
    self.opacity = 0
  end
    
  #----------------------------------------------------------------------------
  # ~ window_width
  #----------------------------------------------------------------------------
  def window_width
    return Graphics.width
  end
    
  #----------------------------------------------------------------------------
  # ~ window_height
  #----------------------------------------------------------------------------
  def window_height
    return item_height
  end
    
  #----------------------------------------------------------------------------
  # ~ spacing
  #----------------------------------------------------------------------------
  def spacing
    return 8
  end
    
  #----------------------------------------------------------------------------
  # ~ col_max
  #----------------------------------------------------------------------------
  def col_max
    return item_max
  end
    
  #----------------------------------------------------------------------------
  # ~ item_width
  #----------------------------------------------------------------------------
  def item_width
    return 64
  end
    
  #----------------------------------------------------------------------------
  # ~ item_height
  #----------------------------------------------------------------------------
  def item_height
    return face_height + data_height
  end
    
  #----------------------------------------------------------------------------
  # + face_height
  #----------------------------------------------------------------------------
  def face_height
    return 64
  end
    
  #----------------------------------------------------------------------------
  # + data_height
  #----------------------------------------------------------------------------
  def data_height
    return fitting_height(visible_data_lines)
  end
    
  #----------------------------------------------------------------------------
  # * visible_data_lines
  #----------------------------------------------------------------------------
  def visible_data_lines
    return 2 + ($data_system.opt_display_tp ? 1 : 0) +
            ($bs_module["ActiveTimeBattle"] && Pear::BattleSystem::SHOW_AVL ? 1 : 0)
  end
    
  #----------------------------------------------------------------------------
  # * face_area_rect
  # Get Face Area Retangle
  #----------------------------------------------------------------------------
  def face_area_rect(index)
    rect = item_rect(index)
    rect.height = face_height
    return rect
  end
    
  #----------------------------------------------------------------------------
  # * data_area_rect
  # Get Data Area Rectangle
  #----------------------------------------------------------------------------
  def data_area_rect(index)#TODO
    rect = item_rect(index)
    rect.y = face_height
    rect.height = data_height
    return rect
  end
    
  #----------------------------------------------------------------------------
  # ~ draw_item
  #----------------------------------------------------------------------------
  def draw_item(index)
    actor = $game_party.battle_members[index]
    draw_face_area(face_area_rect(index), actor)
    draw_data_area(data_area_rect(index), actor)
  end
   
  #----------------------------------------------------------------------------
  # * draw_face_area
  #----------------------------------------------------------------------------
  def draw_face_area(rect, actor)
    draw_actor_face_ex(actor, rect)
  draw_actor_name(actor, rect.x, rect.y, rect.width)
  end
    
  #----------------------------------------------------------------------------
  # * draw_data_area
  #----------------------------------------------------------------------------
  def draw_data_area(rect, actor)
    draw_actor_hp(actor, rect.x, rect.y + line_height * 0, rect.width)
    draw_actor_mp(actor, rect.x, rect.y + line_height * 1, rect.width)
        
    if $data_system.opt_display_tp
      draw_actor_tp(actor, rect.x, rect.y + line_height * 2, rect.width)
    end
        
    if $bs_module["ActiveTimeBattle"] &&
            Pear::BattleSystem::USE_ACTIVE_TIME_BATTLE_MODULE &&
            Pear::BattleSystem::SHOW_AVL
      if $data_system.opt_display_tp
        draw_actor_avl(actor, rect.x, rect.y + line_height * 3, rect.width)
      else
        draw_actor_avl(actor, rect.x, rect.y + line_height * 2, rect.width)
      end
    end
  end
    
  #----------------------------------------------------------------------------
  # * draw_actor_face_ex
  # New drawing method based on KGC Bitmap Extension
  #----------------------------------------------------------------------------
  def draw_actor_face_ex(actor, rect, enabled = true)
    bitmap = Cache.face(actor.face_name)
    nrect = Rect.new(actor.face_index % 4 * 96, actor.face_index / 4 * 96,
                                96, 96)
    contents.stretch_blt_r(rect, bitmap, nrect, enabled ? 255 : translucent_alpha)
    bitmap.dispose
  end
    
  #--------------------------------------------------------------------------
  # * draw_actor_avl
  # Draw AVL
  #--------------------------------------------------------------------------
  def draw_actor_avl(actor, x, y, width)
    draw_gauge(x, y, width, actor.battle_avl, hp_gauge_color1, hp_gauge_color2)
    change_color(system_color)
    draw_text(x, y, 30, line_height, "AVL")
    draw_current_and_max_values(x, y, width, actor.battle_avl,
            Pear::BattleSystem::MAX_AVL,
      hp_color(actor), normal_color)
  end
end

#==============================================================================
# ■ Window_BattleLog
#==============================================================================

class Window_BattleLog < Window_Selectable
  #----------------------------------------------------------------------------
  # + draw_background
  # Added little update/fix to ensure background and content sync
  #----------------------------------------------------------------------------
  alias window_battlelog_draw_background_p_bs_gui draw_background
  def draw_background
    @back_sprite.y = y
    window_battlelog_draw_background_p_bs_gui
  end
end

#==============================================================================
# ◆ Scene section
#==============================================================================

#==============================================================================
# ■ Scene_Battle
#==============================================================================

class Scene_Battle
  #----------------------------------------------------------------------------
  # ~ update_info_viewport
  # We are not moving around... 
  #----------------------------------------------------------------------------
  def update_info_viewport
  end
    
  #----------------------------------------------------------------------------
  # ~ create_status_window
  #----------------------------------------------------------------------------
  def create_status_window
    @status_window = Window_BattleStatus.new
    @status_window.x = Pear::BattleSystem::STATUS_WINDOW_OFF_X
    @status_window.y = Pear::BattleSystem::STATUS_WINDOW_OFF_Y
    @status_window.z = 150
  end
    
  #----------------------------------------------------------------------------
  # + create_log_window
  #----------------------------------------------------------------------------
  alias scene_battle_create_log_window_p_bs_gui create_log_window
  def create_log_window
    scene_battle_create_log_window_p_bs_gui
    @log_window.y = Graphics.height - @log_window.window_height - 5
  end
    
  #----------------------------------------------------------------------------
  # ~ create_info_viewport
  # Do not like it... will kill it -_-
  #----------------------------------------------------------------------------
  def create_info_viewport
    @info_viewport = Viewport.new
    @info_viewport.z = 100
    #@status_window.viewport = @info_viewport
  end
end

end # USE_GUI_MODULE 