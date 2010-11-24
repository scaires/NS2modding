// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\RoboticsFactory.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")

class 'RoboticsFactory' (Structure)

RoboticsFactory.kMapName = "roboticsfactory"

RoboticsFactory.kModelName = PrecacheAsset("models/marine/robotics_factory/robotics_factory.model")

RoboticsFactory.kActiveEffect = PrecacheAsset("cinematics/marine/roboticsfactory/active.cinematic")
RoboticsFactory.kDeathEffect = PrecacheAsset("cinematics/marine/roboticsfactory/death.cinematic")

function RoboticsFactory:OnInit()

    self:SetModel(RoboticsFactory.kModelName)
    
    Structure.OnInit(self)
    
end

function RoboticsFactory:GetRequiresPower()
    return true
end

function RoboticsFactory:GetTechButtons(techId)

    if(techId == kTechId.RootMenu) then
    
        local techButtons = {   kTechId.MASC, kTechId.MASCArmorTech, kTechId.MASCSplashTech, kTechId.None, 
                                kTechId.SetRally, kTechId.None, kTechId.None, kTechId.None, 
                                kTechId.None, kTechId.None, kTechId.None, kTechId.Recycle }
        
        return techButtons
        
    end
    
    return nil
    
end

function RoboticsFactory:GetDeathEffect()
    return RoboticsFactory.kDeathEffect
end

Shared.LinkClassToMap("RoboticsFactory", RoboticsFactory.kMapName, {})

