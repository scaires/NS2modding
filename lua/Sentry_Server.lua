// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Sentry_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//TCBM set sentry angles to that of builder
function Sentry:setSentryAngles(builder)
	local angles = Angles(self:GetAngles())
	angles.yaw = Angles(builder:GetAngles()).yaw
	self:SetAngles(angles)
end

function Sentry:OnConstructionComplete()

    Structure.OnConstructionComplete(self)
    
    // Start scanning for targets once built
    local time = self:GetAnimationLength(Structure.kAnimDeploy)

    self:SetNextThink(time)
        
end

function Sentry:OnDestroy()
    
    self:StopSound(Sentry.kAttackSoundName)
    
    Structure.OnDestroy(self)
    
end

function Sentry:GetDamagedAlertId()
    return kTechId.MarineAlertSentryUnderAttack
end

function Sentry:AcquireTarget()

    local targetAcquired = nil

    if Shared.GetTime() > (self.timeOfLastTargetAcquisition + Sentry.kTargetCheckTime) then
    
        self.shortestDistanceToTarget = nil
        self.targetIsaPlayer = false
        
        local targets = GetGamerules():GetEntities("LiveScriptActor", GetEnemyTeamNumber(self:GetTeamNumber()))
        
        for index, target in pairs(targets) do
        
            local validTarget, distanceToTarget = self:GetIsTargetValid(target)
            //Print("Sentry scanned target: %s => %s", SafeClassName(target), ToString(validTarget))
            
            if(validTarget) then
            
                local newTargetCloser = (self.shortestDistanceToTarget == nil or (distanceToTarget < self.shortestDistanceToTarget))
                local newTargetIsaPlayer = target:isa("Player")
        
                // Give players priority over regular entities, but still pick closer players
                if( (not self.targetIsaPlayer and newTargetIsaPlayer) or
                    (newTargetCloser and not (self.targetIsaPlayer and not newTargetIsaPlayer)) ) then
            
                    // Set new target
                    targetAcquired = target
                    
                    self.shortestDistanceToTarget = distanceToTarget
                    self.targetIsaPlayer = newTargetIsaPlayer
                    
                end           
                
            end
                
        end
        
        self.timeOfLastTargetAcquisition = Shared.GetTime()
        
    end
    
    if targetAcquired ~= nil then
        self:GiveOrder(kTechId.Attack, targetAcquired:GetId(), nil)
    end
    
    return targetAcquired
    
end

function Sentry:ClearOrders()

    Structure.ClearOrders(self)
    
    if self:GetAnimation() == self:GetPowerDownAnimation() then
    
        self.settingTarget = false
        self:SetAnimation(self:GetPowerUpAnimation())
        
    end
    
end

function Sentry:OnAnimationComplete(animName)

    Structure.OnAnimationComplete(self, animName)
    
    if animName == Sentry.kAttackStartAnim then
    
        self.spunUp = true
        self:PlaySound(Sentry.kAttackSoundName)

    elseif animName == Sentry.kAttackEndAnim then
        self.spunUp = false
        self:StopSound(Sentry.kAttackSoundName)
    end
    
    if animName == self:GetPowerDownAnimation() then
        self.poweringDown = false
    end
        
end

function Sentry:UpdateAttackTarget()

    local target = self:GetTarget()
    local order = self:GetCurrentOrder()
    local orderLocation = ConditionalValue(order ~= nil, order:GetLocation(), nil)
    
    local attackEntValid = (target ~= nil and GetCanSeeEntity(self, target) and (target:GetOrigin() - self:GetOrigin()):GetLength() < Sentry.kRange)
    local attackLocationValid = (order:GetType() == kTechId.Attack and orderLocation ~= nil)
    
    if (attackEntValid or attackLocationValid) and (self.timeNextAttack == nil or (Shared.GetTime() > self.timeNextAttack)) then
    
        local currentAnim = self:GetAnimation()
        
        if self.spunUp then
    
            self:FireBullets()

            self:SetAnimation(Sentry.kAttackAnim)
            
            Shared.PlayWorldSound(nil, Sentry.kAttackSoundName, nil, self:GetModelOrigin())

            // Random rate of fire so it can't be gamed         
            self.timeNextAttack = Shared.GetTime() + Sentry.kBaseROF + NetworkRandom() * Sentry.kRandROF
            
        elseif self:GetAnimation() ~= Sentry.kAttackStartAnim then
        
            // Spin up
            self:SetAnimation(Sentry.kAttackStartAnim)
            
            self:PlaySound(Sentry.kSpinUpSoundName)
                
            self.timeNextAttack = Shared.GetTime() + self:GetAnimationLength(Sentry.kAttackStartAnim)
            
        else
            self.timeNextAttack = Shared.GetTime() + .1
        end        

    end    
   
