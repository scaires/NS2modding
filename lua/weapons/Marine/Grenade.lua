//=============================================================================
//
// lua\Weapons\Marine\Grenade.lua
//
// Created by Charlie Cleveland (charlie@unknownworlds.com)
// Copyright (c) 2010, Unknown Worlds Entertainment, Inc.
//
//=============================================================================
Script.Load("lua/Weapons/Projectile.lua")

class 'Grenade' (Projectile)

Grenade.kMapName            = "grenade"
Grenade.kModelName          = PrecacheAsset("models/marine/rifle/rifle_grenade.model")
Grenade.kExplosionSound     = PrecacheAsset("sound/ns2.fev/marine/common/explode")
Grenade.kExplosionEffect    = "cinematics/materials/%s/grenade_explosion.cinematic"
PrecacheMultipleAssets(Grenade.kExplosionEffect, kSurfaceList)

Grenade.kDamageRadius       = 10
//Use balance.lua value
Grenade.kMaxDamage          = kGrenadeLauncherDamage
Grenade.kThinkInterval = .3
Grenade.kLifetime = 5
Grenade.kMinVelocity = 3

function Grenade:OnCreate()

    Projectile.OnCreate(self)
    self:SetModel( Grenade.kModelName )
    self.timeSpawned = Shared.GetTime()
	self:SetNextThink(Grenade.kThinkInterval)
end

function Grenade:GetDeathIconIndex()
    return kDeathMessageIcon.Grenade
end

function Grenade:GetDamageType()
	return kGrenadeLauncherDamageType
end

if (Server) then
	function Grenade:OnThink()

		if( Shared.GetTime() > (self.timeSpawned + Grenade.kLifetime) ) or self:GetVelocity():GetLength() < Grenade.kMinVelocity then
			
			self:GrenadeExplode()
		
			// Go away after a time
			DestroyEntity(self)

		else
		
			self:SetNextThink(Grenade.kThinkInterval)
			
		end
		
	end
	
	function Grenade:GrenadeExplode()
		// Play sound and particle effect
		Shared.PlayWorldSound(nil, Grenade.kExplosionSound, nil, self:GetOrigin())
		
		// Do damage to targets
		local hitEntities = GetGamerules():GetEntities("LiveScriptActor", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), Grenade.kDamageRadius)
		
		// Remove self
		table.removevalue(hitEntities, self)

		RadiusDamage(hitEntities, self:GetOrigin(), Grenade.kDamageRadius, Grenade.kMaxDamage, self:GetOwner())

		if self.physicsBody then

			local surface = GetSurfaceFromEntity(targetHit)
			
			if(surface ~= "" and surface ~= nil and surface ~= "unknown") then
				Shared.CreateEffect(nil, string.format(Grenade.kExplosionEffect, surface), nil, BuildCoords(Vector(0, 1, 0), Vector(0, 0, 1), self.physicsBody:GetCoords().origin, 1))    
			end
			
		end	
	end
	
    function Grenade:OnCollision(targetHit)
    
        if targetHit ~= nil and (targetHit:isa("LiveScriptActor") and GetGamerules():CanEntityDoDamageTo(self, targetHit)) and
            self:GetOwner() ~= targetHit then
            
			self:GrenadeExplode()

            // Destroy first, just in case there are script errors below somehow
            DestroyEntity(self)
            
        end
        
    end    

end

Shared.LinkClassToMap("Grenade", Grenade.kMapName)