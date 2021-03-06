// ======= Copyright � 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Player_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/HudTooltips.lua")
Script.Load("lua/DSPEffects.lua")

Player.kFeedbackFlash = "ui/feedback.swf"
Player.kSharedHUDFlash = "ui/shared_hud.swf"

Player.kDamageCameraShakeAmount = 0.01
Player.kDamageCameraShakeSpeed = 30
Player.kDamageCameraShakeTime = 0.1
// The amount of health left before the low health warning
// screen effect is active
Player.kLowHealthWarning = 0.35
Player.kLowHealthPulseSpeed = 10

gFlashPlayers = nil

/**
 * Get setup data for crosshairs
 * Returns modified key, value pairs in single dimensional array
 * Changes are applied only to current frame
 *
 * "mask", <maskname>
 * "scale", [1 - ???]
 * "cameraShake", [0 - ???]
 * "targetHit", [alpha, 0-1]
 * "target", [alpha, 0-1]
 * 
 */
function PlayerUI_GetCrosshairValues()

   local crosshairValues = {}
   
   local player = Client.GetLocalPlayer()
   if(player ~= nil) then
   
        local weapon = player:GetActiveWeapon()
        
        // Grow crosshair to account for inaccuracy/recoil
        if(weapon ~= nil) then

            // Don't show inaccuracy in reticle until we can get it looking better        
            local inaccuracyScalar = 1 //= weapon:GetInaccuracyScalar()
            table.insert(crosshairValues, "scale")
            table.insert(crosshairValues, inaccuracyScalar)
            
            table.insert(crosshairValues, "cameraShake")
            table.insert(crosshairValues, math.max(0, (inaccuracyScalar - 1)*.005))
            
        end
        
        // Draw hit indicator
        local kDrawReticleHitTime = .25
        local time = player:GetTimeTargetHit()
        if(time ~= 0 and (Shared.GetTime() - time < kDrawReticleHitTime)) then
        
            table.insert(crosshairValues, "targetHit")
            table.insert(crosshairValues, 1)        
            
        end
        
        // Draw reticle differently if we have live target under crosshairs
        if(player:GetReticleTarget()) then
        
            table.insert(crosshairValues, "target")
            table.insert(crosshairValues, 1)        
            
        end
        
   end
   
   return crosshairValues
   
end

/**
 * Get waypoint data
 * Returns single-dimensional array of fields in the format screenX, screenY, drawRadius, waypointType
 */
function PlayerUI_GetWaypointInfo()
    return {}   
end

function PlayerUI_GetNextWaypointActive()

    local player = Client.GetLocalPlayer()
    return player ~= nil and player.nextOrderWaypointActive and not player:isa("Commander")

end

/**
 * Gives the UI the screen space coordinates of where to display
 * the next waypoint for when players have an order location
 */
function PlayerUI_GetNextWaypointInScreenspace()

    local player = Client.GetLocalPlayer()
    
    local playerEyePos = Vector(player:GetCameraViewCoords().origin)
    local playerForwardNorm = Vector(player:GetCameraViewCoords().zAxis)
    
    // This method needs to use the previous updates player info
    if(player.lastPlayerEyePos == nil) then
        player.lastPlayerEyePos = Vector(playerEyePos)
        player.lastPlayerForwardNorm = Vector(playerForwardNorm)
    end
    
    local screenPos = Client.WorldToScreen(player.nextOrderWaypoint)
    
    local isInScreenSpace = false
    local nextWPDir = player.nextOrderWaypoint - player.lastPlayerEyePos
    local normToEntityVec = GetNormalizedVectorXZ(nextWPDir)
    local normViewVec = GetNormalizedVectorXZ(player.lastPlayerForwardNorm)
    local dotProduct = normToEntityVec:DotProduct(normViewVec)
    
    // Distance is used for scaling
    local nextWPDist = nextWPDir:GetLength()
    local nextWPMaxDist = 25
    local nextWPScale = math.max(0.5, 1 - (nextWPDist / nextWPMaxDist))
    
    if(player.nextWPInScreenSpace == nil) then
    
        player.nextWPInScreenSpace = true
        player.nextWPDoingTrans = false
        player.nextWPLastVal = { }
        
        for i = 1, 5 do 
            player.nextWPLastVal[i] = 0
        end
        
        player.nextWPCurrWP = Vector(player.nextOrderWaypoint)
        
    end
    
    // If the waypoint has changed, do a smooth transition
    if(player.nextWPCurrWP ~= player.nextOrderWaypoint) then
    
        player.nextWPDoingTrans = true
        VectorCopy(player.nextOrderWaypoint, player.nextWPCurrWP)
        
    end
    
    local returnTable = nil

    // If offscreen, fallback on compass method
    local minWidthBuff = Client.GetScreenWidth() * 0.1
    local minHeightBuff = Client.GetScreenHeight() * 0.1
    local maxWidthBuff = Client.GetScreenWidth() * 0.9
    local maxHeightBuff = Client.GetScreenHeight() * 0.9
    if(screenPos.x < minWidthBuff or screenPos.x > maxWidthBuff or
    
       screenPos.y < minHeightBuff or screenPos.y > maxHeightBuff or dotProduct < 0) then
       
        if(player.nextWPInScreenSpace) then
        
            player.nextWPDoingTrans = true
            
        end
        player.nextWPInScreenSpace = false

        local eyeForwardPos = player.lastPlayerEyePos + (player.lastPlayerForwardNorm * 5)
        local eyeForwardToWP = player.nextOrderWaypoint - eyeForwardPos
        eyeForwardToWP:Normalize()
        local eyeForwardToWPScreen = Client.WorldToScreen(eyeForwardPos + eyeForwardToWP)
        local middleOfScreen = Vector(Client.GetScreenWidth() / 2, Client.GetScreenHeight() / 2, 0)
        local screenSpaceDir = eyeForwardToWPScreen - middleOfScreen
        screenSpaceDir:Normalize()
        local finalScreenPos = middleOfScreen + Vector(screenSpaceDir.x * (Client.GetScreenWidth() / 2), screenSpaceDir.y * (Client.GetScreenHeight() / 2), 0)
        // Clamp to edge of screen with buffer
        finalScreenPos.x = Clamp(finalScreenPos.x, minWidthBuff, maxWidthBuff)
        finalScreenPos.y = Clamp(finalScreenPos.y, minHeightBuff, maxHeightBuff)
        returnTable = { finalScreenPos.x, finalScreenPos.y, 3.14, nextWPScale, nextWPDist }
        
    else
    
        isInScreenSpace = true
        if(not player.nextWPInScreenSpace) then
        
            player.nextWPDoingTrans = true
            
        end
        player.nextWPInScreenSpace = true
        
        local bounceY = screenPos.y + (math.sin(Shared.GetTime() * 3) * (30 * nextWPScale))
        returnTable = { screenPos.x, bounceY, 3.14, nextWPScale, nextWPDist }
        
    end
    
    if(player.nextWPDoingTrans) then
    
        local replaceTable = { }
        local allEqual = true
        for i = 1, 5 do
        
            replaceTable[i] = Slerp(player.nextWPLastVal[i], returnTable[i], 50) 
            allEqual = allEqual and replaceTable[i] == returnTable[i]
            
        end
        
        if(allEqual) then
        
            player.nextWPDoingTrans = false
            
        end
        
        returnTable = replaceTable
        
    end
    
    for i = 1, 5 do
    
        player.nextWPLastVal[i] = returnTable[i]
        
    end
    
    // If the next waypoint is also the final waypoint and is in screen space,
    // setting the distance to negative will hide it since the distance is
    // also displayed on the final waypoint
    local nextIsFinal = player:GetVisibleWaypoint() == player.nextOrderWaypoint
    if nextIsFinal and isInScreenSpace then
    
        returnTable[5] = -1
    
    end
    
    // Save current for next update
    VectorCopy(playerEyePos, player.lastPlayerEyePos)
    VectorCopy(playerForwardNorm, player.lastPlayerForwardNorm)
    
    return returnTable