end

function Sentry:FireBullets()

    local worldAimYaw = self:GetAngles().yaw - (self.barrelYawDegrees/180) * math.pi
    local worldAimPitch = self:GetAngles().pitch + (self.barrelPitchDegrees/180) * math.pi
    local direction = GetNormalizedVector(Vector(math.sin(worldAimYaw), math.sin(worldAimPitch), math.cos(worldAimYaw)))    
    
    local fireCoords = BuildCoords(Vector(0, 1, 0), direction)
    local startPoint = self:GetAttachPointOrigin(Sentry.kMuzzleNode)    
    
    for bullet = 1, Sentry.kBulletsPerSalvo do

        // Add some spread to bullets
        local x = (NetworkRandom(string.format("%s:FireBullet %d, %d", self:GetClassName(), bullet, 1)) - .5) + (NetworkRandom(string.format("%s:FireBullet %d, %d", self:GetClassName(), bullet, 2)) - .5)
        local y = (NetworkRandom(string.format("%s:FireBullet %d, %d", self:GetClassName(), bullet, 3)) - .5) + (NetworkRandom(string.format("%s:FireBullet %d, %d", self:GetClassName(), bullet, 4)) - .5)
        
        local spreadDirection = direction + x * Sentry.kSpread.x * fireCoords.xAxis + y * Sentry.kSpread.y * fireCoords.yAxis
        local endPoint = startPoint + spreadDirection * Sentry.kRange
        
        local trace = Shared.TraceRay(startPoint, endPoint, PhysicsMask.AllButPCs, EntityFilterOne(self))
        
        if (trace.fraction < 1) then
        
            Shared.CreateEffect(nil, Sentry.kTracerEffect, nil, Coords.GetTranslation(trace.endPoint))
            
            if not GetBlockedByUmbra(trace.entity) then
            
                Shared.CreateEffect(nil, ScriptActor.kSparksEffect, nil, Coords.GetTranslation(trace.endPoint))
                
                // Play ricochet sound 
                local surface = GetSurfaceFromTrace(trace)
                
                if(surface ~= "" and surface ~= nil and surface ~= "unknown") then

                    // Play ricochet sound at world position for everyone else
                    Shared.PlayWorldSound(player, string.format(Sentry.kRicochetMaterialSound, surface), nil, trace.endPoint)
                    
                end
                                   
                if Server then
                if trace.entity and trace.entity.TakeDamage then
                
                    local direction = (trace.endPoint - startPoint):GetUnit()
                    
                    trace.entity:TakeDamage(Sentry.kDamagePerBullet, player, self, endPoint, direction)
					// When bullets hit targets, apply force to send them backwards
					//from minigun code
					if(trace.entity:isa("Player")) then
					
						// Take player mass into account
						local impulseVelocity = GetNormalizedVector(direction) * ((100) / trace.entity:GetMass())
						//Print("targetvel x %f y %f z %f impulse x %f y %f z %f",trace.entity:GetVelocity().x,trace.entity:GetVelocity().y,trace.entity:GetVelocity().z,impulseVelocity.x,impulseVelocity.y,impulseVelocity.z)
						local targetVelocity = trace.entity:GetVelocity() + impulseVelocity
						
						trace.entity:SetVelocity(targetVelocity)
					end                   
                end
                end
                
            end
            
        end
    
    end
    
    self:CreateAttachedEffect(Sentry.kFireEffect, Sentry.kMuzzleNode)
    
    self:CreateAttachedEffect(Sentry.kBarrelSmokeEffect, Sentry.kMuzzleNode)

    if Server then
    self:GetTeam():TriggerAlert(kTechId.MarineAlertSentryFiring, self)    
    end
    
end

