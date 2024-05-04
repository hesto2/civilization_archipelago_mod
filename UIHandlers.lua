function OnToggleTech(_, params)
    -- Responds to player clicking unlocked items in the UI to disable them, useful for building obsolete units, id is sent in as index so we don't need to modify it
    print("START ToggleTech")
    local id = params.id

    local gameProperty = "ToggledTechs_" .. id

    local hasTech = Players[0]:GetTechs():HasTech(id)
    local toggledState = Game.GetProperty(gameProperty) or false
    local isValid = false

    print("Current disabled state:", toggledState)
    print("Has Tech", hasTech)
    if hasTech then
        Players[0]:GetTechs():SetTech(id, false)
        toggledState = true
        isValid = true
    else
        if toggledState == true then
            Players[0]:GetTechs():SetTech(id, true)
            Players[0]:GetTechs():SetResearchProgress(id, 999999)
            toggledState = false
            isValid = true
        end
    end
    print("New disabled state:", toggledState)
    -- Don't change anything for techs that we haven't unlocked yet
    if isValid then
        Game.SetProperty(gameProperty, toggledState)
        ExposedMembers.AP.OnPostToggleTech(id, toggledState)
    end

    print("END ToggleTech")
end

-- Functions to expose to the UI
GameEvents.OnToggleTech.Add(OnToggleTech);