// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\LiveScriptActor_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================


// Client version of TakeDamage(). Just call OnTakeDamage() for pushing around ragdolls and such.
function LiveScriptActor:TakeDamage(damage, attacker, doer, point, direction)

    local killed = false
    
    if (self:GetIsAlive()) then
    
        self:OnTakeDamage(damage, doer, point)
        
    end
    
    return killed
    
end

function LiveScriptActor:OnTakeDamage(damage, doer, point)
end

function LiveScriptActor:OnSynchronized()

    PROFILE("LiveScriptActor:OnSynchronized")

    ScriptActor.OnSynchronized(self)
    self:SetPoseParameters()
    
end

// Display text when selected
function LiveScriptActor:GetCustomSelectionText()
    return ""
end
    