// ======= Copyright � 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\BlendedActor.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Handles animation blending, overlay animations and idling.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Actor.lua")

class 'BlendedActor' (Actor)

BlendedActor.kMapName = "blendedactor"

local networkVars = 
{   
    // Overlay animations
    overlayAnimationSequence    = "compensated integer (-1 to " .. Actor.maxAnimations .. ")",
    overlayAnimationStart       = "compensated float", 
    
    // Animation blending
    prevAnimationSequence       = "compensated integer (-1 to " .. Actor.maxAnimations .. ")",
    prevAnimationStart          = "compensated float",
    blendTime                   = "compensated float",
    
    // Idling
    nextIdleTime                = "float", 
}

// Called right after an entity is created on the client or server. This happens through Server.CreateEntity, 
// or when a server-created object is propagated to client. 
function BlendedActor:OnCreate()    

    Actor.OnCreate(self)

    // Overlay animations
    self.overlayAnimationSequence   = Model.invalidSequence
    self.overlayAnimationStart      = 0

    // Animation blending    
    self.prevAnimationSequence      = Model.invalidSequence
    self.prevAnimationStart         = 0
    self.blendTime                  = 0.0
    
    self.nextIdleTime               = 0
    
end

function BlendedActor:ResetAnimState()

    Actor.ResetAnimState(self)
    
    self.overlayAnimationSequence   = Model.invalidSequence
    self.overlayAnimationStart      = 0
    
    self.prevAnimationSequence      = Model.invalidSequence
    self.prevAnimationStart         = 0
    self.blendTime                  = 0.0
    
    self.nextIdleTime               = 0

end

// Allow children to process animation names to translate something like 
// "idle" to "bite_idle" depending on current state
function BlendedActor:GetCustomAnimationName(baseAnimationName)
    return baseAnimationName
end

function BlendedActor:GetCanIdle()
    return true
end

// Return empty string for no idling
function BlendedActor:GetIdleAnimation()
    return ""
end

// Default movement blending time
function BlendedActor:GetBlendTime()
    return .2
end

/* Sets default blend length when not otherwise specified */
function BlendedActor:SetBlendTime( blendTime )
    self.blendTime = blendTime
end

function BlendedActor:SetAnimation(sequenceName, force, animSpeed)

    if Actor.SetAnimation(self, sequenceName, force, animSpeed) then
    
        local length = self:GetAnimationLength(sequenceName)        
        if(length > 0) then
        
            if animSpeed then
                length = length / animSpeed
            end
        
            self.nextIdleTime = Shared.GetTime() + length
            
        end

        return true
        
    end
    
    return false
    
end

/**
 * Sets the primary animation, blending into it from the currently playing
 * animation. The blendTime specifies the time (in seconds) over which
 * the new animation will be blended in. Note the model can only blend
 * between two animations at a time, so if an an animation is already being
 * blended in, there will be a pop. If nothing passed for blendTime, it
 * uses the default blend time. Returns true if the animation was changed.
 */
function BlendedActor:SetAnimationWithBlending(baseAnimationName, blendTime, force, speed)

    if(baseAnimationName == "" or baseAnimationName == nil) then
        return false
    end
    
    if(type(baseAnimationName) ~= "string") then
        Print("%s:SetAnimationWithBlending(%s): Didn't pass a string.", tostring(baseAnimationName))
        return false
    end
    
    if(blendTime == nil) then
        blendTime = self:GetBlendTime()
    end

    // Translate animation name to one that uses current weapon    
    animationName = self:GetCustomAnimationName(baseAnimationName)
    
    if(force == nil or force == false) then
    
        local newSequence = self:GetAnimationIndex(animationName)
        if((newSequence == self.prevAnimationSequence) and (newSequence ~= Model.invalidSequence) and (Shared.GetTime() < (self.prevAnimationStart + self.blendTime))) then
            return false
        end
        
    end
    
    // If we don't have a weapon-specific animation, try to play the base one
    if(self:GetAnimationIndex(animationName) == Model.invalidSequence) then
        animationName = baseAnimationName
    end
    
    local theCurrentAnimName = self:GetAnimation()
    
    // If we're already playing this and it hasn't expired, do nothing new
    if(theCurrentAnimName == animationName and not force and not self.animationComplete) then
    
        // If we've already blended with previous animation once, blend no more
        if((self.prevAnimationSequence ~= Model.invalidSequence) and (Shared.GetTime() > self.prevAnimationStart + self.blendTime)) then
            self.prevAnimationSequence = Model.invalidSequence
        end

        return false
        
    end

    // If we have no animation or are already playing this animation, don't blend
    if(theCurrentAnimName ~= nil and theCurrentAnimName ~= animationName) then    
        self.prevAnimationSequence = self:GetAnimationIndex(theCurrentAnimName)
        self.prevAnimationStart    = self.animationStart
        self.blendTime             = blendTime
    else
        self.prevAnimationSequence = Model.invalidSequence
        self.prevAnimationStart = 0
    end
    
    return self:SetAnimation(animationName, force, speed)
    
end

