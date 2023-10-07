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
local audios = {
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

local shoutRock = function(delta)  
    if HoldingRock and (delta == nil or delta > 0.1) then       
       table.shuffle(audios, math_random() )       
       Audio.play_file(audios[1], { audio_type = "sfx", adelay = "20000|20000", chorus = "0.6:0.9:50|60:0.4|0.32:0.25|0.4:2|1.3",volume = 100,silenceremove = "start_periods=1:stop_periods=1", })                
       return false
    end
    return true
end
mod.on_all_mods_loaded = function()
  Audio = get_mod("Audio")
  
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

end
