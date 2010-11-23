// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Hydra_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Creepy plant turret the Gorge can create.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Hydra.kThinkInterval = .3
    
function Hydra:GetDeploySound()
    return Hydra.kDeploySound
end

function Hydra:GetKilledSound(doer)
    return Hydra.kDeathSound
end

function Hydra:AcquireTarget()

    PROFILE("Hydra:AcquireTarget")

    self.shortestDistanceToTarget = nil
    self.targetIsaPlayer = false
    self.target = nil
        
    local targets = GetGamerules():GetEntities("LiveScriptActor", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetModelOrigin(), Hydra.kRange)
    
    for index, target in pairs(targets) do
    
        local distanceToTarget = self:GetDistanceToTarget(target)
        if distanceToTarget < Hydra.kRange then
        
            local validTarget = self:GetTargetValid(target)
            if(validTarget) then
            
                local newTargetCloser = (self.shortestDistanceToTarget == nil or (distanceToTarget < self.shortestDistanceToTarget))
                local newTargetIsaPlayer = target:isa("Player")
        
                // Give players priority over regular entities, but still pick closer players
                if( (not self.targetIsaPlayer and newTargetIsaPlayer) or
                    (newTargetCloser and not (self.targetIsaPlayer and not newTargetIsaPlayer)) ) then
            
                    // Set new target
                    self.target = target
                    self.shortestDistanceToTarget = distanceToTarget
                    self.targetIsaPlayer = newTargetIsaPlayer
                    
                end           
                
            end
            
        end
            
    end
        
end

function Hydra:GetDistanceToTarget(target)
    return (target:GetEngagementPoint() - self:GetModelOrigin()):GetLength()           
end

function Hydra:GetTargetValid(target, logError)

    if(target ~= nil and (target:isa("Player") or target:isa("Structure")) and target.alive and target ~= self and target:GetCanTakeDamage()) then
    
        local distance = self:GetDistanceToTarget(target)
        if distance < Hydra.kRange then
        
            // Perform trace to make sure nothing is blocking our target. Trace from enemy to us
            local trace = Shared.TraceRay(target:GetModelOrigin(), self:GetModelOrigin(), PhysicsMask.AllButPCs, EntityFilterTwo(target, self))               
            local validTarget = (trace.fraction == 1)

            if not validTarget and logError then
                Print("Hydra:GetTargetValid(): Target %s not valid, blocked by %s", SafeClassName(target), SafeClassName(trace.entity))
            end
            
            return validTarget
            
        end
    
    end
    
    return false

end

function Hydra:AttackTarget()

    self:CreateSpikeProjectile()
    
    Shared.PlayWorldSound(nil, Hydra.kAttackSoundName, nil, self:GetModelOrigin())
    
    self:SetAnimationWithBlending(Hydra.kAnimAttack, nil, nil, 1/self:AdjustFuryFireDelay(1))
    
    // Random rate of fire to prevent players from popping out of cover and shooting regularly
    self.timeOfNextFire = Shared.GetTime() + self:AdjustFuryFireDelay(.5 + NetworkRandom() * 1)
    
end

function Hydra:CreateSpikeProjectile()

    local direction = GetNormalizedVector(self.target:GetModelOrigin() - self:GetModelOrigin())
    local startPos = self:GetModelOrigin() + direction
    
    // Create it outside of the hydra a bit
    local spike = CreateEntity(HydraSpike.kMapName, startPos, self:GetTeamNumber())
    SetAnglesFromVector(spike, direction)
    
    local startVelocity = direction * 25
    spike:SetVelocity(startVelocity)
    
    spike:SetGravityEnabled(false)
    
    // Set spike owner so we don't collide with ourselves and so we
    // can attribute a kill to us
    spike:SetOwner(self:GetOwner())
    
    spike:SetIsVisible(true)
                
end

function Hydra:GetIsEnemyNearby()

    local enemyPlayers = GetGamerules():GetPlayers( GetEnemyTeamNumber(self:GetTeamNumber()) )
    
    for index, player in ipairs(enemyPlayers) do                
    
        if player:GetIsVisible() and not player:isa("Commander") then
        
            local dist = self:GetDistanceToTarget(player)
            if dist < Hydra.kRange then
        
                return true
                
            end
            
        end
        
    end

    return false
    
end

function Hydra:OnThink()

    Structure.OnThink(self)
    
    if(self:GetIsBuilt()) then    
    
        self:AcquireTarget()
    
        if(self:GetTargetValid(self.target)) then
        
            if(self.timeOfNextFire == nil or (Shared.GetTime() > self.timeOfNextFire)) then
            
                self:AttackTarget()
                
            end

        else
        
            // Play alert animation if marines nearby and we're not targeting (MASCs?)
            if self.timeLastAlertCheck == nil or Shared.GetTime() > self.timeLastAlertCheck + Hydra.kAlertCheckInterval then
            
                if self:GetIsEnemyNearby() then
                
                    self:SetAnimationWithBlending(Hydra.kAnimAlert, nil, nil, 1/self:AdjustFuryFireDelay(1)) 
                    
                    self.timeLastAlertCheck = Shared.GetTime()
                
                end
                                                            
            end
            
        end
        
    end
    
    self:SetNextThink(Hydra.kThinkInterval)
    
end

function Hydra:OnConstructionComplete()

    Structure.OnConstructionComplete(self)
    
    // Start scanning for targets once built
    self:SetNextThink(Hydra.kThinkInterval)
        
end

function Hydra:OnInit()

    Structure.OnInit(self)
   
    self:SetNextThink(Hydra.kThinkInterval)
           
end



