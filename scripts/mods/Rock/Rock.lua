--[[
Title: Rock
Author: Wobin
Date: 07/10/2023
Repository: https://github.com/Wobin/Rock
Version: 1.0
]]--

local CharacterSheet = require("scripts/utilities/character_sheet")
local mod = get_mod("Rock")
local Audio
local WeOgryn = false
local HoldingRock
local player
local math_random = math.random
local rockShouts = {
  "noise/OgrynNoise-01.opus",
  "noise/OgrynNoise-02.opus",
  "noise/OgrynNoise-03.opus",
  "noise/OgrynNoise-04.opus",
  "noise/OgrynNoise-05.opus",
  "noise/OgrynNoise-06.opus",
  "noise/OgrynNoise-07.opus",
  "noise/OgrynNoise-08.opus",
  "noise/OgrynNoise-09.opus",
  "noise/OgrynNoise-10.opus",
  "noise/OgrynNoise-11.opus",
  "noise/OgrynNoise-12.opus",
  "noise/OgrynNoise-13.opus",
  "noise/OgrynNoise-14.opus",
  "noise/OgrynNoise-15.opus",
  "noise/OgrynNoise-16.opus",
  "noise/OgrynNoise-17.opus",
  "noise/OgrynNoise-18.opus",
  "noise/OgrynNoise-19.opus",
  "noise/OgrynNoise-20.opus",
  "noise/OgrynNoise-21.opus",
}
local friendgryn = {
  "friend/friendgryn-01.opus",
  "friend/friendgryn-02.opus",
  "friend/friendgryn-03.opus",
  "friend/friendgryn-04.opus",
  "friend/friendgryn-05.opus",
  "friend/friendgryn-06.opus",
  "friend/friendgryn-07.opus",
  "friend/friendgryn-08.opus",
  }
local impact = {
  "impact/bonk_AgRFvsD.mp3",
  "impact/bonk-99378.mp3",
  "impact/bonk-sound-effect.mp3",
  "impact/bonk-sound-effect-36055.mp3",
  "impact/metallic-clang-100473.mp3",
  "impact/mixkit-cartoon-blow-impact-2654.wav",
  "impact/mixkit-cartoon-clown-fun-nose-sound-528.wav",
  "impact/mixkit-cartoon-spring-sound-736.wav",
  "impact/mixkit-cartoon-toy-whistle-616.wav",
  "impact/mixkit-funny-clown-horn-sounds-2886.wav",
  "impact/mixkit-hard-pop-click-2364.wav",
  "impact/mixkit-metallic-boing-hit-2895.wav",
  "impact/mixkit-spinning-whistle-toy-2647.wav",
  "impact/hit-with-frying-pan-39340.mp3",
}
local pickup = {
   "find/Charlie Brown_ I got a rock.opus",
   "find/found-01.opus",
   "find/found-02.opus",
  }
  
local class_loadout = {
	ability = {},
	blitz = {},
	aura = {}
}
local lastshout
local lastbonk
local lastpickup

local shoutRock = function(delta)  
    if HoldingRock and (delta == nil or delta > 0.1) then       
       local ran = table.get_random_array_indices(#rockShouts,1)
       if ran[1] == lastshout then
         ran = table.get_random_array_indices(#rockShouts,1)
       end
       lastshout = ran[1]
       Audio.play_file(rockShouts[ran[1]], { audio_type = "sfx", adelay = "20000|20000", chorus = "0.6:0.9:50|60:0.4|0.32:0.25|0.4:2|1.3",volume = 100,silenceremove = "start_periods=1:stop_periods=1", })       
        if mod:get("friend_ogryn") then
          mod:FindFrendgryn()
        end
       return false
    end
    return true
end

local getBonk = function()
  if mod:get("single_bonk_noise") then 
    return "impact/bonk_AgRFvsD.mp3" 
  end
  local ran = table.get_random_array_indices(#impact,1)
  if ran[1] == lastbonk then
    ran = table.get_random_array_indices(#impact,1)
  end  
  lastbonk = ran[1]
  return impact[ran[1]]  
end

local getPickup = function()
    local ran = table.get_random_array_indices(#pickup,1)
  if ran[1] == lastPickup then
    ran = table.get_random_array_indices(#pickup,1)
  end  
  lastPickup = ran[1]
  return pickup[ran[1]]  
end

local bonkRock = function(delta, source)
  if HoldingRock and (delta == nil or delta > 0.1) then       
      Audio.play_file(getBonk(), { audio_type = "sfx", silenceremove = "start_periods=1:stop_periods=1",volume = 100, })                
      return false
  end
end

local pickupRock = function(delta)
  if delta == nil or delta > 0.1 then
    Audio.play_file(getPickup(), { audio_type = "sfx", silenceremove = "start_periods=1:stop_periods=1",volume = 100, })                
  end
end



local doIHaveRock = function()
  local profile = player:profile()    
	CharacterSheet.class_loadout(profile, class_loadout)
  return class_loadout and class_loadout.grenade_ability and class_loadout.grenade_ability.name and class_loadout.grenade_ability.name == "ogryn_grenade_friend_rock"
end

mod.FindFriendgryn = function(self)
  
end

mod.on_game_state_changed = function(status, state_name) 
  if state_name == "GameplayStateRun" and status == "enter" then    
    player = Managers.player:local_player(1)  
    WeOgryn = player:profile().archetype.breed == "ogryn"     
  end    
end
  
mod.on_all_mods_loaded = function()
    Audio = get_mod("Audio")    
    -- Hook the rock tossing --
    mod:hook_require("scripts/extension_systems/weapon/actions/action_throw_grenade", function(altFire)
      mod:hook_safe(altFire, "start", function(self, ...)              
        HoldingRock = WeOgryn and self and self._weapon_template and self._weapon_template.projectile_template and self._weapon_template.projectile_template.name == "ogryn_grenade_friend_rock"
      end)
    end)
    
    Audio.hook_sound("wwise/events/weapon/stop_player_combat_weapon_grenader_loop", function(_, _, delta)
        if WeOgryn and HoldingRock then
          HoldingRock = shoutRock(delta)
        end      
      return true
    end)

    Audio.hook_sound("wwise/events/weapon/play_ogryn_grenade_rock_impact", function(_, _, delta)
        if WeOgryn and mod:get("amusing_bonk") and  HoldingRock then
          bonkRock(delta, "play_ogryn_grenade_rock_impact")
        end      
      return false
    end) 
    -- Hook when rock regenerates
    Audio.hook_sound("wwise/events/player/play_player_grenade_charge_restored_gen", function(_, _, delta)
        if WeOgryn and mod:get("rock_pickup") and doIHaveRock() then
          pickupRock()
        end      
      return true
    end)   
end
