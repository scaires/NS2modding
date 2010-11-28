// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ResourceTower_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Generic resource structure that marine and alien structures inherit from.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function ResourceTower:OnKill(damage, killer, doer, point, direction)

    Structure.OnKill(self, damage, killer, doer, point, direction)
    
    self:StopSound(self:GetActiveSound())
    
end

function ResourceTower:OnPoweredChange(newPoweredState)

    Structure.OnPoweredChange(self, newPoweredState)
    
    if not self.powered then
        self:StopSound(self:GetActiveSound())
    end
    
end

function ResourceTower:GetUpdateInterval()
    return kResourceTowerResourceInterval
end

function ResourceTower:UpdateOnThink()

    // Give plasma to all players on team
    local team = self:GetTeam()
    team:ForEachPlayer( function (player) self:GiveResourcesToTeam(player) end )

    // Give carbon to team
    local team = self:GetTeam()
    if(team ~= nil) then
		local carbon = ResourceTower.kCarbonInjection * (1 + self:GetUpgradeLevel() * kResourceUpgradeAmount)
        team:AddCarbon(carbon)
        //Print("team carbon: %f + %f", carbon, team.carbon)
    end
    
    self:PlaySound(self:GetHarvestedSound())
    
end

function ResourceTower:OnThink()

    if self:GetIsBuilt() and self:GetIsAlive() and (self:GetAttached() ~= nil) and self:GetIsActive() and (self:GetAttached():GetAttached() == self) and GetGamerules():GetGameStarted() then

        self:UpdateOnThink()
            
    end

    Structure.OnThink(self)
    
    self:SetNextThink(self:GetUpdateInterval())

end

function ResourceTower:OnConstructionComplete()

    Structure.OnConstructionComplete(self)
    
    self:SetNextThink(ResourceTower.kBuildDelay)
    
	//TCBM: notify all players that a new tower was dropped
	local team = self:GetTeam()
    team:ForEachPlayer( function (player) team:ProcessPlayerResourceHelp(player) end )
	
end

//TCBM: used for resource hud notifications
function ResourceTower:OnKill(damage, attacker, doer, point, direction)
    
    Structure.OnKill(self, damage, attacker, doer, point, direction)
	//TCBM: notify team that station was killed
	local team = self:GetTeam()
    team:ForEachPlayer( function (player) team:ProcessPlayerResourceHelp(player) end )
end
