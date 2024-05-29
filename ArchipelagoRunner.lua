-- This file needs to be loaded before the other archipelago custom scripts
TECHS = {}
TECH_BLOCKER_ID = -1

CIVICS = {}
CIVIC_BLOCKER_ID = -1
HUMAN_PLAYER = nil

KEY_PLAYER = "PLAYER"
KEY_CITY = "CITY"
GOODY_HUT_MODIFIER_MAP = {
    ["GOODY_GOLD_SMALL_MODIFIER"] = KEY_PLAYER,
    ["GOODY_GOLD_MEDIUM_MODIFIER"] = KEY_PLAYER,
    ["GOODY_GOLD_LARGE_MODIFIER"] = KEY_PLAYER,

    ["GOODY_FAITH_SMALL_MODIFIER"] = KEY_PLAYER,
    ["GOODY_FAITH_MEDIUM_MODIFIER"] = KEY_PLAYER,
    ["GOODY_FAITH_LARGE_MODIFIER"] = KEY_PLAYER,

    ["GOODY_DIPLOMACY_GRANT_FAVOR"] = KEY_PLAYER,
    ["GOODY_DIPLOMACY_GRANT_GOVERNOR_TITLE"] = KEY_PLAYER,
    ["GOODY_DIPLOMACY_GRANT_ENVOY"] = KEY_PLAYER,

    ["GOODY_CULTURE_GRANT_ONE_RELIC"] = KEY_PLAYER,

    ["GOODY_MILITARY_GRANT_SCOUT"] = KEY_CITY,

    ["GOODY_SURVIVORS_ADD_POPULATION"] = KEY_CITY,
    ["GOODY_SURVIVORS_GRANT_BUILDER"] = KEY_CITY,
    ["GOODY_SURVIVORS_GRANT_TRADER"] = KEY_CITY,
    ["GOODY_SURVIVORS_GRANT_SETTLER"] = KEY_CITY

}

-- Messages read by the client will be started/ended with these
local CLIENT_PREFIX = "APSTART:"
local CLIENT_POSTFIX = ":APEND"

-- Sets to true once a turn begins, this is to let the client know that the game can be interacted with now

function OnTurnBegin()
    unsent_goodies = GetUnsentGoodies()
    if #unsent_goodies > 0 then
        print("Handling unsent goodies")
        for key, id in pairs(unsent_goodies) do
            city = HUMAN_PLAYER:GetCities():GetCapitalCity()
            if city then
                print("Attaching modifier to city", id)
                city:AttachModifierByID(id)
            end
        end
    end
    Game.SetProperty("UnsentGoodies", {})

end

function NotifyReceivedItem(item, index)
    NotificationManager:SendNotification(NotificationTypes.USER_DEFINED_2, item.Name .. " Received",
        "You have received " .. item.Name .. (item.Sender and " from " .. item.Sender or ""), 0, index) -- 0/index are techincally x/y coords, but if they aren't unique then it won't stack the notifications
end

function GetCheckedLocations()
    locations = {}
    for key, value in pairs(TECHS) do
        id = key - 1
        if id >= TECH_BLOCKER_ID and HUMAN_PLAYER:GetTechs():HasTech(id) then
            table.insert(locations, 1, value.TechnologyType)
        end
    end
    for key, value in pairs(CIVICS) do
        id = key - 1
        if id >= CIVIC_BLOCKER_ID and HUMAN_PLAYER:GetCulture():HasCivic(id) then
            table.insert(locations, 1, value.CivicType)
        end
    end
    currentEra = Game.GetEras():GetCurrentEra()

    while currentEra > 0 do -- Don't include ERA_ANCIENT
        table.insert(locations, 1, GameInfo.Eras[currentEra].EraType)
        currentEra = currentEra - 1
    end

    i = 0
    while i < (Game.GetProperty("TotalGoodyHuts") or 0) do
        table.insert(locations, 1, "GOODY_HUT_" .. i)
        i = i + 1
    end

    return locations
end

-- CLIENT FUNCTION
function GetUnsentCheckedLocations()
    -- Gets the locations that have not been sent yet and returns them
    locations = {}
    unsent_locations = Game.GetProperty("UnsentCheckedLocations") or {}
    for key, value in pairs(unsent_locations) do
        name = value.TechnologyType or value.CivicType
        table.insert(locations, value)
    end
    Game.SetProperty("UnsentCheckedLocations", {})
    return CLIENT_PREFIX .. table.concat(locations, ",") .. CLIENT_POSTFIX
end

-- CLIENT FUNCTION
function Resync()
    print("START resync")
    Game.SetProperty("UnsentCheckedLocations", GetCheckedLocations())
    print("END resync")
end

-- CLIENT FUNCTION
function IsInGame()
    result = "true"
    -- This function gets unloaded when in the main menu and reloaded in the game
    -- For some reason IsInGame and other GameObject bound functions are still available in the main menu after exiting a game
    if GetLastReceivedIndex == nil then
        result = "false"
    end
    return CLIENT_PREFIX .. result .. CLIENT_POSTFIX
end

function SetLastReceivedIndex(index)
    Game.SetProperty("LastReceivedIndex", index)
