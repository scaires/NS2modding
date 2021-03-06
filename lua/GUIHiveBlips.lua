
// ======= Copyright � 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIHiveBlips.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages the blips that are displayed on the Alien HUD due to hive sight.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIHiveBlips' (GUIScript)

GUIHiveBlips.kBlipImageName = "ui/hivesight.dds"

GUIHiveBlips.kBlipTextureTypeYOffset = { }
GUIHiveBlips.kBlipTextureTypeYOffset[kBlipType.Friendly] = 0
GUIHiveBlips.kBlipTextureTypeYOffset[kBlipType.FriendlyUnderAttack] = 1
GUIHiveBlips.kBlipTextureTypeYOffset[kBlipType.TechPointStructure] = 2
GUIHiveBlips.kBlipTextureTypeYOffset[kBlipType.Sighted] = 3
GUIHiveBlips.kBlipTextureTypeYOffset[kBlipType.Undefined] = 4

GUIHiveBlips.kNumberFramesForBlipType = { }
GUIHiveBlips.kNumberFramesForBlipType[kBlipType.Friendly] = 10
GUIHiveBlips.kNumberFramesForBlipType[kBlipType.FriendlyUnderAttack] = 7
GUIHiveBlips.kNumberFramesForBlipType[kBlipType.TechPointStructure] = 10
GUIHiveBlips.kNumberFramesForBlipType[kBlipType.Sighted] = 11
GUIHiveBlips.kNumberFramesForBlipType[kBlipType.Undefined] = 10

GUIHiveBlips.kBlipTextureSize = 64
GUIHiveBlips.kDefaultBlipSize = 25
GUIHiveBlips.kMaxBlipSize = 200

GUIHiveBlips.kBlipObstructedColor = Color(1, 1, 1, .75)
GUIHiveBlips.kBlipVisibleColor = Color(1, 1, 1, 0)

// How fast the animations are for the blips.
GUIHiveBlips.kFrameChangeRate = 0.1

function GUIHiveBlips:Initialize()

    self.activeBlipList = { }
    self.reuseBlips = { }
    self.frameTime = GUIHiveBlips.kFrameChangeRate
    self.currentFrame = 0
    
end

function GUIHiveBlips:Uninitialize()

    for i, blip in ipairs(self.activeBlipList) do
        GUI.DestroyItem(blip.GraphicsItem)
    end
    self.activeBlipList = { }
    
    for i, blip in ipairs(self.reuseBlips) do
        GUI.DestroyItem(blip.GraphicsItem)
    end
    self.reuseBlips = { }
    
end

function GUIHiveBlips:Update(deltaTime)

    self:UpdateBlipList(PlayerUI_GetBlipInfo())
    
    self:UpdateAnimations(deltaTime)
    
end

function GUIHiveBlips:UpdateAnimations(deltaTime)

    // Check if it is time to switch frames.
    self.frameTime = self.frameTime - deltaTime
    if self.frameTime < 0 then
        self.frameTime = GUIHiveBlips.kFrameChangeRate
        self.currentFrame = self.currentFrame + 1
    end

    // Update all the blip animations.
    for i, blip in ipairs(self.activeBlipList) do
        local size = math.min(blip.Radius * 2 * GUIHiveBlips.kDefaultBlipSize, GUIHiveBlips.kMaxBlipSize)
        blip.GraphicsItem:SetSize(Vector(size, size, 0))
        
        // Offset by size / 2 so the blip is centered.
        local newPosition = Vector(blip.ScreenX - size / 2, blip.ScreenY - size / 2, 0)
        blip.GraphicsItem:SetPosition(newPosition)
        
        local blipCurrentFrame = self.currentFrame % GUIHiveBlips.kNumberFramesForBlipType[blip.Type]
        local xOffset = blipCurrentFrame * GUIHiveBlips.kBlipTextureSize
        local yOffset = GUIHiveBlips.kBlipTextureTypeYOffset[blip.Type] * GUIHiveBlips.kBlipTextureSize
        blip.GraphicsItem:SetTexturePixelCoordinates(xOffset, yOffset, xOffset + GUIHiveBlips.kBlipTextureSize, yOffset + GUIHiveBlips.kBlipTextureSize)
        
        // Draw blips as barely visible when in view, to communicate their purpose. Animate color towards final value.
        local currentColor = blip.GraphicsItem:GetColor()
        local destAlpha = ConditionalValue(blip.Obstructed, GUIHiveBlips.kBlipObstructedColor.a, GUIHiveBlips.kBlipVisibleColor.a)
        local newAlpha = Slerp(currentColor.a, destAlpha, deltaTime * 2)
        currentColor.a = newAlpha
        blip.GraphicsItem:SetColor(currentColor)
    end
    
end

function GUIHiveBlips:UpdateBlipList(activeBlips)
    
    local numElementsPerBlip = 5
    local numBlips = table.count(activeBlips) / numElementsPerBlip
    
    while numBlips > table.count(self.activeBlipList) do
        local newBlipItem = self:CreateBlipItem()
        table.insert(self.activeBlipList, newBlipItem)
        newBlipItem.GraphicsItem:SetIsVisible(true)
    end
    
    while numBlips < table.count(self.activeBlipList) do
        self.activeBlipList[1].GraphicsItem:SetIsVisible(false)
        table.insert(self.reuseBlips, self.activeBlipList[1])
        table.remove(self.activeBlipList, 1)
    end
    
    // Update current blip state.
    local currentIndex = 1
    while numBlips > 0 do
        local updateBlip = self.activeBlipList[numBlips]
        updateBlip.ScreenX = activeBlips[currentIndex]
        updateBlip.ScreenY = activeBlips[currentIndex + 1]
        updateBlip.Radius = activeBlips[currentIndex + 2]
        updateBlip.Type = activeBlips[currentIndex + 3]
        updateBlip.Obstructed = activeBlips[currentIndex + 4]
        numBlips = numBlips - 1
        currentIndex = currentIndex + numElementsPerBlip
    end

end

function GUIHiveBlips:CreateBlipItem()
    
    // Reuse an existing player item if there is one.
    if table.count(self.reuseBlips) > 0 then
        local returnBlip = self.reuseBlips[1]
        table.remove(self.reuseBlips, 1)
        returnBlip.GraphicsItem:SetIsVisible(true)
        return returnBlip
    end

    local newBlip = { ScreenX = 0, ScreenY = 0, Radius = 0, Type = 0 }
    newBlip.GraphicsItem = GUI.CreateGraphicsItem()
    newBlip.GraphicsItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    newBlip.GraphicsItem:SetTexture(GUIHiveBlips.kBlipImageName)
    newBlip.GraphicsItem:SetColor(GUIHiveBlips.kBlipVisibleColor)
    newBlip.GraphicsItem:SetBlendTechnique(GUIItem.Add)
    return newBlip
    
end