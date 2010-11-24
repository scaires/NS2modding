// ======= Copyright � 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\CommandStation.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/CommandStructure.lua")

class 'CommandStation' (CommandStructure)
CommandStation.kMapName               = "commandstation"

CommandStation.kLevel1MapName         = "commandstationl1"

CommandStation.kModelName = PrecacheAsset("models/marine/command_station/command_station.model")

CommandStation.kLoginSound = PrecacheAsset("sound/ns2.fev/marine/structures/command_station_close")
CommandStation.kLogoutSound = PrecacheAsset("sound/ns2.fev/marine/structures/command_station_open")
CommandStation.kActiveSound = PrecacheAsset("sound/ns2.fev/marine/structures/command_station_active")
CommandStation.kUnderAttackSound = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/command_station_under_attack")
CommandStation.kReplicateSound = PrecacheAsset("sound/ns2.fev/alien/common/join_team")

CommandStation.kCommandScreenEffect = PrecacheAsset("cinematics/marine/commandstation/command_screen.cinematic")
CommandStation.kDeathEffect = PrecacheAsset("cinematics/marine/commandstation/death.cinematic")
CommandStation.kMarineReplicateEffect = PrecacheAsset("cinematics/marine/clone_structure.cinematic")
CommandStation.kMarineReplicateBigEffect = PrecacheAsset("cinematics/marine/clone_structure_big.cinematic")

CommandStation.kLoginAttachPoint = "login"

if (Server) then
    Script.Load("lua/CommandStation_Server.lua")
end

local networkVars = 
{
    occupied            = "boolean"
}

function CommandStation:GetRequiresPower()
    return false
end

function CommandStation:GetDeathEffect()
    return CommandStation.kDeathEffect
end

function CommandStation:GetLoginSound()
    return CommandStation.kLoginSound
end

function CommandStation:GetLogoutSound()
    return CommandStation.kLogoutSound
end

function CommandStation:GetDeploySound()
    return CommandStation.kLogoutSound
end

function CommandStation:GetUseAttachPoint()
    return CommandStation.kLoginAttachPoint
end

function CommandStation:GetPowerDownAnimation()
    return ""
end

function CommandStation:GetPowerUpAnimation()
    return ""
end

function CommandStation:OnAnimationComplete(animName)

    if(animName == Structure.kAnimDeploy) then
        self:SetAnimation("open")
    elseif(animName == "close") then
        self:PlaySound(CommandStation.kActiveSound)
    elseif(animName == "open") then
        self:StopSound(CommandStation.kActiveSound)
    end

end

function CommandStation:GetOnFireSound()
    return LiveScriptActor.kOnFireLargeSound
end

function CommandStation:GetTechButtons(techId)

    local techButtons = nil
    
    if(techId == kTechId.RootMenu) then 
    
        techButtons = { kTechId.MAC, kTechId.AmmoPack, kTechId.MedPack, kTechId.CatPack,
                        kTechId.SetRally, kTechId.None, kTechId.None, kTechId.None,
                        kTechId.None, kTechId.CommandStationUpgradesMenu, kTechId.ReplicateMenu, kTechId.None}
        
        // Allow command station to be upgraded, but you'll never upgrade it to Level1 so don't show it
        if(self:GetTechId() == kTechId.CommandStation) then
            techButtons[kMarineUpgradeButtonIndex] = self:GetLevelTechId(2)
        elseif(self:GetTechId() == kTechId.CommandFacility) then
            techButtons[kMarineUpgradeButtonIndex] = self:GetLevelTechId(3)
        end
        
        // Don't allow recycling of structure when occupied!
        if not self:GetIsOccupied() then
            techButtons[kRecycleButtonIndex] = kTechId.Recycle
        end
        
    elseif techId == kTechId.ReplicateMenu then
    
        techButtons = {     kTechId.ReplicateCommandStation, kTechId.ReplicateExtractor, kTechId.ReplicateInfantryPortal, kTechId.ReplicateArmory, 
                            kTechId.ReplicateSentry, kTechId.ReplicateObservatory, kTechId.ReplicateRoboticsFactory, kTechId.None,
                            kTechId.ReplicateMAC, kTechId.ReplicateMASC, kTechId.None, kTechId.RootMenu }
                            
    elseif techId == kTechId.CommandStationUpgradesMenu then
    
        techButtons = {     kTechId.ReplicateTech, kTechId.SentryTech, kTechId.None, kTechId.None, 
                            kTechId.MACMinesTech, kTechId.MACEMPTech, kTechId.MACSpeedTech, kTechId.None,
                            kTechId.None, kTechId.None, kTechId.None, kTechId.RootMenu  }

    end
    
    return techButtons
 
end

function CommandStation:PerformActivation(techId, position, commander)

    local success = false
    
    for index, techButtonId in ipairs(self:GetTechButtons(kTechId.ReplicateMenu)) do

        if (techId == techButtonId) and (techId ~= kTechId.None) then    
        
            // Check if we have enough carbon to replicate this structure
            local structureId = LookupTechData(techId, kTechDataReplicateTechId)
            //Use replicate cost instead of normal cost
			local cost = LookupTechData(kTechDataReplicateTechId, kTechDataCostKey)
            local costsCarbon = commander:GetTechTree():GetTechNode(structureId):GetIsBuild()
            
            if (costsCarbon and (commander:GetTeam():GetCarbon() >= cost)) or (commander:GetPlasma() >= cost) then
            
                if ReplicateStructure(structureId, position, commander) then
                
                    if costsCarbon then
                        commander:GetTeam():AddCarbon(-cost)
                    else
                        commander:GetTeam():AddPlasma(-cost)
                    end

                    success = true
                    
                end
                    
            else
            
                // Play "require more resources" sound
                commander:TriggerNotEnoughResourcesAlert()
                
            end
            
            break
            
        end
        
    end
    
    if not success then
        success = LiveScriptActor.PerformActivation(self, techId, position, commander)
    end
    
    return success
    
end

function CommandStation:GetDeathAnimation()
    return ConditionalValue(self.occupied, "death_closed", "death_opened")
end

function CommandStation:GetEngagementPoint()
    if not self.occupied then
        return self:GetOrigin()
    else
        return CommandStructure.GetEngagementPoint(self)
    end
end

Shared.LinkClassToMap("CommandStation",    CommandStation.kMapName, networkVars)
Shared.LinkClassToMap("CommandStation",    CommandStation.kLevel1MapName, networkVars)

// Create new classes here so L2 and L3 command stations can be created for test cases without
// create a basic hive and then upgrading it
class 'CommandStationL2' (CommandStation)

function CommandStationL2:GetTechId()
    return kTechId.CommandFacility
end

CommandStationL2.kMapName       = "commandstationl2"
Shared.LinkClassToMap("CommandStationL2", CommandStationL2.kMapName, {})

class 'CommandStationL3' (CommandStationL2)

function CommandStationL3:GetTechId()
    return kTechId.CommandCenter
end

CommandStationL3.kMapName       = "commandstationl3"
Shared.LinkClassToMap("CommandStationL3", CommandStationL3.kMapName, {})