end

function GetLastReceivedIndex()
    -- If it isn't a number or nil then return -1
    return tonumber(Game.GetProperty("LastReceivedIndex") or -1) or -1
end

-- CLIENT FUNCTION
function ClientGetLastReceivedIndex()
    local index = GetLastReceivedIndex()
    return CLIENT_PREFIX .. tostring(index) .. CLIENT_POSTFIX
end

function HandleReceiveItem(id, name, type, sender, amount)
    print("START HandleReceiveItem type: " .. type)
    received = false
    notification_id = id
    if type == "TECH" then
        print("Received Tech", id)
        HUMAN_PLAYER:GetTechs():SetResearchProgress(id, 999999)
        received = true

    elseif type == "CIVIC" then
        print("Received Civic", id)
        HUMAN_PLAYER:GetCulture():SetCulturalProgress(id, 999999)
        notification_id = id + 100 -- Tech ids and notification ids are not unique between each other
        received = true
    elseif type == "ERA" then
        print("Received Era", id)
        SetMaxAllowedEra(amount)
        notification_id = id + 200
        received = true
    elseif type == "GOODY" then
        print("Received Goody Hut", id)
        if GOODY_HUT_MODIFIER_MAP[id] == KEY_PLAYER then
            HUMAN_PLAYER:AttachModifierByID(id)
        elseif GOODY_HUT_MODIFIER_MAP[id] == KEY_CITY then
            city = HUMAN_PLAYER:GetCities():GetCapitalCity()
            if city then
                city:AttachModifierByID(id)
            else
                unsent_goodies = GetUnsentGoodies()
                table.insert(unsent_goodies, id)
                Game.SetProperty("UnsentGoodies", unsent_goodies)
            end
        end

        notification_id = 1000 + GetLastReceivedIndex()
        received = true
    end
    if received then
        SetLastReceivedIndex(GetLastReceivedIndex() + 1)
        NotifyReceivedItem({
            Name = name,
            Sender = sender
        }, notification_id)
        NotifyReceivedItem({
            Name = name,
            Sender = sender
        }, notification_id)
    end

    print("END HandleReceiveItem")
end

function OnResearchComplete(playerID, techID)
    print("START OnResearchComplete")
    if playerID == HUMAN_PLAYER:GetID() and techID > TECH_BLOCKER_ID then
        print("Tech Researched", techID)
        tech = TECHS[techID + 1]
        if tech then
            locations = Game.GetProperty("UnsentCheckedLocations") or {}
            table.insert(locations, tech.TechnologyType)
            Game.SetProperty("UnsentCheckedLocations", locations)
        end
    end
    if playerID == HUMAN_PLAYER:GetID() and techID == TECH_BLOCKER_ID then
        print("Unsetting BLOCKER")
        Players[HUMAN_PLAYER:GetID()]:GetTechs():SetTech(TECH_BLOCKER_ID, false)
        Players[HUMAN_PLAYER:GetID()]:GetTechs():SetResearchProgress(TECH_BLOCKER_ID, 0)
        Players[HUMAN_PLAYER:GetID()]:GetTechs():SetResearchingTech(TECH_BLOCKER_ID)
    end
    print("END OnResearchComplete")
end

function GetUnsentGoodies()
    return Game.GetProperty("UnsentGoodies") or {}
end

function OnCivicComplete(playerID, civicID)
    print("START OnCivicComplete")
    if playerID == HUMAN_PLAYER:GetID() and civicID > CIVIC_BLOCKER_ID then
        print("Civic Researched", civicID)
        civic = CIVICS[civicID + 1]
        if civic then
            locations = Game.GetProperty("UnsentCheckedLocations") or {}
            table.insert(locations, civic.CivicType)
            Game.SetProperty("UnsentCheckedLocations", locations)
        end
    end
    if playerID == HUMAN_PLAYER:GetID() and civicID == CIVIC_BLOCKER_ID then
        print("Unsetting BLOCKER")
        Players[HUMAN_PLAYER:GetID()]:GetCulture():SetCivic(CIVIC_BLOCKER_ID, false)
        Players[HUMAN_PLAYER:GetID()]:GetCulture():SetCulturalProgress(CIVIC_BLOCKER_ID, 0)
        Players[HUMAN_PLAYER:GetID()]:GetCulture():SetProgressingCivic(CIVIC_BLOCKER_ID)
    end
    print("END OnCivicComplete")
end

function OnTeamVictory(teamID, victoryType, eventID)
    print("START OnTeamVictory", teamID, victoryType, eventID)
    if HUMAN_PLAYER:GetTeam() == teamID then
        print("Victory!")
        Game.SetProperty("Victory", "true")
    end
    print("END OnTeamVictory")
end

function OnGameEraChanged(previousEraID, newEraID)
    print("START OnGameEraChanged")
    maxAllowedEra = Game.GetProperty("MaxAllowedEra") or -1
    if newEraID > maxAllowedEra and maxAllowedEra ~= -1 then
        print("Max allowed era exceeded")
        ForceDefeat()
    else
        locations = Game.GetProperty("UnsentCheckedLocations") or {}
        era = GameInfo.Eras[newEraID].EraType
        table.insert(locations, era)
        Game.SetProperty("UnsentCheckedLocations", locations)
    end
    print("END OnGameEraChanged")