end

/**
 * Gives the UI the screen space coordinates of where to display
 * the final waypoint for when players have an order location
 */
function PlayerUI_GetFinalWaypointInScreenspace()

    local player = Client.GetLocalPlayer()
    
    // Get our own waypoint, or if we're comm, the waypoint of our first selected player
    local waypoint = Vector(player:GetVisibleWaypoint())
    
    local returnTable = { }
    local screenPos = Client.WorldToScreen(waypoint)
    local finalWPDir = waypoint - player:GetEyePos()
    local normToEntityVec = GetNormalizedVectorXZ(finalWPDir)
    local normViewVec = GetNormalizedVectorXZ(player:GetViewAngles():GetCoords().zAxis)
    local dotProduct = normToEntityVec:DotProduct(normViewVec)
    
    // Distance is used for scaling
    local finalWPDist = finalWPDir:GetLengthSquared()
    local finalWPMaxDist = 25 * 25
    local finalWPScale = math.max(0.3, 1 - (finalWPDist / finalWPMaxDist))
    
    if(screenPos.x < 0 or screenPos.x > Client.GetScreenWidth() or
       screenPos.y < 0 or screenPos.y > Client.GetScreenHeight() or dotProduct < 0) then
       
        // Don't draw if it is behind the player
        returnTable[1] = false
        
    else
    
        returnTable[1] = true
        returnTable[2] = screenPos.x
        local bounceY = screenPos.y + (math.sin(Shared.GetTime() * 3) * (30 * finalWPScale))
        returnTable[3] = bounceY
        returnTable[4] = finalWPScale
        returnTable[5] = LookupTechData(player.orderType, kTechDataDisplayName, "<no display name>")
        returnTable[6] = math.sqrt(finalWPDist)
        
    end
    
    return returnTable
    
end

/**
 * Get crosshair texture atlas
 */
function PlayerUI_GetCrosshairTexture()

    Client.BindFlashTexture("weapon_crosshair", "ui/crosshairs.dds")
    return "weapon_crosshair"

end

/**
 * Get the X position of the crosshair image in the atlas. 
 */
function PlayerUI_GetCrosshairX()
    return 0
end

/**
 * Get the Y position of the crosshair image in the atlas.
 * Listed in this order:
 *   Rifle, Pistol, Axe, Shotgun, Minigun, Rifle with GL, Flamethrower
 */
function PlayerUI_GetCrosshairY()

    local player = Client.GetLocalPlayer()

    if(player and not player:GetIsThirdPerson()) then  
      
        local weapon = player:GetActiveWeapon()
        if(weapon ~= nil) then
        
            // Get class name and use to return index
            local index 
            local mapname = weapon:GetMapName()
            
            if(mapname == Rifle.kMapName or mapname == GrenadeLauncher.kMapName) then 
                index = 0
            elseif(mapname == Pistol.kMapName) then
                index = 1
            elseif(mapname == Shotgun.kMapName) then
                index = 3
            elseif(mapname == Minigun.kMapName) then
                index = 4
            elseif(mapname == Flamethrower.kMapName) then
                index = 5   
            // All alien crosshairs are the same for now
            elseif((mapname == Spikes.kMapName) or (mapname == Spores.kMapName) or (mapname == SpitSpray.kMapName) or (mapname == Parasite.kMapName)) then
                index = 6
            // Picking blink target
            elseif (mapname == SwipeBlink.kMapName) and weapon:GetShowingGhost() then
                index = 6
            // Blanks
            else
                index = 7
            end
        
            return index*64
            
        end
        
    end

    return 0

end

/**
 * Returns the player name under the crosshair for display (return "" to not display anything).
 */
function PlayerUI_GetCrosshairText()
    local player = Client.GetLocalPlayer()
    if player then
        return player.crossHairText
    end
    return ""
end