function BlendedActor:SetOverlayAnimation(animationName, dontForce)

    if( animationName == nil or animationName == "") then
    
        self.overlayAnimationSequence = Model.invalidSequence
    
    elseif ( animationName ~= nil ) then
    
        // Try to play the weapon or player specific version of this animation 
        local theAnimName = self:GetCustomAnimationName(animationName)
        local index = self:GetAnimationIndex(theAnimName)
        if(index == Model.invalidSequence) then
            // ...but fall back to base if there is none 
            theAnimName = animationName
            index = self:GetAnimationIndex( theAnimName )
        end
        
        // Don't reset it if already playing
        if(index ~= Model.invalidSequence) and ((self.overlayAnimationSequence ~= index) or (not dontForce)) then
            self.overlayAnimationSequence = index
            self.overlayAnimationStart    = Shared.GetTime()
            
            //self.nextIdleTime = Shared.GetTime() + self:GetAnimationLength(animationName)
            //Print("%s (%d):SetOverlayAnimation(%s) (set next idle to %.2f)", self:GetMapName(), self:GetId(), theAnimName, self.nextIdleTime)
        end
        
    end

end

// Stop playing specified overlay animation if it's playing
function BlendedActor:StopOverlayAnimation(animationName)

    local success = false
    
    if( animationName ~= nil and animationName ~= "") then
    
        if self.overlayAnimationSequence ~= Model.invalidSequence then
        
            // Try to play the weapon or player specific version of this animation 
            local customAnimName = self:GetCustomAnimationName(animationName)
            local index = self:GetAnimationIndex(customAnimName)
            
            if(index ~= Model.invalidSequence) then
            
                if self.overlayAnimationSequence == index then
                
                    self.overlayAnimationSequence = Model.invalidSequence
                    success = true
                    
                end
                
            end
            
        end
        
    else
        Print("%s:StopOverlayAnimation(): Must specify an animation name.", self:GetClassName())
    end
    
    return success
    
end

function BlendedActor:GetOverlayAnimationFinished()

    local finished = false
    
    if(self.overlayAnimationSequence ~= Model.invalidSequence) then
    
        local animName = self:GetOverlayAnimation()
        finished = (Shared.GetTime() > self.overlayAnimationStart + self:GetAnimationLength(animName))
        
    end
    
    return finished
    
end

function BlendedActor:GetOverlayAnimation()

    local overlayAnimName = ""
    
    if(self.overlayAnimationSequence ~= Model.invalidSequence) then
        overlayAnimName = self:GetAnimation(self.overlayAnimationSequence)
    end
    
    return overlayAnimName
    
end

/**
 * Called by the engine to construct the pose of the bones for the actor's model.
 */
function BlendedActor:BuildPose(poses)
    
    Actor.BuildPose(self, poses)

    // If we have a previous animation, blend it in.
    if (self.prevAnimationSequence ~= Model.invalidSequence) then

        if(self.blendTime ~= nil and self.blendTime > 0) then
        
            local time     = Shared.GetTime()
            local fraction = Clamp( (time - self.animationStart) / self.blendTime, 0, 1 )
            
            if (fraction < 1) then
                self:BlendAnimation(poses, self.prevAnimationSequence, self.prevAnimationStart, 1 - fraction)
            end
            
        end
    
    end

    // Apply the overlay animation if we have one.
    if (self.overlayAnimationSequence ~= Model.invalidSequence) then
        self:AccumulateAnimation(poses, self.overlayAnimationSequence, self.overlayAnimationStart)
    end
    
end

// Called whenever actor is not doing anything else. Play idle animation, trigger reload, etc.
// Called when current time passes nextIdleTime. Return time of next idle, or nil to not
// update next idle time. Enable or disable idling through GetCanIdle().
function BlendedActor:OnIdle()

    // Play interruptable idle animation
    local animName = self:GetIdleAnimation()
    
    if(animName ~= "" and self:GetAnimationLength(animName) > 0) then
    
        self:SetAnimation(animName, true)
        
    end
        
end

// Called every tick
function BlendedActor:OnUpdate(deltaTime)

    Actor.OnUpdate( self, deltaTime )
    
    if not Shared.GetIsRunningPrediction() then
        self:UpdateAnimation( deltaTime )
    end        
    
end

function BlendedActor:GetName()
    return self:GetMapName()
end

function BlendedActor:ForceIdle()
    self.nextIdleTime = 0
end

function BlendedActor:UpdateAnimation(timePassed)

    // Run idles on the server only until we have shared random numbers
    if self:GetIsVisible() and self.modelIndex ~= 0 then
    
        if self:GetOverlayAnimationFinished() then
        
            self.overlayAnimationSequence   = Model.invalidSequence
            self.overlayAnimationStart      = 0
            
        end
    
        if(self.nextIdleTime ~= nil and self.nextIdleTime ~= -1 and Shared.GetTime() > self.nextIdleTime and self:GetCanIdle()) then
        
           self:OnIdle()
            
        end    
        
    end
    
end

// Called with name of animation that finished. Called at end of looping animation also.
function BlendedActor:OnAnimationComplete(animationName)
    self.prevAnimationSequence = Model.invalidSequence
end

Shared.LinkClassToMap("BlendedActor", BlendedActor.kMapName, networkVars )