--[[
Title: Rock
Author: Wobin
Date: 28/06/2026
Repository: https://github.com/Wobin/Rock
]]--

local CharacterSheet = require("scripts/utilities/character_sheet")
local mod = get_mod("Rock")
mod.version = mod.get_metadata and mod:get_metadata("version") or "unknown"
local SimpleAudio
local HoldingRock
local player
local math_random = math.random

local IMPACT_EXTENSIONS = { "mp3", "wav" }
local FIND_EXTENSIONS = { "opus" }
local impact_files = {}
local find_files = {}

local BONK_VOLUME = 100
local BONK_MIN_DISTANCE = 0
local BONK_MAX_DISTANCE = 100
local BONK_DECAY = 0.001

local function build_playlist(category, extensions)
  local list = {}
  if not (SimpleAudio and SimpleAudio.glob) then return list end
  for _, ext in ipairs(extensions) do
    local pattern = "mods/Rock/audio/"..category.."/*."..ext
    local ok, result = pcall(SimpleAudio.glob, pattern)
    if ok and result then
      for _, path in ipairs(result:list()) do
        list[#list + 1] = path
      end
    end
  end
  return list
end

local function random_track(list)
  local n = #list
  if n == 0 then return nil end
  return list[math_random(n)]
end

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
          Promise.delay(2 + (0.5 * count)):next(function() SimpleAudio.play("loc_"..(member:profile().selected_voice or "ogryn_a") .."__blitz_rock_a_"..string.format("%02d", math.random(1,10)), member.player_unit) end)
          count = count + 1
    end
  end    
end

mod.shoutRock = function(self, delta, override)    
    if (override or HoldingRock) and (delta == nil or delta > 0.1) then                
       Promise.delay(0.5):next(function() SimpleAudio.play("loc_".. mod.ogrynVoice .."__blitz_rock_a_"..string.format("%02d", math.random(1,10))) end)
        if mod:get("friend_ogryn") then          
          mod:friendShout(override)
        end
       return false
    end
    return true
end

mod.getBonkRelative = function()
  if mod:get("single_bonk_noise") then
    return "mods/Rock/audio/impact/bonk_AgRFvsD.mp3"
  end
  return random_track(impact_files)
end

mod.playBonkSpatial = function(self, source)
  if not (SimpleAudio and SimpleAudio.play_file) then return false end
  local rel = mod:getBonkRelative()
  if not rel then return false end
  local ok, id = pcall(SimpleAudio.play_file, rel, { audio_type = "sfx", volume = BONK_VOLUME }, source, BONK_DECAY, BONK_MIN_DISTANCE, BONK_MAX_DISTANCE)
  return (ok and id) and true or false
end

mod.bonkRock = function(self, source)
  if HoldingRock or mod:get("hear_all_bonk") then
      mod:playBonkSpatial(source)
      return false
  end
end

mod.pickupRock = function(self, delta)
  if (delta == nil or delta > 0.1) and SimpleAudio and SimpleAudio.play_file then
    local path = random_track(find_files)
    if path then
      SimpleAudio.play_file(path, { audio_type = "sfx" })
    end
  end
end



mod.on_all_mods_loaded = function()
    SimpleAudio = get_mod("SimpleAudio")
    if not SimpleAudio then
      mod:error("Rock requires the SimpleAudio mod - please install and enable it.")
      return
    end
    impact_files = build_playlist("impact", IMPACT_EXTENSIONS)
    find_files = build_playlist("find", FIND_EXTENSIONS)

    mod:hook_require("scripts/extension_systems/weapon/actions/action_throw_grenade", function(altFire)
      mod:hook_safe(altFire, "start", function(self, ...)              
        HoldingRock = mod:weOgryn() and self and self._weapon_template and self._weapon_template.projectile_template and self._weapon_template.projectile_template.name == "ogryn_grenade_friend_rock"        
      end)
    end)
    
    SimpleAudio.hook_sound("wwise/events/weapon/stop_player_combat_weapon_grenader_loop", function(_, _, delta)
        if mod:weOgryn() and HoldingRock then
          HoldingRock = mod:shoutRock(delta)
        end
      return true
    end)

    SimpleAudio.hook_sound("_blitz_rock_a", function() return false end)

    SimpleAudio.hook_sound("wwise/events/player/play_player_grenade_charge_restored_gen", function(_, _, delta)
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