// Returns the int color to draw the results of PlayerUI_GetCrosshairText() in. 
function PlayerUI_GetCrosshairTextColor()
    local player = Client.GetLocalPlayer()
    if player then
        return player.crossHairTextColor
    end
    return kFriendlyNeutralColor
end

/**
 * Get the width of the crosshair image in the atlas, return 0 to hide
 */
function PlayerUI_GetCrosshairWidth()

    local player = Client.GetLocalPlayer()
    if player then

        local weapon = player:GetActiveWeapon()
    
        //if (weapon ~= nil and player:isa("Marine") and not player:GetIsThirdPerson()) then
    if (weapon ~= nil and not player:GetIsThirdPerson()) then
            return 64
        end
    end
    
    return 0
    
end


/**
 * Get the height of the crosshair image in the atlas, return 0 to hide
 */
function PlayerUI_GetCrosshairHeight()

    local player = Client.GetLocalPlayer()
    if(player ~= nil) then

        local weapon = player:GetActiveWeapon()    
        //if(weapon ~= nil and player:isa("Marine") and not player:GetIsThirdPerson()) then
    if (weapon ~= nil and not player:GetIsThirdPerson()) then
            return 64
        end
    
    end
    
    return 0

end

/**
 * Called by Flash to get the number of reserve bullets in the active weapon.
 */
function PlayerUI_GetWeaponAmmo()
    local player = Client.GetLocalPlayer()
    if player then
        return player:GetWeaponAmmo()
    end
    return 0
end

/**
 * Called by Flash to get the number of bullets left in the reserve for 
 * the active weapon.
 */
function PlayerUI_GetWeaponClip()
    local player = Client.GetLocalPlayer()
    if player then
        return player:GetWeaponClip()
    end
    return 0
end

function PlayerUI_GetAuxWeaponClip()
    local player = Client.GetLocalPlayer()
    if player then
        return player:GetAuxWeaponClip()
    end
    return 0
end

/**
 * Called by Flash to get the value to display for the team resources on
 * the HUD.
 */
function PlayerUI_GetTeamResources()
    local player = Client.GetLocalPlayer()
    if player then
        return player:GetDisplayTeamCarbon()
    end
    return 0
end

// TODO: 
function PlayerUI_MarineAbilityIconsImage()
end

/**
 * Called by Flash to get the value to display for the personal resources on
 * the HUD.
 */
function PlayerUI_GetPlayerResources()
    
    local player = Client.GetLocalPlayer()
    if player then
        return player:GetDisplayPlasma()
    end
    return 0
end

//TCBM player team carbon
function PlayerUI_GetPlayerTeamCarbon()
    
    local player = Client.GetLocalPlayer()
    if player then
        return player:GetDisplayTeamCarbon()
    end
    return 0
end

//TCBM player team resources
function PlayerUI_GetPlayerTeamResourcers()
    
    local player = Client.GetLocalPlayer()
    if player then
        return player:GetDisplayTeamResourcers()
    end
    return 0
end

function PlayerUI_GetPlayerTeamTechPoints()
    
    local player = Client.GetLocalPlayer()
    if player then
        return player:GetDisplayTeamTechPoints()
    end
    return 0
end

function PlayerUI_GetPlayerHealth()
    local player = Client.GetLocalPlayer()
    if player then
        return Client.GetLocalPlayer():GetHealth()
    end
    return 0
end

function PlayerUI_GetPlayerMaxHealth()
    local player = Client.GetLocalPlayer()
    if player then
        return player:GetMaxHealth()
    end
    return 0
end

function PlayerUI_GetPlayerArmor()
    local player = Client.GetLocalPlayer()
    if player then
        return player:GetArmor()
    end
    return 0
end

function PlayerUI_GetPlayerMaxArmor()
    local player = Client.GetLocalPlayer()
    if player then
        return player:GetMaxArmor()
    end
    return 0
end

// For drawing health circles
function GameUI_GetHealthStatus(entityId)

    local entity = Shared.GetEntity(entityId)
    if(entity ~= nil) then
    
        if entity:isa("LiveScriptActor") then
        
            return entity:GetHealth()/entity:GetMaxHealth()
            
        else
        
            Print("GameUI_GetHealthStatus(%d) - Entity not a ScriptActor (%s instead).", entityId, entity:GetMapName())
            
        end
        
    end
    
    return 0

end

function Player:GetName()
    return Scoreboard_GetPlayerData(self:GetClientIndex(), kScoreboardDataIndexName)
end

function Player:UpdateHelp()
end

function Player:GetDrawResourceDisplay()
    return false
end

