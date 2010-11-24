// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\DeathMessage_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kSubImageWidth = 128
local kSubImageHeight = 64

local queuedDeathMessages = {}

// Can't have multi-dimensional arrays so return potentially very long array [color, name, color, name, doerid, ....]
function DeathMsgUI_GetMessages()

    local returnArray = {}
    local arrayIndex = 1
    
    // return list of recent death messages
    for index, deathMsg in ipairs(queuedDeathMessages) do
    
        for deathMessageIndex, element in ipairs(deathMsg) do
            table.insert(returnArray, element)
        end
        
    end
    
    // Clear current death messages
    table.clear(queuedDeathMessages)
    
    return returnArray
    
end

function DeathMsgUI_MenuImage()
    return "death_messages"
end

function DeathMsgUI_GetTechOffsetX(doerId)
    return 0
end

function DeathMsgUI_GetTechOffsetY(iconIndex)

    if not iconIndex then
        iconIndex = 1
    end
    
    return (iconIndex - 1)*kSubImageHeight
    
end

function DeathMsgUI_GetTechWidth(doerId)
    return kSubImageWidth
end

function DeathMsgUI_GetTechHeight(doerId)
    return kSubImageHeight
end

function InitDeathMessages(player)

    Client.BindFlashTexture("death_messages", "ui/messages_icons.dds")
    queuedDeathMessages = {}
    
end

// Pass 1 for isPlayer if coming from a player (look it up from scoreboard data), otherwise it's a tech id
function GetDeathMessageEntityName(isPlayer, entityId)

    local name = ""

    if isPlayer == 1 then
        // Convert the entity Id to a client Id for the player.
        local playerEntity = Shared.GetEntity(entityId)
        if playerEntity then
            local convertedClientIndex = playerEntity:GetClientIndex()
            name = Scoreboard_GetPlayerData(convertedClientIndex, kScoreboardDataIndexName)
        end
    else
        name = LookupTechData(entityId, kTechDataDisplayName)
    end
    
    if not name then
        name = ""
    end
    
    return name
    
end

function AddDeathMessage(killerIsPlayer, killerId, killerTeamNumber, iconIndex, targetIsPlayer, targetId, targetTeamNumber)

    local killerName = GetDeathMessageEntityName(killerIsPlayer, killerId)
    local targetName = GetDeathMessageEntityName(targetIsPlayer, targetId)
    
    // Just display attacker and icon when we kill ourselves
    if killerName == targetName then
        targetName = ""
    end
    
    local deathMessage = {GetColorForTeamNumber(killerTeamNumber), killerName, GetColorForTeamNumber(targetTeamNumber), targetName, iconIndex}
    
    table.insertunique(queuedDeathMessages, deathMessage)
    
end