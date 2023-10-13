--[[
Title: Rock
Author: Wobin
Date: 12/10/2023
Repository: https://github.com/Wobin/Rock
Version: 2.0
]]--

local CharacterSheet = require("scripts/utilities/character_sheet")
local mod = get_mod("Rock")
local Audio

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
   "find/fatherted.opus",
   "find/a-rock.opus",
   "find/rock-and-stone.opus",
  }
  
local class_loadout = {
	ability = {},
	blitz = {},
	aura = {}
}
local lastshout
local lastfriend
local lastbonk
local lastpickup

local WeOgryn = function()
    player = Managers.player:local_player(1)  
    if not player then return false end
    return player:profile().archetype.breed == "ogryn"     
end

local getRandomSound = function(soundPool, lastShout)
  local ran = table.get_random_array_indices(#soundPool,1)
  if ran[1] == lastShout then
     ran = table.get_random_array_indices(#soundPool,1)
  end
  lastShout = ran[1]
  return soundPool[ran[1]]
end

mod.FriendShout = function (attacking_unit)
  local player_manager = Managers.player
	local players = player_manager:players()  
  for i,member in pairs(players) do            
    if member ~= player and member:is_human_controlled() and member._profile.archetype.breed == "ogryn" and (not attacking_unit or (attacking_unit and member.player_unit ~= attacking_unit)) then          
          Audio.play_file(getRandomSound(friendgryn, lastfriend), { audio_type = "sfx", adelay = "1200|1200", chorus = "0.6:0.9:50|60:0.4|0.32:0.25|0.4:2|1.3" }, member.player_unit, 0.001, 100)        
    end
  end    
end

local shoutRock = function(delta, override)    
    if (override or HoldingRock) and (delta == nil or delta > 0.1) then             
       Audio.play_file(getRandomSound(rockShouts, lastshout), { audio_type = "sfx", adelay = "500|500", chorus = "0.6:0.9:50|60:0.4|0.32:0.25|0.4:2|1.3", })       
        if mod:get("friend_ogryn") then          
          mod:FriendShout(override)
        end
       return false
    end
    return true
end

local getBonk = function()
  if mod:get("single_bonk_noise") then 
    return "impact/bonk_AgRFvsD.mp3" 
  end
  return getRandomSound( impact, lastbonk)  
end

local bonkRock = function(source)
  if HoldingRock then       
      Audio.play_file(getBonk(), { audio_type = "sfx"}, source, 0.001, 100)                
      return false
  end
end

local pickupRock = function(delta)
  if delta == nil or delta > 0.1 then
    Audio.play_file(getRandomSound(pickup, lastpickup), { audio_type = "sfx" })                
  end
end

local doIHaveRock = function()
  local profile = player:profile()    
	CharacterSheet.class_loadout(profile, class_loadout)
  return class_loadout and class_loadout.grenade_ability and class_loadout.grenade_ability.name and class_loadout.grenade_ability.name == "ogryn_grenade_friend_rock"
end


mod.on_all_mods_loaded = function()
    Audio = get_mod("Audio")    
    -- Hook the rock tossing --
    mod:hook_require("scripts/extension_systems/weapon/actions/action_throw_grenade", function(altFire)
      mod:hook_safe(altFire, "start", function(self, ...)              
        HoldingRock = WeOgryn() and self and self._weapon_template and self._weapon_template.projectile_template and self._weapon_template.projectile_template.name == "ogryn_grenade_friend_rock"        
      end)
    end)
    
    Audio.hook_sound("wwise/events/weapon/stop_player_combat_weapon_grenader_loop", function(_, _, delta)
        if WeOgryn() and HoldingRock then
          HoldingRock = shoutRock(delta)
        end      
      return true
    end)

     -- Hook when rock regenerates
    Audio.hook_sound("wwise/events/player/play_player_grenade_charge_restored_gen", function(_, _, delta)
        if WeOgryn() and mod:get("rock_pickup") and doIHaveRock() then
          pickupRock()
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
      if (mod:get("amusing_bonk") and (WeOgryn() and HoldingRock)) or mod:get("hear_all_bonk") then          
        bonkRock(position)
        if attacking_unit ~= Managers.player:local_player(1).player_unit and mod:get("respond_to_all_bonk") then
          shoutRock(1, attacking_unit)
        end
      end   
    end
  end)
end