// Update crosshair text and color which displays what player you're looking at and
// whether they're a friend or enemy. When tracereticle cheat is on, display any 
// entity under the crosshair.
function Player:UpdateCrossHairText()

    // Clear text if we don't hit anything
    self.crossHairText = ""

    local viewAngles = self:GetViewAngles()
    
    local viewCoords = viewAngles:GetCoords()
    
    local startPoint = self:GetViewOffset() + self:GetOrigin()
        
    local endPoint = startPoint + viewCoords.zAxis * 20
        
    local trace = Shared.TraceRay(startPoint, endPoint, PhysicsMask.AllButPCsAndRagdolls, EntityFilterOne(self))
    local entity = trace.entity
    
    // Show players and important structures
    if trace.fraction < 1 and entity ~= nil then
    
        local updatedText = false
        
        if self.traceReticle then
            
            self.crossHairText = string.format("%s (id: %d) origin: %s", SafeClassName(trace.entity), trace.entity:GetId(), trace.entity:GetOrigin():tostring())

            if trace.entity.GetExtents then
                self.crossHairText = string.format("%s extents: %s", self.crossHairText, trace.entity:GetExtents():tostring())
            end
            
            if trace.entity.GetTeamNumber then
                self.crossHairText = string.format("%s teamNum: %d", self.crossHairText, trace.entity:GetTeamNumber())
            end
            
            updatedText = true
    
        elseif entity:isa("Player") and entity:GetIsAlive() then
        
            local playerName = Scoreboard_GetPlayerData(entity:GetClientIndex(), kScoreboardDataIndexName)
                    
            if playerName ~= nil then
            
                self.crossHairText = playerName
            
            end
            
            if entity:GetTeamNumber() == self:GetTeamNumber() then
            
                // Add health scalar
                self.crossHairText = string.format("%s (%d%%)", self.crossHairText, math.ceil(entity:GetHealthScalar()*100))
                
            end
            
            updatedText = true

        // Add quickie damage feedback and structure status
        elseif (entity:isa("Structure") or entity:isa("MAC") or entity:isa("Drifter") or entity:isa("ARC")) and entity:GetIsAlive() then
        
            local techId = trace.entity:GetTechId()
            local statusText = string.format("(%.0f%%)", Clamp(math.ceil(trace.entity:GetHealthScalar() * 100), 0, 100))
            if entity:isa("Structure") and not entity:GetIsBuilt() then
                statusText = string.format("(%.0f%%)", Clamp(math.ceil(trace.entity:GetBuiltFraction() * 100), 0, 100))
            end

            local secondaryText = ""
            if entity:isa("Structure") then
            
                // Display location name for power point so we know what it affects
                if entity:isa("PowerPoint") then
                
                    if not entity:GetIsPowered() then
                        secondaryText = "Destroyed " .. entity:GetLocationName() .. " "
                        statusText = ""
                    else
                        secondaryText = entity:GetLocationName() .. " "
                    end

                elseif not entity:GetIsBuilt() then
                    secondaryText = "Unbuilt "
                elseif entity:GetRequiresPower() and not entity:GetIsPowered() then
                    secondaryText = "Unpowered "
                end
                
            end
            
            self.crossHairText = string.format("%s%s %s", secondaryText, LookupTechData(techId, kTechDataDisplayName), statusText)

            updatedText = true
            
        end
        
        if updatedText then
        
            if GetEnemyTeamNumber(self:GetTeamNumber()) == trace.entity:GetTeamNumber() then
    
                self.crossHairTextColor = kEnemyColor
                
            else
            
                self.crossHairTextColor = kFriendlyNeutralColor
                
            end
            
            self.crossHairTextTime = Shared.GetTime()

        end
            
    end     
    
end

// For debugging. Cheats only.
function Player:ToggleTraceReticle()
    self.traceReticle = not self.traceReticle
end

function Player:ToggleViewHeight()
    self.viewHeightCheat = not self.viewHeightCheat
end

function Player:UpdateMisc(input)

    PROFILE("Player:UpdateMisc")

    self:UpdateSharedMisc(input)

    if not Shared.GetIsRunningPrediction() then

        self:UpdateCrossHairText()
        self:UpdateDamageIndicators()
        
    end
    
end

/*
// Inefficient - find another way
function Player:UpdateCloaking()

    // Set cloaked enemy structures and players invisible
    local ents = GetEntitiesIsa("LiveScriptActor", -1)
    
    for index, entity in ipairs(ents) do
    
        if entity:GetGameEffectMask(kGameEffect.Cloaked) then
        
            if entity:GetTeamNumber() == GetEnemyTeamNumber(self:GetTeamNumber()) then
                entity:SetIsVisible(false)
            else
                // TODO: Mark friendly stuff as being cloaked but still visible
            end                
            
        end
        
    end

end
*/

function Player:UpdateScreenEffects(timePassed)

    if(self.flareStartTime > 0) then
    
        self.screenEffects.flare:SetActive(true)
        
        // How long to flare for
        local flareEffectTime = self.flareStopTime - self.flareStartTime
        local currFlareTime = Shared.GetTime() - self.flareStartTime
        local flareWeight = Clamp(currFlareTime / flareEffectTime, 0, 1)
        
        // We want the effect to ramp up fast for the first bit of the time, stick
        // for most the time and then down slow for the last bit
        // The point within the flare time which the flare will reach full power
        local atFullPoint = 0.1
        // The point where the flare will begin to die down
        local rampDownAtPoint = 0.75
        local rampUpSpeed = 1 / atFullPoint
        flareWeight = flareWeight * rampUpSpeed
        local rampDownTime = rampUpSpeed * rampDownAtPoint
        if(flareWeight > rampDownTime) then
        
            flareWeight = (rampUpSpeed - flareWeight) / (rampUpSpeed - rampDownTime)
        
        end
        flareWeight = Clamp(flareWeight, 0, 1) * self.flareScalar
        self.screenEffects.flare:SetParameter("flareWeight", flareWeight)
        
    else
    
        self.screenEffects.flare:SetActive(false)
        
    end
    
    // Show low health warning if below the threshold and not a spectator.
    local isSpectator = self:isa("Spectator") or self:isa("AlienSpectator")
    if(self:GetHealthScalar() <= Player.kLowHealthWarning) and not isSpectator then
    
        self.screenEffects.lowHealth:SetActive(true)
        local healthWeight = 1 - (self:GetHealthScalar() / Player.kLowHealthWarning)
        local pulseSpeed = Player.kLowHealthPulseSpeed / 2 + (Player.kLowHealthPulseSpeed / 2 * healthWeight)
        local pulseScalar = (math.sin(Shared.GetTime() * pulseSpeed) + 1) / 2
        healthWeight = 0.5 + (0.5 * (healthWeight * pulseScalar))
        self.screenEffects.lowHealth:SetParameter("healthWeight", healthWeight)
        
    else
    
        self.screenEffects.lowHealth:SetActive(false)
        
    end

end

