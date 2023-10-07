--[[
Title: Rock
Author: Wobin
Date: 07/10/2023
Repository: https://github.com/Wobin/Rock
]]--

local mod = get_mod("Rock")
local Audio
local HoldingRock
local math_random = math.random
local rockShouts = {
  "OgrynNoise-01.opus",
  "OgrynNoise-02.opus",
  "OgrynNoise-03.opus",
  "OgrynNoise-04.opus",
  "OgrynNoise-05.opus",
  "OgrynNoise-06.opus",
  "OgrynNoise-07.opus",
  "OgrynNoise-08.opus",
  "OgrynNoise-09.opus",
  "OgrynNoise-10.opus",
  "OgrynNoise-11.opus",
  "OgrynNoise-12.opus",
  "OgrynNoise-13.opus",
  "OgrynNoise-14.opus",
  "OgrynNoise-15.opus",
  "OgrynNoise-16.opus",
  "OgrynNoise-17.opus",
  "OgrynNoise-18.opus",
  "OgrynNoise-19.opus",
  "OgrynNoise-20.opus",
  "OgrynNoise-21.opus",
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
local lastshout
local shoutRock = function(delta)  
    if HoldingRock and (delta == nil or delta > 0.1) then       
       local ran = table.get_random_array_indices(#rockShouts,1)
       if ran[1] == lastshout then
         ran = table.get_random_array_indicies(#rockShouts,1)
       end
       lastshout = ran[1]
       Audio.play_file(rockShouts[ran[1]], { audio_type = "sfx", adelay = "20000|20000", chorus = "0.6:0.9:50|60:0.4|0.32:0.25|0.4:2|1.3",volume = 100,silenceremove = "start_periods=1:stop_periods=1", })       
       return false
    end
    return true
end

local lastbonk

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

local bonkRock = function(delta, source)
  if HoldingRock and (delta == nil or delta > 0.1) then       
      Audio.play_file(getBonk(), { audio_type = "sfx", silenceremove = "start_periods=1:stop_periods=1",volume = 100, })                
      return false
  end
end

mod.on_all_mods_loaded = function()
  Audio = get_mod("Audio")
  Audio.hook_sound("wwise/events/weapon/melee_hits_blunt_heavy", function(_, _, delta)
  
  end)
-- Hook the rock tossing --
  mod:hook_require("scripts/extension_systems/weapon/actions/action_throw_grenade", function(altFire)
    mod:hook_safe(altFire, "start", function(self, ...)              
      HoldingRock = self and self._weapon_template and self._weapon_template.projectile_template and self._weapon_template.projectile_template.name == "ogryn_grenade_friend_rock"                     
    end)
  end)
  
  Audio.hook_sound("wwise/events/weapon/stop_player_combat_weapon_grenader_loop", function(_, _, delta)
      if HoldingRock then
        HoldingRock = shoutRock(delta)
      end      
    return true
  end)

  Audio.hook_sound("wwise/events/weapon/play_ogryn_grenade_rock_impact", function(_, _, delta)
      if mod:get("amusing_bonk") and  HoldingRock then
        bonkRock(delta, "play_ogryn_grenade_rock_impact")
      end      
    return false
  end)

end
