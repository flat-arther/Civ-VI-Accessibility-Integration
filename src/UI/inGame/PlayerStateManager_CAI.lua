--- PlayerStateManager_CAI.lua
--- Shared per player state manager used by various CAI systems. Saves a given state and allows for retrieving the active player's data, indexing the local table based on Game.GetLocalPlayer. necessary for hotseet games to keep track of cursor, buffer, reveal and scanner states for different players

PlayerStateManager = PlayerStateManager or {}

function PlayerStateManager.Init(createDefaultState, onCreate)
    local manager = {
        _states = {},
        _createDefaultState = createDefaultState,
        _onCreate = onCreate,
    }

    function manager:GetActivePlayerID()
        return Game.GetLocalPlayer()
    end

    function manager:Get(playerID)
        if playerID == nil or playerID < 0 then
            return nil
        end

        local state = self._states[playerID]
        if state == nil then
            state = self._createDefaultState(playerID)
            self._states[playerID] = state

            if self._onCreate ~= nil then
                self._onCreate(playerID, state)
            end
        end

        return state
    end

    function manager:GetActive()
        return self:Get(self:GetActivePlayerID())
    end

    function manager:Peek(playerID)
        return self._states[playerID]
    end

    function manager:Has(playerID)
        return self._states[playerID] ~= nil
    end

    function manager:Clear(playerID)
        self._states[playerID] = nil
    end

    function manager:Reset(playerID)
        self._states[playerID] = self._createDefaultState(playerID)
        return self._states[playerID]
    end

    function manager:ClearAll()
        self._states = {}
    end

    function manager:ForEach(fn)
        for playerID, state in pairs(self._states) do
            fn(playerID, state)
        end
    end

    return manager
end