// Only called when not running prediction
function Player:UpdateClientEffects(deltaTime, isLocal)

    // Only show local player model and active weapon for local player when third person 
    // or for other players
    local drawWorld = ((not isLocal) or self:GetIsThirdPerson())
    self:SetIsVisible(drawWorld)
    
    local activeWeapon = self:GetActiveWeapon()
    if (activeWeapon ~= nil) then
        activeWeapon:SetIsVisible( drawWorld )
    end
    
    local viewModel = self:GetViewModelEntity()    
    if(viewModel ~= nil) then
        viewModel:SetIsVisible( not drawWorld )
    end
    
    //self:UpdateCloaking()
    
    // Draw vector for view offset
    if self.viewHeightCheat then
    
        local extents = self:GetExtents()
        local boxWidth = math.max(extents.x, extents.z)
        DebugBox(self:GetOrigin() - Vector(boxWidth, 0, boxWidth), self:GetOrigin() + Vector(boxWidth, self:GetMaxViewOffsetHeight(), boxWidth), Vector(0, 0, 0), .3, 1, 1, 1, 1)
        
    end
    
    if isLocal then
    
        self:UpdateScreenEffects(deltaTime)
        self:UpdatePowerPointLights()
        
    end
    
end

function Player:UpdatePowerPointLights()

    // Only get power nodes on client every so often for performance reasons
    local time = Shared.GetTime()
    
    // Get power points that are relevant
    local forceUpdate = false
    
    if (self.timeOfLastPowerPoints == nil) or (time > (self.timeOfLastPowerPoints + 3)) then
    
        self.powerPoints = GetEntitiesIsa("PowerPoint")
        
        self.timeOfLastPowerPoints = time
        
        // If a power node wasn't relevant and becomes relevant, we need to update lights
        forceUpdate = true
        
    end
    
    // Now update the lights every frame
    for index, powerPoint in ipairs(self.powerPoints) do
    
        // But only update lights when necessary for performance reasons
        if powerPoint:GetIsAffectingLights() or forceUpdate then
        
            powerPoint:UpdatePoweredLights()
        
        end
        
    end
    
end

// Return flash player at index, creating it if it doesn't exist. Must call GetFlashPlayer(n-1) before calling GetFlashPlayer(n)
// or it will return nil. Start with GetFlashPlayer(1).
function GetFlashPlayer(index)

    // Create table if it doesn't exist
    if not gFlashPlayers then
        gFlashPlayers = {}
    end
    
    if index == nil then
        Print("GetFlashPlayer(nil): Error encountered - nil passed in as index")
        return nil
    end
    
    if(index > (table.maxn(gFlashPlayers) + 1)) then
        Print("GetFlashPlayer(%d): Error encountered - must have previously called GetFlashPlayer(%d) (num created: %d).", index, index - 1, table.maxn(gFlashPlayers))
        return nil
    end
    
    if(index > table.maxn(gFlashPlayers)) then
    
        local flashPlayer = Client.CreateFlashPlayer()
        Client.AddFlashPlayerToDisplay(flashPlayer)
        
        if gFlashPlayers[index] ~= nil then
            Print("GetFlashPlayer(%d): Creating flash player at index but flash player already there, overwriting", index)
        end
        
        gFlashPlayers[index] = flashPlayer
        
    end
    
    return gFlashPlayers[index]
    
end

// You can only remove the top-most flash player, or else it would invalidate the other indices.
function RemoveFlashPlayer(index)

    if gFlashPlayers then
    
        if(index == table.maxn(gFlashPlayers)) then
        
            local flashPlayer = gFlashPlayers[index]
            Client.RemoveFlashPlayerFromDisplay(flashPlayer)
            Client.DestroyFlashPlayer(flashPlayer)
            gFlashPlayers[index] = nil
            
        elseif index < table.maxn(gFlashPlayers) then
            Print("RemoveFlashPlayer(%d): Error - can only remove top-most flash player (currently at index %d)", index, table.maxn(gFlashPlayers))
        end 
       
    else
        Print("RemoveFlashPlayer(%d): No flash players have been created, use GetFlashPlayer() first.", index)
    end
    
end

function GetFlashPlayerDisplaying(index)

    local displaying = false
    
    if gFlashPlayers ~= nil and index >= table.maxn(gFlashPlayers) then
    
        if gFlashPlayers[index] then
        
            displaying = true
            
        end
        
    end
    
    return displaying
    
end

function RemoveFlashPlayers( all )

    // Destroy all flash players
    if (gFlashPlayers ~= nil) then
    
        local startIndex = ConditionalValue(all, 1, kClassFlashIndex)
        
        for index = startIndex, table.count(gFlashPlayers) do
            RemoveFlashPlayer(index)
        end

        if all or table.count(gFlashPlayers) == 0 then
            gFlashPlayers = nil
        end
        
    end
    
end

function Player:SetDesiredName()

    // Set default player name to one set in Steam, or one we've used and saved previously
    local playerName = Client.GetOptionString( kNicknameOptionsKey, Client.GetUserName() )
   
    Client.ConsoleCommand(string.format("name \"%s\"", playerName))

end

