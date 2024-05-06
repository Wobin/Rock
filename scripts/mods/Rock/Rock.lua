--[[
Title: Rock
Author: Wobin
Date: 18/04/2024
Repository: https://github.com/Wobin/Rock
Version: 3.0
]]--

local CharacterSheet = require("scripts/utilities/character_sheet")
local mod = get_mod("Rock")
local Audio
local audio_files
local HoldingRock
local player
local friendgryn = "friend"
local impact = "impact"
local pickup = "find"
  
local class_loadout = {
	ability = {},
	blitz = {},
	aura = {}
}


mod.weOgryn = function()
    player = Managers.player:local_player(1)  
    if not player then return false end
    if not mod.ogrynVoice and player:profile().archetype.breed == "ogryn" then
      mod.ogrynVoice = player:profile().selected_voice
    end
    return player:profile().archetype.breed == "ogryn"     
end

mod.doIHaveRock = function()
  local profile = player:profile()    
	CharacterSheet.class_loadout(profile, class_loadout)
  return class_loadout and class_loadout.grenade_ability and class_loadout.grenade_ability.name and class_loadout.grenade_ability.name == "ogryn_grenade_friend_rock"
end

mod.friendShout = function (self, attacking_unit)
  local player_manager = Managers.player
	local players = player_manager:players()  
  local count = 1
  for i,member in pairs(players) do            
    if member ~= player and member:is_human_controlled() and member._profile.archetype.breed == "ogryn" and (not attacking_unit or (attacking_unit and member.player_unit ~= attacking_unit)) then                  
          Promise.delay(2 + (0.5 * count)):next(function() Audio.play("loc_"..(member:profile().selected_voice or "ogryn_a") .."__blitz_rock_a_"..string.format("%02d", math.random(1,10)), member.player_unit) end)
          count = count + 1
    end
  end    
end

mod.shoutRock = function(self, delta, override)    
    if (override or HoldingRock) and (delta == nil or delta > 0.1) then                
       Promise.delay(0.5):next(function() Audio.play("loc_".. mod.ogrynVoice .."__blitz_rock_a_"..string.format("%02d", math.random(1,10))) end)
        if mod:get("friend_ogryn") then          
          mod:friendShout(override)
        end
       return false
    end
    return true
end

mod.getBonk = function()
  if mod:get("single_bonk_noise") then 
    return "impact/bonk_AgRFvsD.mp3" 
  end
  return audio_files:random(impact)  
end

mod.bonkRock = function(self, source)
  if HoldingRock or mod:get("hear_all_bonk") then       
      Audio.play_file(mod:getBonk(), { audio_type = "sfx"}, source, 0.001, 100)                
      return false
  end
end

mod.pickupRock = function(self, delta)
  if delta == nil or delta > 0.1 then
    Audio.play_file(audio_files:random(pickup), { audio_type = "sfx" })                
  end
end



mod.on_all_mods_loaded = function()
    Audio = get_mod("Audio")    
    audio_files = Audio.new_files_handler()
    
    -- Hook the rock tossing --
    mod:hook_require("scripts/extension_systems/weapon/actions/action_throw_grenade", function(altFire)
      mod:hook_safe(altFire, "start", function(self, ...)              
        HoldingRock = mod:weOgryn() and self and self._weapon_template and self._weapon_template.projectile_template and self._weapon_template.projectile_template.name == "ogryn_grenade_friend_rock"        
      end)
    end)
    
    Audio.hook_sound("wwise/events/weapon/stop_player_combat_weapon_grenader_loop", function(_, _, delta)
        if mod:weOgryn() and HoldingRock then                  
          HoldingRock = mod:shoutRock(delta)
        end      
      return true
    end)

    Audio.hook_sound("_blitz_rock_a", function() return false end)
    
     -- Hook when rock regenerates
    Audio.hook_sound("wwise/events/player/play_player_grenade_charge_restored_gen", function(_, _, delta)
        if mod:weOgryn() and mod:get("rock_pickup") and mod:doIHaveRock() then          
          mod:pickupRock()
        end      
      return true
    end)     
  
  mod:hook_safe(CLASS.FxSystem, "play_impact_fx", function( self,
        impact_fx,
        position,
        direction,
        source_parameters,
        attacking_unit,
        optional_target_unit)
    if impact_fx.name:match("ogryn_friend_rock") then
      if (mod:get("amusing_bonk") and mod:weOgryn()) or mod:get("hear_all_bonk") then                         
        if mod:get("hear_all_bonk") or (mod:get("amusing_bonk") and attacking_unit == Managers.player:local_player(1).player_unit) then                    
          mod:bonkRock(position) 
          if attacking_unit ~= Managers.player:local_player(1).player_unit and mod:get("respond_to_all_bonk") and mod:weOgryn() then            
            mod:shoutRock(1, attacking_unit)
          end
        end
      end   
    end
  end)  
end
