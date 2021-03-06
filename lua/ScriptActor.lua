// ======= Copyright � 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ScriptActor.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Base class for all visible entities in NS2. Players, weapons, structures, etc.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Globals.lua")
Script.Load("lua/BlendedActor.lua")

class 'ScriptActor' (BlendedActor)

ScriptActor.kMapName = "scriptactor"

if (Server) then
    Script.Load("lua/ScriptActor_Server.lua")
else
    Script.Load("lua/ScriptActor_Client.lua")
end

ScriptActor.kSparksEffect = PrecacheAsset("cinematics/sparks.cinematic")

// Attach point names for effects
ScriptActor.kHurtNode = "fxnode_hurt"
ScriptActor.kHurtSevereNode = "fxnode_hurt_severe"
ScriptActor.kDeathNode = "fxnode_death"

local networkVars = 
{   
    // Team type (marine, alien, neutral)
    teamType                    = string.format("integer (0 to %d)", kRandomTeamType),
    
    // Never set this directly, call SetTeamNumber()
    teamNumber                  = string.format("integer (-1 to %d)", kSpectatorIndex),
    
    // Whether this entity is in sight of the enemy team
    sighted                     = "boolean",
            
    // The technology this object represents
    techId                      = string.format("integer (0 to %d)", kTechIdMax),
    
    // Entity that is attached to us (if we're a tech point, resource nozzle, etc.)
    attachedId                  = "entityid",
    
    // Player that "owns" this unit. Shouldn't be set for players. Gets credit
    // for kills.
    owner                       = "entityid",
    
    // Id used to look up precached string representing room location ("Marine Start")
    locationId                  = "integer"
    
}

ScriptActor.kMass = 100

// Called right after an entity is created on the client or server. This happens through Server.CreateEntity, 
// or when a server-created object is propagated to client. 
function ScriptActor:OnCreate()    

    BlendedActor.OnCreate(self)

    self.teamType = kNeutralTeamType
    
    self.sighted = false
    
    self.teamNumber = -1

    self.techId = LookupTechId(self:GetMapName(), kTechDataMapName, kTechId.None)
    
    self.attachedId = Entity.invalidId
    
    self.ownerServerClient = nil
    // Stores all the entities that are owned by this ScriptActor.
    self.ownedEntities = { }
    
    self.locationId = 0
    
    if(Server) then
    
        if not self:GetIsMapEntity() then
            self:SetTeamNumber(kTeamReadyRoom)
        end
        
    end
    
    // Remember if we've called OnInit() for entities that are propagated to the client
    if(Client) then
    
        self.clientInitedOnSynch = false
        
    end
    
end

// Called after OnCreate and before OnInit, if entity has been loaded from the map. Use it to 
// read class values from the editor_setup file. Convert parameters from strings to numbers. 
// It's safe to call Shared.PrecacheModel and Shared.PrecacheSound in this function. Team hasn't 
// been set.
function ScriptActor:OnLoad()

    BlendedActor.OnLoad(self)
    
    local teamNumber = GetAndCheckValue(self.teamNumber, 0, 2, "teamNumber", 0)
    
    // Set to nil to prevent OnTeamChange() from being called before it's set for the first time
    self.teamNumber = -1
    
    self:SetTeamNumber(teamNumber)
    
end

// Called when entity is created via CreateEntity(), after OnCreate(). Team number and origin will be set properly before it's called.
// Also called on client each time the entity gets created locally, due to proximity. This won't be called on the server for 
// pre-placed map entities.
function ScriptActor:OnInit()

    local techId = self:GetTechId()
    
    if techId ~= kTechId.None then
    
        local modelName = LookupTechData(techId, kTechDataModel, nil)
        if modelName ~= nil and modelName ~= "" then
        
            self:SetModel(modelName)

        // Don't emit error message if they specified no model 
        elseif modelName ~= "" then
        
            Print("%s:OnInit() (ScriptActor): Couldn't find model name for techId %d (%s).", self:GetClassName(), techId, EnumToString(kTechId, techId))
            
        end
        
    end
    
    BlendedActor.OnInit(self)

end

function ScriptActor:ComputeLocation()

    if Server then
    
        self:SetLocationName(GetLocationForPoint(self:GetOrigin()), true)

    end

end

// Called when the game ends and a new game begins (or when the reset command is typed in console).
function ScriptActor:Reset()
    self:OnReset()   
end

function ScriptActor:SetOrigin(origin)
    BlendedActor.SetOrigin(self, origin)
    self:ComputeLocation()
end

function ScriptActor:OnReset()
    self:ComputeLocation()    
end

// Called when player entities are moved to a team location in the world. This is often after the player entity is created, but not always.
function ScriptActor:OnRespawn()
end

function ScriptActor:GetTeamType()
    return self.teamType
end

function ScriptActor:GetTeamNumber()
    return self.teamNumber
end

/**
 * Gets the view angles for entity.
 */
function ScriptActor:GetViewAngles(viewAngles)
    return self:GetAngles()
end

function ScriptActor:GetCanSeeEntity(targetEntity)
    return GetCanSeeEntity(self, targetEntity)
end

function ScriptActor:GetDamageType()
    return LookupTechData(self:GetTechId(), kTechDataDamageType, kDamageType.Normal)
end

// Return tech ids that represent research or actions for this entity in specified menu. Parameter is kTechId.RootMenu for
// default menu or a entity-defined menu id for a sub-menu. Return nil if this actor doesn't recognize a menu of that type.
// Used for drawing icons in selection menu and also for verifying which actions are valid for entities and when (ie, when
// a ARC can siege, or when a unit has enough energy to perform an action, etc.)
// Return list of 8 tech ids, represnting the 2nd and 3rd row of the 4x3 build icons.
function ScriptActor:GetTechButtons(techId)
    return nil