// Called on the Client only, after OnInit(), for a ScriptActor that is controlled by the local player.
// Ie, the local player is controlling this Marine and wants to intialize local UI, flash, etc.
function Player:OnInitLocalClient()

    // Only create base HUDs the first time a player is created
    if not gFlashPlayers then
    
        // Alpha send feedback swf
        //GetFlashPlayer(kFeedbackFlashIndex):Load(Player.kFeedbackFlash)
        //GetFlashPlayer(kFeedbackFlashIndex):SetBackgroundOpacity(0)

        // Main HUD for all classes (scoreboard, death messages, chat, etc.)
        //GetFlashPlayer(kSharedFlashIndex):Load(Player.kSharedHUDFlash)
        //GetFlashPlayer(kSharedFlashIndex):SetBackgroundOpacity(0)
        
    end
    
    // Only create base HUDs the first time a player is created.
    // We only ever want one of these.
    GetGUIManager():CreateGUIScriptSingle("GUICrosshair")
    GetGUIManager():CreateGUIScriptSingle("GUIScoreboard")
    GetGUIManager():CreateGUIScriptSingle("GUINotifications")
    GetGUIManager():CreateGUIScriptSingle("GUIRequests")
    GetGUIManager():CreateGUIScriptSingle("GUIDamageIndicators")
    GetGUIManager():CreateGUIScriptSingle("GUIDeathMessages")
    GetGUIManager():CreateGUIScriptSingle("GUIChat")
    
    // In case we were commanding on map reset
    Client.SetMouseVisible(false)
    Client.SetMouseCaptured(true)
    Client.SetMouseClipped(false)
    
    // Re-enable skybox rendering after commanding
    SetSkyboxDrawState(true)
    
    // Show props normally
    SetCommanderPropState(false)
    
    // Turn on sound occlusion for non-commanders
    Client.SetSoundGeometryEnabled(true)
    
    // Setup materials, etc. for death messages
    InitDeathMessages(self)
    
    self:ClearDisplayedTooltips()
    
    // Fix after Main/Client issue resolved
    self:SetDesiredName()
    
    self.cameraShakeAmount = 0
    self.cameraShakeSpeed = 0
    self.cameraShakeTime = 0
    
    self.crossHairText = ""
    self.crossHairTextColor = kFriendlyNeutralColor
    
    self.traceReticle = false
    self.viewHeightCheat = false
    
    self.damageIndicators = {}
    
    self.powerPoints = {}
    self.timeOfLastPowerPoints = nil
    
    // Set commander geometry visible
    Client.SetGroupIsVisible(kCommanderInvisibleGroupName, true)
    
    Client.SetEnableFog(true)
    
    self:InitScreenEffects()
    
end

function Player:InitScreenEffects()

    self.screenEffects = {}
    self.screenEffects.flare = Client.CreateScreenEffect("shaders/Flare.screenfx")
    self.screenEffects.lowHealth = Client.CreateScreenEffect("shaders/LowHealth.screenfx")

end

/**
 * Called when the player entity is destroyed.
 */
function Player:OnDestroy()

    LiveScriptActor.OnDestroy(self)
    
    Shared.DestroyPhysicsController(self.controller)
    self.controller = nil

    if (self.viewModel ~= nil) then
        Client.DestroyRenderViewModel(self.viewModel)
        self.viewModel = nil
    end
    
    self:DestroyScreenEffects()
    
end

function Player:DestroyScreenEffects()

    if(self.screenEffects ~= nil) then
    
        for effectName, effect in pairs(self.screenEffects) do
        
            Client.DestroyScreenEffect(effect)

        end
        
        self.screenEffects = {}
        
    end

end

function Player:DrawGameStatusMessage()

    local time = Shared.GetTime()
    local fraction = 1 - (time - math.floor(time))
    Client.DrawSetColor(255, 0, 0, fraction*200)

    if(self.countingDown) then
    
        Client.DrawSetTextPos(.42*Client.GetScreenWidth(), .95*Client.GetScreenHeight())
        Client.DrawString("Game is starting")
        
    else
    
        Client.DrawSetTextPos(.25*Client.GetScreenWidth(), .95*Client.GetScreenHeight())
        Client.DrawString("Game will start when both sides have players")
        
    end

end

function entityIdInList(entityId, entityList, useParentId)

    for index, entity in ipairs(entityList) do
    
        local id = entity:GetId()
        if(useParentId) then id = entity:GetParentId() end
        
        if(id == entityId) then
        
            return true
            
        end
        
    end
    
    return false
    
end

function Player:DebugVisibility()

    // For each visible entity on other team
    local entities = GetEntitiesIsaMultiple({"Player", "ScriptActor"}, GetEnemyTeamNumber(self:GetTeamNumber()))
    
    for entIndex, entity in ipairs(entities) do
    
        // If so, remember that it's seen and break
        local seen = self:GetCanSeeEntity(entity)            
        
        // Draw red or green depending
        DebugLine(self:GetOrigin() + self:GetViewOffset(), entity:GetOrigin(), 1, ConditionalValue(seen, 0, 1), ConditionalValue(seen, 1, 0), 0, 1)
        
    end

end

// Opens a menu in the kMenuFlashIndex layer
function Player:OpenMenu(swfMenuName)

    if(not Client.GetMouseVisible() and (Client.GetLocalPlayer() == self)) then
    
        GetFlashPlayer(kMenuFlashIndex):Load(swfMenuName)
        GetFlashPlayer(kMenuFlashIndex):SetBackgroundOpacity(0)
        
        Client.SetCursor("ui/Cursor_MenuDefault.dds")
        Client.SetMouseVisible(true)
        Client.SetMouseCaptured(false)
        Client.SetMouseClipped(true)
        
        return true

    end
    
    return false
           
end

function Player:CloseMenu(flashIndex)

    local success = false
    
    if flashIndex == nil and gFlashPlayers ~= nil then
        // Close top-level menu if not specified
        flashIndex = table.maxn(gFlashPlayers)
    end
    
    if(GetFlashPlayer(flashIndex) ~= nil and Client.GetMouseVisible()) then
    
        RemoveFlashPlayer(flashIndex)
    
        Client.SetMouseVisible(false)
        Client.SetMouseCaptured(true)
        Client.SetMouseClipped(false)
        
        success = true

    end
    
    return success
    
end

function Player:GetWeaponAmmo()

    // We could do some checks to make sure we have a non-nil ClipWeapon,
    // but this should never be called unless we do.
    local weapon = self:GetActiveWeapon()
    
    if(weapon ~= nil and weapon:isa("ClipWeapon")) then
        return weapon:GetAmmo()
    end
    
    return 0
    
end

function Player:GetWeaponClip()

    // We could do some checks to make sure we have a non-nil ClipWeapon,
    // but this should never be called unless we do.
    local weapon = self:GetActiveWeapon()
    
    if(weapon ~= nil and weapon:isa("ClipWeapon")) then
        return weapon:GetClip()
    end
    
    return 0
    
end

