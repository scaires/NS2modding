// ======= Copyright � 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\GrenadeLauncher.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Marine/Rifle.lua")
Script.Load("lua/Weapons/Marine/Grenade.lua")

class 'GrenadeLauncher' (Rifle)

GrenadeLauncher.kMapName              = "grenadelauncher"

GrenadeLauncher.kModelName = PrecacheAsset("models/marine/rifle/rifle.model")

GrenadeLauncher.kFireSoundName = PrecacheAsset("sound/ns2.fev/marine/rifle/fire_grenade")
GrenadeLauncher.kReloadSoundName = PrecacheAsset("sound/ns2.fev/marine/rifle/reload_grenade")
GrenadeLauncher.kMuzzleFlashEffect = PrecacheAsset("cinematics/marine/gl/muzzle_flash.cinematic")
GrenadeLauncher.kBarrelSmokeEffect = PrecacheAsset("cinematics/marine/gl/barrel_smoke.cinematic")
GrenadeLauncher.kShellEffect = PrecacheAsset("cinematics/marine/gl/shell.cinematic")

// Grenade launcher attachment
GrenadeLauncher.kAnimAttack = "attack_grenade"
GrenadeLauncher.kAnimReloadGrenade = "reload_grenade"
GrenadeLauncher.kAnimDraw = "draw_grenade"

GrenadeLauncher.kLauncherFireDelay = kGrenadeLauncherFireDelay
GrenadeLauncher.kAuxClipSize = 1
GrenadeLauncher.kLauncherStartingAmmo = 2 * kGrenadeLauncherClipSize
GrenadeLauncher.kGrenadesPerAmmoClip = kGrenadeLauncherClipSize
GrenadeLauncher.kGrenadeDamage = kGrenadeLauncherDamage

local networkVars =
    {
        auxAmmo = string.format("integer (0 to %d)", GrenadeLauncher.kLauncherStartingAmmo),
        auxClip = string.format("integer (0 to %d)", GrenadeLauncher.kAuxClipSize),
    }
    
function GrenadeLauncher:GetViewModelName()
    return Rifle.kViewModelName
end

function GrenadeLauncher:GetMuzzleFlashEffect()
    return GrenadeLauncher.kMuzzleFlashEffect
end

function GrenadeLauncher:GetBarrelSmokeEffect()
    return GrenadeLauncher.kBarrelSmokeEffect
end

function GrenadeLauncher:GetShellEffect()
    return GrenadeLauncher.kShellEffect
end

function GrenadeLauncher:GetDrawAnimation(previousWeaponMapName)

    if not self.drawnOnce then
        self.drawnOnce = true
        return GrenadeLauncher.kAnimDraw
    end
    
    return Rifle.GetDrawAnimation(self, previousWeaponMapName)
    
end

function GrenadeLauncher:GetTechId()
    return kTechId.GrenadeLauncher
end

function GrenadeLauncher:GetNeedsAmmo()
    return Rifle.GetNeedsAmmo(self) or self.auxClip < GrenadeLauncher.kAuxClipSize or self.auxAmmo < GrenadeLauncher.kLauncherStartingAmmo
end

function GrenadeLauncher:GetHUDSlot()
    return kPrimaryWeaponSlot
end

function GrenadeLauncher:GiveAmmo(clips)
    
    // Give half to GL and any not used, give to rifle
    local glClips = clips/2
    local grenades = glClips * GrenadeLauncher.kGrenadesPerAmmoClip 
    
    local grenadesUsed = math.min(GrenadeLauncher.kLauncherStartingAmmo - self.auxAmmo - 1, grenades)
    self.auxAmmo = self.auxAmmo + grenadesUsed
    
    local clipsLeft = (clips - glClips) + (grenades - grenadesUsed) * GrenadeLauncher.kGrenadesPerAmmoClip 
    
    if clipsLeft > 0 then
        Rifle.GiveAmmo(self, clipsLeft)
    end
    
end