end

function SetMaxAllowedEra(eraID)
    Game.SetProperty("MaxAllowedEra", eraID)
end

function ClientGetMaxAllowedEra()
    era = Game.GetProperty("MaxAllowedEra") or -1
    return CLIENT_PREFIX .. era .. CLIENT_POSTFIX
end

function ForceDefeat()
    Game.RetirePlayer(HUMAN_PLAYER:GetID())
end

-- CLIENT FUNCTION
function ClientGetVictory()
    victory = Game.GetProperty("Victory") or "false"
    return CLIENT_PREFIX .. victory .. CLIENT_POSTFIX
end

function OnGoodyHutReward(playerID, unitID)
    print("START OnGoodyHutReward")
    if playerID == HUMAN_PLAYER:GetID() then
        print("Goody Hut Reward")
        total = Game.GetProperty("TotalGoodyHuts") or 0
        new_total = total + 1
        locations = Game.GetProperty("UnsentCheckedLocations") or {}
        table.insert(locations, "GOODY_HUT_" .. new_total)
        Game.SetProperty("UnsentCheckedLocations", locations)
        Game.SetProperty("TotalGoodyHuts", new_total)
    end
    print("END OnGoodyHutReward")

end

function OnCivicBoostTriggered(playerID, civicID)
  local boostCheckEnabled = Game.GetProperty("BoostsAsChecks")
  if boostCheckEnabled and playerID == HUMAN_PLAYER:GetID() then
    locations = Game.GetProperty("UnsentCheckedLocations") or {}
    civic = CIVICS[civicID + 1]
    table.insert(locations, civic.CivicType)
    Game.SetProperty("UnsentCheckedLocations", locations)
  end
end

function OnTechBoostTriggered(playerID, techID)
  local boostCheckEnabled = Game.GetProperty("BoostsAsChecks")
  if boostCheckEnabled and playerID == HUMAN_PLAYER:GetID() then
    locations = Game.GetProperty("UnsentCheckedLocations") or {}
    tech = TECHS[techID + 1]
    table.insert(locations, tech.TechnologyType)
    Game.SetProperty("UnsentCheckedLocations", locations)
  end
end

function Init()
    print("Running Main")
    -- Events to listen for
    Events.TurnBegin.Add(OnTurnBegin);
    Events.ResearchCompleted.Add(OnResearchComplete)
    Events.CivicCompleted.Add(OnCivicComplete)
    Events.TeamVictory.Add(OnTeamVictory)
    Events.GameEraChanged.Add(OnGameEraChanged)
    Events.GoodyHutReward.Add(OnGoodyHutReward)
    Events.TechBoostTriggered.Add(OnTechBoostTriggered)
    Events.CivicBoostTriggered.Add(OnCivicBoostTriggered)

    -- Initialize the techs
    TECHS = DB.Query("Select * FROM Technologies")

    for key, value in pairs(TECHS) do
        if value.TechnologyType == "TECH_BLOCKER" then
            TECH_BLOCKER_ID = key - 1 -- DB index starts at 1, ids start at 0
        end
    end
    -- Initialize civics
    CIVICS = DB.Query("Select * FROM Civics")
    for key, value in pairs(CIVICS) do
        if value.CivicType == "CIVIC_BLOCKER" then
            CIVIC_BLOCKER_ID = key - 1 -- DB index starts at 1, ids start at 0
        end
    end

    PLAYERS = Game.GetPlayers()
    -- Init HUMAN_PLAYER and grant AI players the AP techs/civics
    for key, player in pairs(PLAYERS) do
        if player:IsHuman() == false then
            -- AP Civics / Techs start with the blocker id and then are populated after
            print("Granting AP techs/civics for AI Player", key)
            for key, value in pairs(TECHS) do
                id = key - 1
                if id >= TECH_BLOCKER_ID then
                    player:GetTechs():SetTech(id, true)
                end
            end

            for key, value in pairs(CIVICS) do
                id = key - 1
                if id >= CIVIC_BLOCKER_ID then
                    player:GetCulture():SetCivic(id, true)
                end
            end
        else
            HUMAN_PLAYER = player
            if player:GetCulture():GetProgressingCivic() == 0 then
                print("Setting human player to first AP civic")
                player:GetCulture():SetProgressingCivic(CIVIC_BLOCKER_ID + 1) -- Game starts player researching code of laws, switch it to the first AP civic
            end
        end
    end

    print("Main Completed")
end

-- Init the script
Init()

-- Functions to expose to the client
Game.HandleReceiveItem = HandleReceiveItem
Game.GetUnsentCheckedLocations = GetUnsentCheckedLocations
Game.IsInGame = IsInGame
Game.ClientGetLastReceivedIndex = ClientGetLastReceivedIndex
Game.Resync = Resync
Game.ClientGetVictory = ClientGetVictory
Game.SetMaxAllowedEra = SetMaxAllowedEra
Game.ClientGetMaxAllowedEra = ClientGetMaxAllowedEra

