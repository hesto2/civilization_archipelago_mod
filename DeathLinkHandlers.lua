local DL_NOTIFICATION_TYPE = NotificationTypes.USER_DEFINED_3
local DL_KILL_NOTIFICATION_TYPE = NotificationTypes.USER_DEFINED_4
local DL_INDEX = 0
local CLIENT_PREFIX = "APSTART:"
local CLIENT_POSTFIX = ":APEND"

-- Used to dedupe notifications in the UI, otherwise they won't stack
function IncrementDeathLinkIndex()
    DL_INDEX = DL_INDEX + 1
    Game.SetProperty("DeathLinkIndex", DL_INDEX)
end

-- CLIENT FUNCTION
-- percent is expected to be an int (7 = 7%)
function DecreaseGoldByPercent(percent, message)
    treasury = Players[0]:GetTreasury()
    current = treasury:GetGoldBalance()
    amount = math.floor(current * percent / 100)
    treasury:SetGoldBalance(current - amount)
    NotificationManager:SendNotification(DL_NOTIFICATION_TYPE, "You lost " .. amount .. " gold from a Death Link",
        message, 0, DL_INDEX)
    IncrementDeathLinkIndex()
end

-- CLIENT FUNCTION
-- percent is expected to be an int (7 = 7%)
function DecreaseFaithByPercent(percent, message)
    religion = Players[0]:GetReligion()
    current = religion:GetFaithBalance()
    amount = math.floor(current * percent / 100)
    religion:SetFaithBalance(current - amount)
    NotificationManager:SendNotification(DL_NOTIFICATION_TYPE, "You lost " .. amount .. " faith from a Death Link",
        message, 0, DL_INDEX)
    IncrementDeathLinkIndex()
end

function DecreaseEraScoreByAmount(amount, message)
    Game.GetEras():ChangePlayerEraScore(Players[0]:GetID(), amount * -1)
    NotificationManager:SendNotification(DL_NOTIFICATION_TYPE, "You lost " .. amount .. " era score from a Death Link",
        message, 0, DL_INDEX)
    IncrementDeathLinkIndex()
end

-- CLIENT FUNCTION
function KillUnit(message)
    pUnits = Players[0]:GetUnits()
    count = pUnits:GetCount()
    if count == 0 then
        return
    end
    for index, pUnit in pUnits:Members() do
        location = pUnit:GetLocation()
        name = Locale.Lookup(pUnit:GetName())
        UnitManager.Kill(pUnit)
        NotificationManager:SendNotification(DL_KILL_NOTIFICATION_TYPE, "Your " .. name .. " was killed by a Death Link",
            message, location.x, location.y)
        return
    end
    NotificationManager:SendNotification(DL_KILL_NOTIFICATION_TYPE, "No unit available for death link to kill!", message, 0,
        0)

end

function OnUnitKilledInCombat(playerID, unitID, killerPlayerID, killerUnitID)
    print("START ON UNIT KILLED")
    if playerID == Players[0]:GetID() then
        -- This is here in case something goes wrong with the lookup
        Game.SetProperty("DeathLink", "Natural Causes")

        if killerPlayerID == -1 or killerUnitID == -1 then
            return
        end
        killerUnit = UnitManager.GetUnit(killerPlayerID, killerUnitID)
        killerUnitName = Locale.Lookup(killerUnit:GetName())

        Game.SetProperty("DeathLink", killerUnitName)
    end
    result = Game.GetProperty("DeathLinkIndex")
    if result ~= nil then
        Game.SetProperty("DeathLinkIndex", result)
    else
        Game.SetProperty("DeathLinkIndex", 0)
    end
end

function Init()
    Events.UnitKilledInCombat.Add(OnUnitKilledInCombat)
    print("Players[0]", Players[0])
end

-- CLIENT FUNCTION
function ClientGetDeathLink()
    deathLink = Game.GetProperty("DeathLink") or "false"
    -- Death link stores a string containing the name of the unit that killed the player's unit
    Game.SetProperty("DeathLink", "false")
    return CLIENT_PREFIX .. deathLink .. CLIENT_POSTFIX
end

function Init()
    Events.UnitKilledInCombat.Add(OnUnitKilledInCombat)
    print("Players[0]", Players[0])
end

Init()

-- Functions to expose to the client
Game.KillUnit = KillUnit

Init()

-- Functions to expose to the client
Game.ClientGetDeathLink = ClientGetDeathLink
Game.KillUnit = KillUnit
Game.DecreaseGoldByPercent = DecreaseGoldByPercent
Game.DecreaseFaithByPercent = DecreaseFaithByPercent
Game.DecreaseEraScoreByAmount = DecreaseEraScoreByAmount

