// ======= Copyright � 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Fade_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Fade:InitWeapons()

    Alien.InitWeapons(self)
    
    self:GiveItem(SwipeBlink.kMapName)
    self:GiveItem(StabBlink.kMapName)

    self:SetActiveWeapon(SwipeBlink.kMapName)
    
end

function Fade:GetKilledSound(doer)
    return Fade.kDieSoundName
end

function Fade:GetCanTakeDamage()
    return Alien.GetCanTakeDamage(self) and not self:GetIsBlinking()
end

function Fade:OnUpdate(deltaTime)

    Alien.OnUpdate(self, deltaTime)
    self:SetIsVisible(not self:GetIsBlinking())
    
end