end

// Return techId that is the technology this entity represents. This is used to choose an icon to display to represent
// this entity and also to lookup max health, spawn heights, etc.
function ScriptActor:GetTechId()
    return self.techId
end

function ScriptActor:SetTechId(techId)
    self.techId = techId
    return true
end

// Allows entities to specify whether they can perform a specific research, activation, buy action, etc. If entity is
// busy deploying, researching, etc. it can return false. Pass in the player who is would be buying the tech.
// techNode could be nil for activations that aren't added to tech tree.
function ScriptActor:GetTechAllowed(techId, techNode, player)
    return true
end

function ScriptActor:GetMass()
    return ScriptActor.kMass
end

// Returns target point which AI units attack. Usually it's the model center
// but some models (open Command Station) can't be hit at the model center.
// Can also be used for units to "operate" on this unit (welding, construction, etc.)
function ScriptActor:GetEngagementPoint()
    return self:GetModelOrigin()
end

// Returns true if entity's build or health circle should be drawn (ie, if it doesn't appear to be at full health or needs building)
function ScriptActor:SetBuildHealthMaterial(entity)
    return false
end

function ScriptActor:GetViewOffset()
    return Vector(0, 0, 0)
end

function ScriptActor:GetFov()
    return 90
end

// TODO: Remove this (it should only be called by players)
function ScriptActor:GetEyePos()
    return self:GetOrigin() + self:GetViewOffset()
end

function ScriptActor:GetDescription()
    return LookupTechData(self:GetTechId(), kTechDataDisplayName, "<no description>")
end

// Something isn't working right here - has to do with references to points or vector
function ScriptActor:GetViewCoords()
    
    local viewCoords = self:GetViewAngles():GetCoords()   
    viewCoords.origin = self:GetEyePos()
    return viewCoords

end

function ScriptActor:GetCanBeUsed(player)
    return false
end

// To require that the entity needs to be used a certain point, return the name
// of an attach point here
function ScriptActor:GetUseAttachPoint()
    return ""
end

// Used by player. Returns true if entity was affected by use, false otherwise.
function ScriptActor:OnUse(player, elapsedTime, useAttachPoint)
end

function ScriptActor:OnTouch(player)
end

function ScriptActor:ForEachChild(functor)

    local childEntities = GetChildEntities(self)
    if(table.maxn(childEntities) > 0) then    
        for index, entity in ipairs(childEntities) do
            functor(entity)
        end
    end

end

// Returns true if seen visible by the enemy
function ScriptActor:GetIsSighted()
    return self.sighted
end

function ScriptActor:GetAttached()

    local attached = nil
    
    if(self.attachedId ~= Entity.invalidId) then
        attached = Shared.GetEntity(self.attachedId)
    end
    
    return attached
    
end

function ScriptActor:GetAttachPointOrigin(attachPointName)

    local attachPointIndex = self:GetAttachPointIndex(attachPointName)
    local coords = Coords.GetIdentity()
    local success = false
    
    if (attachPointIndex ~= -1) then
        coords = self:GetAttachPointCoords(attachPointIndex)
        success = true
    else
        Print("ScriptActor:GetAttachPointOrigin(%s, %s): Attach point not found.", self:GetMapName(), attachPointName)
    end
    
    return coords.origin, success
    
end

function ScriptActor:GetDeathIconIndex()
    return kDeathMessageIcon.None
end

function ScriptActor:GetParentId()

    local id = Entity.invalidId
    
    local parent = self:GetParent()
    if parent ~= nil then
        id = parent:GetId()
    end
    
    return id
    
end

// Called when a entity changes into another entity (players changing classes) or
// when an entity is destroyed. See GetEntityChange(). When an entity is destroyed,
// newId will be nil.
function ScriptActor:OnEntityChange(oldId, newId)
end

// Create a particle effect parented to this object and positioned and oriented with us, using 
// the specified attach point name. If called on a player, it's expected to also be called on the 
// player's client, as it won't be propagated to them.
function ScriptActor:CreateAttachedEffect(effectName, entityAttachPointName)
    Shared.CreateAttachedEffect(nil, effectName, self, self:GetCoords(), entityAttachPointName, false)
end

// Pass entity and proposed location, returns true if entity can go there without colliding with something
function ScriptActor:SpaceClearForEntity(location)
    // TODO: Collide model with world when model collision working
    return true
end

// Called when a player does a trace capsule and hits a script actor. Players don't have physics
// data currently, only hitboxes and trace capsules. If they did have physics data, they would 
// collide with themselves, so we have this instead. 
function ScriptActor:OnCapsuleTraceHit(entity)
end

function ScriptActor:GetLocationName()

    local locationName = ""
    
    if self.locationId ~= 0 then
        locationName = Shared.GetString(self.locationId)
    end
    
    return locationName
    
end

// Hooks into effect manager
function ScriptActor:TriggerEffects(effectName, tableParams)

    if effectName and effectName ~= "" then
    
        if not tableParams then
            tableParams = {}
        end
        
        tableParams[kEffectFilterClassName] = self:GetClassName()
        tableParams[kEffectHostCoords] = self:GetCoords()
        tableParams[kEffectFilterIsAlien] = (self.teamType == kAlienTeamType)
        
        GetEffectManager():TriggerEffects(effectName, tableParams, self)
        
    else
        Print("%s:TriggerEffects(): Called with invalid effectName)", self:GetClassName(), ToString(effectName))
    end
        
end

Shared.LinkClassToMap("ScriptActor", ScriptActor.kMapName, networkVars )