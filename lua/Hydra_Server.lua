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
    
        local validTarget, distanceToTarget = self:GetTargetValid(target)
        
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

function Hydra:GetTargetValid(target, logError)

    if(target ~= nil and (target:isa("Player") or target:isa("Structure")) and target.alive and target ~= self and target:GetCanTakeDamage()) then
    
        local distance = (target:GetEngagementPoint() - self:GetModelOrigin()):GetLength()
        
        if(distance < Hydra.kRange) then
        
            // Perform trace to make sure nothing is blocking our target. Trace from enemy to us
            local trace = Shared.TraceRay(target:GetModelOrigin(), self:GetModelOrigin(), PhysicsMask.AllButPCs, EntityFilterTwo(target, self))               
            local validTarget = (trace.fraction == 1)

            if not validTarget and logError then
                Print("Hydra:GetTargetValid(): Target %s not valid, blocked by %s", SafeClassName(target), SafeClassName(trace.entity))
            end
            
            return validTarget, distance
            
        end
    
    end
    
    return false, -1

end

function Hydra:AttackTarget()
	if(self.lastTargetPos ~= nil) then
		//create a trace instead of a projectile
		self:CreateSpikeTrace()
		
		Shared.PlayWorldSound(nil, Hydra.kAttackSoundName, nil, self:GetModelOrigin())
		
		self:SetAnimationWithBlending(Hydra.kAnimAttack, nil, nil, 1/self:AdjustFuryFireDelay(1))
		
		// Random rate of fire to prevent players from popping out of cover and shooting regularly
		self.timeOfNextFire = Shared.GetTime() + self:AdjustFuryFireDelay(.5 + NetworkRandom() * 1)
    end
end

function Hydra:CreateSpikeTrace()
	if(self.lastTargetPos ~= nil) then
		Print("dir")
		local direction = GetNormalizedVector(Vector(self.lastTargetPos) - self:GetModelOrigin())
		Print("sp")
		local startPos = self:GetModelOrigin() + direction
		Print("local x")
		local x = (NetworkRandom(string.format("%s:FireBullet %d, %d", self:GetClassName(), 1, 1)) - .5) + (NetworkRandom(string.format("%s:FireBullet %d, %d", self:GetClassName(), 1, 2)) - .5)
		local y = (NetworkRandom(string.format("%s:FireBullet %d, %d", self:GetClassName(), 1, 3)) - .5) + (NetworkRandom(string.format("%s:FireBullet %d, %d", self:GetClassName(), 1, 4)) - .5)
		Print("spread dir")
		local spreadDirection = direction// + x * Hydra.kSpread.x + y * Hydra.kSpread.y
		Print("end point")
		local endPoint = startPos + spreadDirection * Hydra.kRange
		Print("trace")
		local trace = Shared.TraceRay(startPos, endPoint, PhysicsMask.AllButPCs, EntityFilterOne(self))
		
		if (trace.fraction < 1) then
		
			if trace.entity and trace.entity.TakeDamage then
						
				local direction = (trace.endPoint - startPos):GetUnit()
				
				trace.entity:TakeDamage(HydraSpike.kDamage, self:GetOwner(), self, trace.endPoint, direction)                    

				// Play sound and particle effect
				Shared.PlayWorldSound(nil, HydraSpike.kHitSound, nil, trace.endPoint)
				
				Shared.CreateEffect(nil, HydraSpike.kImpactEffect, nil, Coords.GetTranslation(trace.endPoint))

			end
		else
			// Play sound and particle effect
			Shared.PlayWorldSound(nil, HydraSpike.kHitSound, nil, trace.endPoint)
			
			Shared.CreateEffect(nil, HydraSpike.kImpactEffect, nil, Coords.GetTranslation(trace.endPoint))	
		end
	end
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
    
        if not player:isa("Commander") then
        
            local dist = (player:GetEngagementPoint() - self:GetModelOrigin()):GetLength()
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
    
		//Slowly decrease hydra health
		//Don't use take damage as this spams updates/messagesd
		if( Shared.GetTime() > (self.timeSpawned + Hydra.kHydraLifetimeCycle) ) then
			self.health = math.max(0,self.health - (kHydraHealth/(Hydra.kHydraLifetime/Hydra.kHydraLifetimeCycle)))
			self.timeSpawned = Shared.GetTime()
			if self.health == 0 then
				self:TakeDamage(10,nil,nil,nil,nil)
			end
		end
	
        self:AcquireTarget()
		
		//attack last position of our target to simulate projectile travel
        if(self:GetTargetValid(self.target)) then
			   
            if(self.timeOfNextFire == nil or (Shared.GetTime() > self.timeOfNextFire)) then
            
                self:AttackTarget()
                
            end
			self.lastTargetPos = self.target:GetModelOrigin()    
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
    self.timeSpawned = Shared.GetTime()    
	self.lastTargetPos = nil
end

function Hydra:OnInit()

    Structure.OnInit(self)
   
    self:SetNextThink(Hydra.kThinkInterval)
           
end



