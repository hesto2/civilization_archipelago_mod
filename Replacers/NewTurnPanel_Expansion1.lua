--[[
-- Copyright (c) 2017 Firaxis Games
--]]
-- ===========================================================================
-- INCLUDE BASE FILE
-- ===========================================================================
include("NewTurnPanel");

local m_LastShownCountdownTurn:number = -1;

function ShowEraCountdownPanel()
	local eraCountdown = Game.GetEras():GetNextEraCountdown() + 1; -- 0 turns remaining is the last turn, shift by 1 to make sense to non-programmers
	local currentEra = Game.GetEras():GetCurrentEra();
	if (eraCountdown ~= nil and eraCountdown ~= 0 and eraCountdown ~= m_LastShownCountdownTurn and currentEra ~= nil) then
		local currentEraInfo = GameInfo.Eras[currentEra];
    print(currentEra)
    local maxAllowedEra = Game.GetProperty("MaxAllowedEra") or -1
    local canProgress = true
    if maxAllowedEra ~= -1 then
        canProgress = maxAllowedEra >= currentEra + 1
    end
    print("Current era:", currentEra, "Max allowed era:", maxAllowedEra, "Can progress:", canProgress)

		if (currentEraInfo ~= nil) then
			m_LastShownCountdownTurn = eraCountdown;
      local description = Locale.ToUpper(Locale.Lookup("LOC_NEW_TURN_PANEL_NEXT_ERA_COUNTDOWN", eraCountdown, currentEraInfo.Name))
      if not canProgress then
        description = description .. " (PROGRESSIVE ERA REQUIRED!)"
      end
			Controls.Root:SetHide(true);
			Controls.NewTurnLabel:SetText(description);
			Controls.Root:SetHide(false);
			RestartAnimations();
		end
	end
end

function Initialize()
	-- Don't show until player clicks start turn
	if GameConfiguration.IsHotseat() then
		LuaEvents.PlayerChange_Close.Add(ShowEraCountdownPanel);
	else
		Events.LocalPlayerTurnBegin.Add(ShowEraCountdownPanel);
	end
end
Initialize();

ShowEraCountdownPanel()