function Player:GetAuxWeaponClip()

    // We could do some checks to make sure we have a non-nil ClipWeapon,
    // but this should never be called unless we do.
    local weapon = self:GetActiveWeapon()
    
    if(weapon ~= nil and weapon:isa("ClipWeapon")) then
        return weapon:GetAuxClip()
    end
    
    return 0
    
end

// Watch for changes in vertical movement and smooth it out (for stairs)
function Player:SmoothCamera(cameraCoords)

    if(self.smoothCamera) then
    
        if(self.lastEyeHeight ~= nil) then
        
            // Only smooth small camera differences (so it doesn't animate when respawning)
            local yDiff = (cameraCoords.origin.y - self.lastEyeHeight)
            if(yDiff < 1) then

                local timeDiff = Shared.GetTime() - self.timeLastSmooth
                local newY = self.lastEyeHeight + timeDiff*10*yDiff
                local newOrigin = cameraCoords.origin
                newOrigin.y = newY
                cameraCoords.origin = newOrigin
                
            end
            
        end

        self.lastEyeHeight = cameraCoords.origin.y
        self.timeLastSmooth = Shared.GetTime()
        
    end
    
end

function Player:GetCameraViewCoords()

    local cameraCoords = self:GetViewCoords()
    
    // Adjust for third person
    if(self.cameraDistance ~= 0) then
    
        // Have camera look at front of player if desired
        if self.viewHeightCheat then
        
            local viewAngles = self:GetViewAngles()
            viewAngles.yaw = viewAngles.yaw + math.pi
            
            cameraCoords = viewAngles:GetCoords()   
            cameraCoords.origin = self:GetEyePos()
            
        end
        
        // Do traceline and put camera closer if we hit something
        local endPoint = cameraCoords.origin - cameraCoords.zAxis * self.cameraDistance
        local trace = Shared.TraceRay(cameraCoords.origin, endPoint, PhysicsMask.AllButPCs, EntityFilterOne(self))
        if(trace.fraction < 1) then
        
            // Add a little extra to avoid wall interpenetration
            VectorCopy(trace.endPoint + cameraCoords.zAxis * .2, cameraCoords.origin)
            
        else
            VectorCopy(endPoint, cameraCoords.origin)
        end        

    else    
    
        // Add in camera movement from view model animation
        local viewModel = self:GetViewModelEntity()
        if viewModel then
        
            local success, viewModelCameraCoords = viewModel:GetCameraCoords()
            if success then
            
                cameraCoords = cameraCoords * viewModelCameraCoords
                
            end
            
        end
    
    end

    self:SmoothCamera(cameraCoords)
    
    // Allow weapon or ability to override camera (needed for Blink)
    local activeWeapon = self:GetActiveWeapon()
    if activeWeapon then
    
        local override, newCoords = activeWeapon:GetCameraCoords()
        
        if override then
            cameraCoords = newCoords
        end
        
    end

    // Add in camera shake effect if any
    if(Shared.GetTime() < self.cameraShakeTime) then
    
        // Camera shake knocks view up and down a bit
        local shakeAmount = math.sin( Shared.GetTime() * self.cameraShakeSpeed * 2 * math.pi ) * self.cameraShakeAmount
        local origin = Vector(cameraCoords.origin)
        
        //cameraCoords.origin = cameraCoords.origin + self.shakeVec*shakeAmount
        local yaw = GetYawFromVector(cameraCoords.zAxis)
        local pitch = GetPitchFromVector(cameraCoords.zAxis) + shakeAmount
        local angles = Angles(pitch, yaw, 0)
        cameraCoords = angles:GetCoords()
        VectorCopy(origin, cameraCoords.origin)
        
    end
        
    return cameraCoords
    
end

function Player:GetRenderFov()
    // Convert degrees to radians
    return math.rad(self:GetFov())
end

function Player:SetCameraShake(amount, speed, time)

    // Overrides existing shake if it has elapsed or if new shake amount is larger
    local currentTime = Shared.GetTime()
    
    if currentTime > self.cameraShakeTime or amount > self.cameraShakeAmount then
    
        self.cameraShakeAmount = amount

        // "bumps" per second
        self.cameraShakeSpeed = speed 
        
        self.cameraShakeTime = currentTime + time
        
    end
    
end

// For drawing build circles
function GameUI_GetBuildStatus(entityId)

    local entity = Shared.GetEntity(entityId)
    
    if(entity ~= nil) then
    
        if(entity:isa("Structure")) then
        
            if(entity:GetIsBuilt()) then
                return 1.0
            end
            
            return entity:GetBuiltFraction()
            
        else
        
            Print("GameUI_GetBuildStatus(%d) - Entity not a BuildableStructure (%s instead).", entityId, entity:GetMapName())
            
        end
        
    end
    
    return 0
    
end

// True means display the menu or sub-menu
function PlayerUI_ShowSayings()
    local player = Client.GetLocalPlayer()    
    if player then
        return player:GetShowSayings()
    end
    return nil
end

// return array of sayings
function PlayerUI_GetSayings()

    local sayings = nil
    local player = Client.GetLocalPlayer()        
    if(player:GetHasSayings()) then
        sayings = player:GetSayings()
    end
    return sayings
    
end

// Returns 0 unless a saying was just chosen. Returns 1 - number of sayings when one is chosen.
function PlayerUI_SayingChosen()
    local player = Client.GetLocalPlayer()
    if player then
        local saying = player:GetAndClearSaying()
        if(saying ~= nil) then
            return saying
        end
    end
    return 0
end

// Draw the current location on the HUD ("Marine Start", "Processing", etc.)
function PlayerUI_GetLocationName()

    local locationName = ""
    
    local player = Client.GetLocalPlayer()    
    if(player ~= nil and player:GetIsPlaying()) then
        locationName = player:GetLocationName()
    end
    
    return locationName
    
end

