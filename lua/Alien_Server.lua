// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Alien_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Alien:Evolve(techId)

    local success = false
    local newPlayer = nil
    
    // Morph into new class or buy upgrade
    local gestationClassName = LookupTechData(techId, kTechDataGestateName)
    
    if(gestationClassName ~= nil) then
    
        // Change into new life form if different
        if self:GetClassName() ~= gestationClassName then
        
            self:RemoveChildren()
            
            newPlayer = self:Replace(Embryo.kMapName)
            
            // Clear angles, in case we were wall-walking or doing some crazy alien thing
            local angles = Angles(self:GetViewAngles())
            angles.roll = 0.0
            angles.pitch = 0.0
            newPlayer:SetAngles(angles)
            
            // We lose our purchased upgrades when we morph into something else
            newPlayer.upgrade1 = kTechId.None
            newPlayer.upgrade2 = kTechId.None
            newPlayer.upgrade3 = kTechId.None
            newPlayer.upgrade4 = kTechId.None
            
            newPlayer:SetGestationTechId(techId)
            
            success = true
            
        end        
        
    end
    
    return success, newPlayer
    
end

// Availability and cost already checked
function Alien:AttemptToBuy(techId)

    local success = false
    
    // Morph into new class 
    if not self:Evolve(techId) then
        
        // Else try to buy tech (carapace, piercing, etc.). If we don't already have this tech node, buy it.
        if not self:GetHasUpgrade(techId) then
            
            success = self:GiveUpgrade(techId)
            
        else
            Print("%s:AttemptToBuy(%d) - Player already has tech (%s).", techId, LookupTechData(techId, kTechDataDisplayName, "unknown"))
        end
    
    end
        
    return success
    
end

function Alien:OnInit()

    Player.OnInit(self)
    
    self.abilityEnergy = Ability.kMaxEnergy

    Shared.PlaySound(self, self:GetSpawnSound())
    
end