function GrenadeLauncher:GetAuxClip()
    // Return how many grenades we have left. Naming seems strange but the 
    // "clip" for the GL is how many grenades we have total.
    return self.auxAmmo
end

function GrenadeLauncher:GetSecondaryAttackDelay()
    return GrenadeLauncher.kLauncherFireDelay
end

// Fire grenade with secondary attack
function GrenadeLauncher:OnSecondaryAttack(player)

    if (self.auxClip > 0) then
    
        // Play effects
        player:SetViewAnimation(GrenadeLauncher.kAnimAttack)
        
        player:SetActivityEnd(self:GetSecondaryAttackDelay() * player:GetCatalystFireModifier())

        // Play the fire animation on the character.
        player:SetOverlayAnimation(Marine.kAnimOverlayFire)
        
        Shared.PlaySound(player, GrenadeLauncher.kFireSoundName)
        
        player:DeactivateWeaponLift()
        
        // Fire grenade projectile
        if Server then
        
            local viewAngles = player:GetViewAngles()
            local viewCoords = viewAngles:GetCoords()
            // The eye position just barely sticks out past some walls so we
            // need to move the emit point back a tiny bit to compensate.
            local startPoint = player:GetEyePos() - (viewCoords.zAxis * 0.2)
            
            local grenade = CreateEntity(Grenade.kMapName, startPoint, player:GetTeamNumber())
            SetAnglesFromVector(grenade, viewCoords.zAxis)
            
            // Inherit player velocity?
            local startVelocity = viewCoords.zAxis * 15 + Vector(0, 3, 0)
            grenade:SetVelocity(startVelocity)
            
            // Set grenade owner to player so we don't collide with ourselves and so we
            // can attribute a kill to us
            grenade:SetOwner(player)
            
        end
        
        self.auxClip = self.auxClip - 1
        
    elseif (not self:ReloadGrenade(player)) then

        player:DeactivateWeaponLift()
        
        player:SetActivityEnd(self:GetSecondaryAttackDelay() * player:GetCatalystFireModifier())
        
    end
    
end

function GrenadeLauncher:CanReload()
    return ClipWeapon.CanReload(self) or (self.auxClip == 0 and self.auxAmmo > 0)
end

function GrenadeLauncher:OnInit()

    Rifle.OnInit(self)
    
    self.auxAmmo = GrenadeLauncher.kLauncherStartingAmmo
    self.auxClip = 0
    
end

function GrenadeLauncher:ReloadGrenade(player)
    
    local success = false
    
    // Automatically reload if we're out of ammo - don't have to hit a key
    if (self.auxClip < GrenadeLauncher.kAuxClipSize) and (self.auxAmmo > 0) and player:GetCanNewActivityStart() then
        
        // Play the reload sequence and don't let it be interrupted until it finishes playing.
        local length = player:SetViewAnimation(GrenadeLauncher.kAnimReloadGrenade)
        player:SetActivityEnd(length)
        
        Shared.PlaySound(player, GrenadeLauncher.kReloadSoundName)
        
        // Play the reload animation on the character.
        player:SetOverlayAnimation(Player.kAnimReload)
        
        self.auxClip = self.auxClip + 1
        
        self.auxAmmo = self.auxAmmo - 1
        
        success = true
        
    end
    
    return success
    
end

function GrenadeLauncher:OnProcessMove(player, input)

    ClipWeapon.OnProcessMove(self, player, input)
    
    self:ReloadGrenade(player)
    
end

function GrenadeLauncher:UpdateViewModelPoseParameters(viewModel, input)
    
    Rifle.UpdateViewModelPoseParameters(self, viewModel, input)
    
    viewModel:SetPoseParam("hide_gl", 0)
    viewModel:SetPoseParam("gl_empty", ConditionalValue(self.auxClip == 0, 1, 0))    
    
end

Shared.LinkClassToMap("GrenadeLauncher", GrenadeLauncher.kMapName, networkVars)