/**
 * Damage indicators. Returns a array of damage indicators which are used to draw red arrows pointing towards
 * recent damage. Each damage indicator pair will consist of an alpha and a direction. The alpha is 0-1 and the
 * direction in radians is the angle at which to display it. 0 should face forward (top of the screen), pi 
 * should be behind us (bottom of the screen), pi/2 is to our left, 3*pi/2 is right.
 * 
 * For two damage indicators, perhaps:
 *  {alpha1, directionRadians1, alpha2, directonRadius2}
 *
 * It returns an empty table if the player has taken no damage recently. 
 */
function PlayerUI_GetDamageIndicators()

    local drawIndicators = {}
    
    local player = Client.GetLocalPlayer()
    if player then
    
        for index, indicatorTriple in ipairs(player.damageIndicators) do
            
            local alpha = Clamp(1 - ((Shared.GetTime() - indicatorTriple[3])/Player.kDamageIndicatorDrawTime), 0, 1)
            table.insert(drawIndicators, alpha)

            local worldX = indicatorTriple[1]
            local worldZ = indicatorTriple[2]
            
            // Dot our view direction with direction to damage       
            local normViewDir = GetNormalizedVectorXZ(player:GetViewAngles():GetCoords().zAxis)
            local normDirToDamage = GetNormalizedVector(Vector(worldX, 0, worldZ) - Vector(player:GetOrigin().x, 0, player:GetOrigin().z))
            local dotProduct = normViewDir:DotProduct(normDirToDamage)
            
            local directionRadians = math.acos(dotProduct)
            if directionRadians < 0 then
                directionRadians = directionRadians + 2 * math.pi
            end
            
            table.insert(drawIndicators, directionRadians)
            
        end
        
    end
    
    //if table.count(drawIndicators) > 0 then
    //    Print("PlayerUI_GetDamageIndicators() => %s", table.tostring(drawIndicators))
    //end
    
    return drawIndicators
    
end

function Player:AddDamageIndicator(worldX, worldZ)

    // Insert triple indicating when damage was taken and from where it came 
    local triple = {worldX, worldZ, Shared.GetTime()}
    table.insert(self.damageIndicators, triple)
    
end

function Player:UpdateDamageIndicators()

    local indicesToRemove = {}
    
    // Expire old damage indicators
    for index, indicatorTriple in ipairs(self.damageIndicators) do
    
        if Shared.GetTime() > (indicatorTriple[3] + Player.kDamageIndicatorDrawTime) then
        
            table.insert(indicesToRemove, index)
            
        end
        
    end
    
    for i, index in ipairs(indicesToRemove) do
        table.remove(self.damageIndicators, index)
    end
    
end

/**
 * Inform player about something (research complete, a structure that can be used, etc.)
 */
function Player:AddTooltip(message)
    
    // Strip out surrounding "s
    local message = string.gsub(message, "\"(.*)\"", "%1")
    
    // Hook flash display 
    HudTooltip_SetMessage(message)
    
    self:AddDisplayedTooltip(message)
    
    Shared.PlaySound(self, Player.kTooltipSound)
    
end

// Set after hotgroup updated over the network
function Player:SetHotgroup(number, entityList)

    if(number >= 1 and number <= Player.kMaxHotkeyGroups) then
        //table.copy(entityList, self.hotkeyGroups[number])
        self.hotkeyGroups[number] = entityList
    end
    
end

function Player:OnSynchronized()

    local player = Client.GetLocalPlayer()
    
    if player ~= nil then
    
        // Make sure to call OnInit() for client entities that have been propagated by the server
        if(not self.clientInitedOnSynch) then
        
            self:OnInit()
            
            // Only call OnInitLocalClient() for entities that are the local player
            if(Client and (player == self)) then   
                self:OnInitLocalClient()    
            end
            
            self.clientInitedOnSynch = true
            
        end

        // Update these here because they could update hitboxes
        local deltaTime = 0
        local currentTime = Shared.GetTime()
        if self.lastSynchronizedTime ~= nil then
            deltaTime = currentTime - self.lastSynchronizedTime
        end
        
        self:UpdatePoseParameters(deltaTime)
        self.lastSynchronizedTime = currentTime
        
        LiveScriptActor.OnSynchronized(self)
        
        self:UpdateControllerFromEntity()
        
    end
    
end

function Player:OnUpdate(deltaTime)

    PROFILE("Player_Client:OnUpdate")
    
    // Need to update pose parameters every frame to keep them smooth
    LiveScriptActor.OnUpdate(self, deltaTime)
    
    self:UpdateUse(deltaTime)
    
    if not Client.GetIsRunningPrediction() then
    
        local isLocal = (self == Client.GetLocalPlayer())
        
        if isLocal then
        
            self:UpdatePoseParameters(deltaTime)
            
        end
        
        GetEffectManager():TriggerQueuedEffects()
    
        self:UpdateClientEffects(deltaTime, isLocal)
    
    end
    
end

function Player:UpdateGUI()

    // Update the view model's GUI.
    
    local viewModel = self:GetViewModelEntity()    
    if(viewModel ~= nil) then
        viewModel:UpdateGUI()
    end

end

function Player:UpdateChat(input)

    // Enter chat message
    if (bit.band(input.commands, Move.TextChat) ~= 0) then
        ChatUI_EnterChatMessage(false)
    end

    // Enter chat message
    if (bit.band(input.commands, Move.TeamChat) ~= 0) then
        ChatUI_EnterChatMessage(true)
    end
    
end

function Player:GetCustomSelectionText()
    return string.format("%s\n%s kills\n%s deaths\n%s score", 
            ToString(Scoreboard_GetPlayerData(self:GetClientIndex(), kScoreboardDataIndexName)), 
            ToString(Scoreboard_GetPlayerData(self:GetClientIndex(), kScoreboardDataIndexKills)),
            ToString(Scoreboard_GetPlayerData(self:GetClientIndex(), kScoreboardDataIndexDeaths)),
            ToString(Scoreboard_GetPlayerData(self:GetClientIndex(), kScoreboardDataIndexScore))
    )
end
