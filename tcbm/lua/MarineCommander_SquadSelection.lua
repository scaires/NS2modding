// ======= Copyright � 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Commander_SquadSelection.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// Client code to that handles squad selection and squad visualization.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function MarineCommander:InitSquadSelectionScreenEffects()

    self.metaballScreenEffect = Client.CreateScreenEffect("shaders/Metaballs.screenfx")
    self.maxRenderBlobSquads = 3
    self.ballRadius = 0.05
    self.minThreshold = 0.45
    self.maxThreshold = 0.50

end

function MarineCommander:DestroySquadSelectionScreenEffects()

    if(self.metaballScreenEffect ~= nil) then
        Client.DestroyScreenEffect(self.metaballScreenEffect)
        self.metaballScreenEffect = nil
    end

end

function MarineCommander:GetMaxNumSquadBalls()

    return GetMaxSquadSize()

end

function MarineCommander:GetMaxRenderBlobSquads()

    return self.maxRenderBlobSquads

end

function MarineCommander:GetSquadBallRadius()

    return self.ballRadius

end

function MarineCommander:GetSquadBallMinThreshold()

    return self.minThreshold

end

function MarineCommander:GetSquadBallMaxThreshold()

    return self.maxThreshold

end

function MarineCommander:GetSquadBallInfo()

    local virSquads = {}
    local i = 1

    while(i <= self:GetMaxRenderBlobSquads()) do
    
        virSquads[i] = { playerCount = 0, squadID = -1 }
        i = i + 1
        
    end
    
    local ballInfo = {}
    local squadEntities = GetEntitiesIsaInRadius(GetSquadClass(), self:GetTeamNumber(), self:GetOrigin(), 20, true)
    // Create list of squads nearby
    for index, entity in pairs(squadEntities) do
        
        // Only consider an entity if it is in a nearby squad
        if(entity ~= nil and entity.squad ~= nil and entity.squad > 0) then
        
            local virSquadID = -1
            // First check if we can render this player
            local doRender = false
            for index, virSquad in pairs(virSquads) do
                if(virSquad.squadID == -1 or virSquad.squadID == entity.squad) then
                    virSquad.squadID = entity.squad
                    virSquadID = index
                    doRender = true
                    break
                end
            end
            
            if(doRender) then
            
                local squadColor = GetColorForSquad(entity.squad)
                
                local entOrigin = entity:GetOrigin()
                local screenPos = Client.WorldToScreen(entOrigin)
                screenPos.x = screenPos.x / Client.GetScreenWidth()
                screenPos.y = screenPos.y / Client.GetScreenHeight()
                
                local ballIndex = virSquads[virSquadID].playerCount
                virSquads[virSquadID].playerCount = virSquads[virSquadID].playerCount + 1
                table.insert(ballInfo, {ballIndex, Color(squadColor[1], squadColor[2], squadColor[3], squadColor[4]), screenPos, entity.squad, virSquadID})
                
            end
            
        end
        
    end
    
    return ballInfo

end

function MarineCommander:UpdateSquadScreenEffects(highlightSquad, selectedSquad)

    if(self.metaballScreenEffect == nil) then
        return
    end
    
    self.metaballScreenEffect:SetParameter("metaBallRadius", self:GetSquadBallRadius())
    self.metaballScreenEffect:SetParameter("minThreshold", self:GetSquadBallMinThreshold())
    self.metaballScreenEffect:SetParameter("maxThreshold", self:GetSquadBallMaxThreshold())
    
    // First assume no balls will be rendered
    local currSquad = 1
    while(currSquad <= self:GetMaxRenderBlobSquads()) do
        local currBallIndex = 0
        while(currBallIndex < self:GetMaxNumSquadBalls()) do
            self.metaballScreenEffect:SetParameter("metaBallRender", 0, currBallIndex, string.format("p%d", currSquad))
            currBallIndex = currBallIndex + 1
        end
        
        self.metaballScreenEffect:SetPassActive(string.format("p%d", currSquad), false)
        currSquad = currSquad + 1
    end
    
    local ballInfo = self:GetSquadBallInfo()
    
    for index, ball in pairs(ballInfo) do
    
        local setColor = Color(ball[2])
        if(selectedSquad == ball[4]) then
            setColor.r = setColor.r * 4
            setColor.g = setColor.g * 4
            setColor.b = setColor.b * 4
        elseif(highlightSquad == ball[4]) then
            setColor.r = setColor.r * 2
            setColor.g = setColor.g * 2
            setColor.b = setColor.b * 2
        end
        self.metaballScreenEffect:SetParameter("metaBallColor", setColor, ball[1], string.format("p%d", ball[5]))
        
        self.metaballScreenEffect:SetParameter("metaBallPos", ball[3], ball[1], string.format("p%d", ball[5]))
        // This ball is being rendered, notify the effect
        self.metaballScreenEffect:SetParameter("metaBallRender", 1, ball[1], string.format("p%d", ball[5]))
        self.metaballScreenEffect:SetPassActive(string.format("p%d", ball[5]), true)
        
    end
 
end

function MarineCommander:GetSquadBlob(atScreenPos)

    local ballInfo = self:GetSquadBallInfo()
    
    atScreenPos.y = atScreenPos.y * (Client.GetScreenHeight() / Client.GetScreenWidth())
	for index, ball in pairs(ballInfo) do
		ball[3] = Vector(ball[3].x, ball[3].y * (Client.GetScreenHeight() / Client.GetScreenWidth()), 0)
	end
	
	local weight = 0
	local radiusSq = self:GetSquadBallRadius() * self:GetSquadBallRadius()
	local foundSquads = {}
	for index, ball in pairs(ballInfo) do
		local tempWeight = radiusSq / ((atScreenPos.x - ball[3].x) * (atScreenPos.x - ball[3].x) + (atScreenPos.y - ball[3].y) * (atScreenPos.y - ball[3].y))
		if(foundSquads[ball[4]] == nil) then
		    foundSquads[ball[4]] = 0
		end
		foundSquads[ball[4]] = foundSquads[ball[4]] + tempWeight
		weight = weight + tempWeight
	end

    local isInside = false
    local foundSquad = -1
    local foundSquadWeight = 0
    if(weight >= self:GetSquadBallMaxThreshold()) then
		isInside = true
		for index, squad in pairs(foundSquads) do
		    if (squad > foundSquadWeight) then
		        foundSquadWeight = squad
		        foundSquad = index
		    end
		end
	end

    return foundSquad

end