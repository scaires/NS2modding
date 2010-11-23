class 'GUIRifleDisplay'

// Global state that can be externally set to adjust the display.
weaponClip     = 0
weaponAmmo     = 0
weaponAuxClip  = 0
weaponClipSize = 50

display         = nil

function GUIRifleDisplay:Initialize()

    self.background = GUI.CreateGraphicsItem()
    self.background:SetSize( Vector(256, 512, 0) )
    self.background:SetPosition( Vector(0, 0, 0))    
    self.background:SetTexture("ui/RifleDisplay.dds")

    // Slightly larger copy of the text for a glow effect
    self.ammoTextBg = GUI.CreateTextItem()
    self.ammoTextBg:SetFontName("MicrogrammaDMedExt")
    self.ammoTextBg:SetFontIsBold(true)
    self.ammoTextBg:SetFontSize(135)
    self.ammoTextBg:SetTextAlignmentX(GUITextItem.Align_Center)
    self.ammoTextBg:SetTextAlignmentY(GUITextItem.Align_Center)
    self.ammoTextBg:SetPosition(Vector(135, 88, 0))
    self.ammoTextBg:SetColor(Color(1, 1, 1, 0.25))

    // Text displaying the amount of ammo in the clip
    self.ammoText = GUI.CreateTextItem()
    self.ammoText:SetFontName("MicrogrammaDMedExt")
    self.ammoText:SetFontIsBold(true)
    self.ammoText:SetFontSize(120)
    self.ammoText:SetTextAlignmentX(GUITextItem.Align_Center)
    self.ammoText:SetTextAlignmentY(GUITextItem.Align_Center)
    self.ammoText:SetPosition(Vector(135, 88, 0))
    
    // Create the indicators for the number of bullets in reserve.

    self.clipTop    = 400 - 256
    self.clipHeight = 69
    self.clipWidth  = 21
    
    self.numClips   = 4
    self.clip = { }
    
    for i =1,self.numClips do
        self.clip[i] = GUI.CreateGraphicsItem()
        self.clip[i]:SetTexture("ui/RifleDisplay.dds")
        self.clip[i]:SetSize( Vector(21, self.clipHeight, 0) )
        self.clip[i]:SetBlendTechnique( GUIItem.Add )
    end
    
    self.clip[1]:SetPosition(Vector( 74, self.clipTop, 0))
    self.clip[2]:SetPosition(Vector( 112, self.clipTop, 0))
    self.clip[3]:SetPosition(Vector( 145, self.clipTop, 0))
    self.clip[4]:SetPosition(Vector( 178, self.clipTop, 0))
    
    // Create the grenade indicators.
        
    self.maxGrenades = 6
    self.grenade = { }
   
    for i =1,self.maxGrenades do
        self.grenade[i] = GUI.CreateGraphicsItem()
        self.grenade[i]:SetTexture("ui/RifleDisplay.dds")
        self.grenade[i]:SetSize( Vector(58, 20, 0) )
        self.grenade[i]:SetPosition( Vector( 6, 267 + 24 * (i - 1), 0 ) )
        self.grenade[i]:SetTexturePixelCoordinates( 77, 266, 135, 286 )
    end
 
    // Force an update so our initial state is correct.
    self:Update(0)

end

function GUIRifleDisplay:Update(deltaTime)
    
    // Update the ammo counter.
    
    local ammoFormat = string.format("%02d", weaponClip) 
    self.ammoText:SetText( ammoFormat )
    self.ammoTextBg:SetText( ammoFormat )
    
    // Update the reserve clip.
    
    local reserveMax      = self.numClips * weaponClipSize
    local reserve         = weaponAmmo
    local reserveFraction = (reserve / reserveMax) * self.numClips

    for i=1,self.numClips do
        self:SetClipFraction( i, Math.Clamp(reserveFraction - i + 1, 0, 1) )
    end

end

function GUIRifleDisplay:SetClipFraction(clipIndex, fraction)

    local offset   = (1 - fraction) * self.clipHeight
    local position = Vector( self.clip[clipIndex]:GetPosition().x, self.clipTop + offset, 0 )
    local size     = self.clip[clipIndex]:GetSize()
    
    self.clip[clipIndex]:SetPosition( position )
    self.clip[clipIndex]:SetSize( Vector( size.x, fraction * self.clipHeight, 0 ) )
    self.clip[clipIndex]:SetTexturePixelCoordinates( position.x, position.y + 256, position.x + self.clipWidth, self.clipTop + self.clipHeight + 256 )

    for i=1,self.maxGrenades do
        // We subtract one from the aux weapon clip, because one grenade is
        // in the chamber.
        self.grenade[i]:SetIsVisible( weaponAuxClip - 1 >= self.maxGrenades - i + 1 )
    end

end

/**
 * Called by the player to update the components.
 */
function Update(deltaTime)
    display:Update(deltaTime)
end

/**
 * Initializes the player components.
 */
function Initialize()

    GUI.SetSize( 256, 417 )

    display = GUIRifleDisplay()
    display:Initialize()

end

Initialize()