// Update rotation state when setting target
function Sentry:UpdateSetTarget()

    if self.settingTarget then
    
        // Get position of target and set facing to it
        if self.poweringDown then
        
            // Don't rotate while powering down
            return
            
        end
        
        local currentOrder = self:GetCurrentOrder()
        if currentOrder ~= nil then
        
            local target = self:GetTarget()
            
            local vecToTarget = nil
            if currentOrder:GetLocation() ~= nil then
                vecToTarget = currentOrder:GetLocation() - self:GetModelOrigin()
            elseif target ~= nil then
                vecToTarget =  target:GetModelOrigin() - self:GetModelOrigin()
            else
                Print("Sentry:UpdateSetTarget(): sentry has attack order without valid entity id or location.")
                self:CompletedCurrentOrder()
                return 
            end            
            
            // Move sentry to face target point
            local currentYaw = self:GetAngles().yaw
            local desiredYaw = GetYawFromVector(vecToTarget)
            local newYaw = InterpolateAngle(currentYaw, desiredYaw, .16)

            local angles = Angles(self:GetAngles())
            angles.yaw = newYaw
            self:SetAngles(angles)
                        
            // Check if we're close enough to final orientation
            if(math.abs(newYaw - desiredYaw) == 0) then

                self:CompletedCurrentOrder()
                
                self.settingTarget = false
                
                // So barrel doesn't "snap" after power-up
                self.barrelYawDegrees = 0
                
                self:SetAnimation(Structure.kAnimPowerUp)
                
            end
            
        else
        
            // Deleted order while setting target
            self.settingTarget = false
            
        end 
       
    else
    
        local powerDownAnim = self:GetPowerDownAnimation()
        if powerDownAnim ~= "" then
            self:SetAnimation(powerDownAnim)
        end
        
        self.poweringDown = true
        self:StopSound(Sentry.kAttackSoundName)
        
        self.settingTarget = true

        // Move barrel towards looking straight forward like in anim                
        self.desiredYawDegrees = 0

    end
    
end

function Sentry:UpdateTargetVariables()

    local order = self:GetCurrentOrder()

    // Update hasTarget so model swings towards target entity or location
    local hasTarget = false
    
    if order ~= nil then
    
        // We have a target if we attacking an entity that's still valid or attacking ground
        local orderParam = order:GetParam()
        hasTarget = (order:GetType() == kTechId.Attack or order:GetType() == kTechId.SetTarget) and 
                    ((orderParam ~= Entity.invalidId and self:GetIsTargetValid(Shared.GetEntity(orderParam)) or (orderParam == Entity.invalidId)) )
    end
    
    if not hasTarget and self.hasTarget then
    
        self:CompletedCurrentOrder()
        
    end
    
    self.hasTarget = hasTarget
    
    if hasTarget then
    
        local target = self:GetTarget()
        if target ~= nil then
            self.targetDirection = GetNormalizedVector(target:GetEngagementPoint() - self:GetAttachPointOrigin(Sentry.kMuzzleNode))
        else
            self.targetDirection = GetNormalizedVector(self:GetCurrentOrder():GetLocation() - self:GetAttachPointOrigin(Sentry.kMuzzleNode))
        end
        
    else
        self.targetDirection = nil
    end
end

function Sentry:OnThink()

    Structure.OnThink(self)

    // If alive and built (map-placed structures don't die when killed)
    if self:GetIsBuilt() and self:GetIsAlive() and self:GetIsActive() then
    
        // If we have order
        local order = self:GetCurrentOrder()
        if order ~= nil and (order:GetType() == kTechId.SetTarget) then
        
            self:UpdateSetTarget()
                
        else
        
            // Get new attack order if any enemies nearby
            if not self:AcquireTarget() then
                self:StopSound(Sentry.kAttackSoundName)
            end
            
            // We may have gotten a new order in acquire target
            order = self:GetCurrentOrder()
        
            // Or "ping" if we have no target    
            if(order == nil and (self.timeLastScanSound == 0 or Shared.GetTime() > self.timeLastScanSound + Sentry.kPingInterval)) then
        
                Shared.PlayWorldSound(nil, Sentry.kSentryScanSoundName, nil, self:GetModelOrigin())
                self.timeLastScanSound = Shared.GetTime()
            
            end

        end

        self:UpdateTargetVariables()
        
        // Play spin-down animation
        if not self.hasTarget and self.spunUp and self:GetAnimation() ~= Sentry.kAttackEndAnim then
        
            self:SetAnimation(Sentry.kAttackEndAnim)
            self:PlaySound(Sentry.kSpinDownSoundName)
            
        end
  
    end
                
    self:SetNextThink(Sentry.kScanThinkInterval)
        
end

function Sentry:GetDamagedAlertId()
    return kTechId.MarineAlertSentryUnderAttack
end