local frame = CreateFrame("frame");

--Use this if you're having some sort of issue and you want to debug it
--This will spam a lot
local debugMode = false;

local function getAllStatistics() 
    local function contains(tab, val) 
       for index, value in ipairs(tab) do
          if value == val then
             return true
          end
       end
       
       return false
    end
    
    local unAllowedCategories = {
        "Dungeons & Raids",
        "Classic",
        "The Burning Crusade",
        "Wrath of the Lich King",
        "Cataclysm",
        "Mists of Pandaria",
        "Warlords of Draenor",
        "Legion",
        "Battle for Azeroth",
        "Player vs. Player",
        "Rated Arenas",
        "Battlegrounds",
        "World",
        "Proving Grounds",
        "Class Hall"
    };
    
    local data = {};
    for _, CategoryId in pairs(GetStatisticsCategoryList()) do
       local Title, ParentCategoryId = GetCategoryInfo(CategoryId)
       
       if contains(unAllowedCategories, Title) == false then
          for i = 1, GetCategoryNumAchievements(CategoryId) do
             local IDNumber, Name, Points, Completed, Month, Day, Year, Description, Flags, Image, RewardText
             IDNumber, Name, Points, Completed, Month, Day, Year, Description, Flags, Image, RewardText = GetAchievementInfo(CategoryId, i)
             
             if Name ~= nil then
                local isGold = false;
                
                if string.match(Name, "gold") or string.match(Name, "Gold") then
                    isGold = true;
                end
                
                table.insert(data, { IDNumber, Name, isGold });
            end
          end
       end
    end

    if debugMode then
        print("number of saved statistics: " .. #data);
     end

    return data;
 end

local function initStore() 
    if debugMode then
        print("initializing store");
    end

    if KOS == nil then
        KOS = {};        
    end

    if KOS.Players == nil then
        KOS.Players = {};
    end

    if KOS.defaultStatistics == nil then
        KOS.defaultStatistics = getAllStatistics();
    end
end

local EVENT_INSPECT_ACHIEVEMENT_READY, EVENT_ADDON_LOADED, EVENT_CHAT_MSG, OUTPUT_CHAT_CHANNEL = "INSPECT_ACHIEVEMENT_READY", "ADDON_LOADED", "CHAT_MSG_GUILD", "GUILD";




local unitsToCheck = {};
local updating = false;
local total = 0;
local currentUnitChecked = 1;
local runningCheck = false;

function string.startsWith(str, subString)
   return string.sub(str, 1, string.len(subString)) == subString
end

function string.firstToUpper(str)
   return str:gsub("^%l", string.upper)
end

Player = {};
function Player:new(name)
    local self = {};
    
    self.name = name;
    self.stats = {};
    return self;
end

PlayerStatistic = {};
function PlayerStatistic:new()
    local self = {};
    
    self.name ="";
    self.value = "";
    return self;
end

local function addCoinText(text)
    text = string.gsub(text, "(%b||)(t)", "")

    local coins = { " c", " s", " g" };
    local s = strrev(text);
    
    local output = " ";
    local c = 1;
    
    for i = 1, #s do
        local char = s:sub(i, i);
        if char == " " or i == 1 then
            output = output .. coins[c];
            c = c + 1;
        else
            output = output .. char;
        end
    end
        
    return strrev(output);
end

local function getPlayerIndex(name, exact)
    for i = 1, #KOS.Players do
        if exact then
            if (KOS.Players[i].name:lower() == name:lower()) then
                return i;
            end
        else
            if (string.startsWith(KOS.Players[i].name:lower(), name:lower() .. "-")) then
                return i;
            end
        end
    end
    
    return -1;
end
-- used to create debug data
local function createFakePlayerStatistics(name)
    local ix = getPlayerIndex(name, true);
    if (ix ~= -1) then
        table.remove(KOS.Players, ix);
    end
    local player = Player:new(name);
    local s = PlayerStatistic:new();
    s.name = KOS.defaultStatistics[1][2];
    s.value = "FAKE_DATA";
    
    table.insert(player.stats, s);
    table.insert(KOS.Players, player);
end

if debugMode then 
    EVENT_CHAT_MSG = "CHAT_MSG_SAY";
    OUTPUT_CHAT_CHANNEL = "SAY";
    initStore();

    -- uncomment these lines if you want to populate debug data, obviously bogus
    --createFakePlayerStatistics("Player-Server");
    --createFakePlayerStatistics("Anotherplayer");
    --createFakePlayerStatistics("Anotherplayer-Server");
end

local function createNewPlayerStatistics(unitId)
    -- name - realm or name
    local name = GetUnitName(unitId, true);

    if debugMode then
        print("gathering information from player " .. name);
    end

    if CheckInteractDistance(unitId, 4) then
        updating = true;
        if debugMode then
            print(name .. " is in range of indexing and running now!");
        end
    
        local ix = getPlayerIndex(name, true);
        if (ix ~= -1) then
            table.remove(KOS.Players, ix);
        end

        local player = Player:new(name);
        
        for i = 1, #KOS.defaultStatistics do
            local s = PlayerStatistic:new();
            s.name = KOS.defaultStatistics[i][2];

            local statistics = GetComparisonStatistic(KOS.defaultStatistics[i][1]);

            if (KOS.defaultStatistics[i][3]) then    
                s.value = addCoinText(statistics);
            else
                s.value = statistics;
            end
            
            table.insert(player.stats, s);
        end
        table.insert(KOS.Players, player);
    else
        if debugMode then
            --out of range for indexing
            print(name .. " was not in range");
        end
    end
    --tell that we are ready for the next unitId
    updating = false;
    --update the current player, move to next unit
    currentUnitChecked = currentUnitChecked + 1;
end

local function OnEvent(self, event, arg1, arg2, ...)
    if event == EVENT_INSPECT_ACHIEVEMENT_READY and runningCheck then
	    --debug
        if debugMode then
            print("inside event "  .. EVENT_INSPECT_ACHIEVEMENT_READY);
        end

        createNewPlayerStatistics(unitsToCheck[currentUnitChecked]);
    elseif event == EVENT_ADDON_LOADED then
        initStore();

        

    elseif event == EVENT_CHAT_MSG then
        local stats = "!stats";
        if string.startsWith(arg1, stats) then
            local p = strtrim(string.sub(arg1, strlen(stats) + 1));
            p = string.firstToUpper(p);
            if debugMode then
                print("looking for player: " .. p);
            end

            if #KOS.Players > 0 then
                local ui = -1; 

                if p ~=nil and strlen(p) > 2 then
                    ui = getPlayerIndex(p, true);

                    if ui == -1 then
                        ui = getPlayerIndex(p, false)
                    end
                else
                    ui = math.random(1, #KOS.Players);
                end
            
                if ui == -1 then
                    SendChatMessage("Sorry no player found with name: " .. p, OUTPUT_CHAT_CHANNEL);
                else
                    local us = math.random(1, #KOS.Players[ui].stats);
                    SendChatMessage(KOS.Players[ui].name .. " " .. KOS.Players[ui].stats[us].name .. " : " .. KOS.Players[ui].stats[us].value, OUTPUT_CHAT_CHANNEL);
                end
            else
                SendChatMessage("Sorry, no players have been indexed", OUTPUT_CHAT_CHANNEL);
            end
        end
    end
end

local function OnUpdate(self, elapsed)
    total = total + elapsed;

    if total > 1.5 then
        if updating == false and #unitsToCheck >= currentUnitChecked then
        
            local unit = unitsToCheck[currentUnitChecked];
            local name, realm = UnitName(unit);
            if debugMode then
                print("units to check: " .. unit);
                print(name);
                print(updating);
            end
            
            ClearAchievementComparisonUnit();
            --check range
            if CheckInteractDistance(unit, 4) then
                
                --debug
                if debugMode then
                    print("inside, setting up for event");
                end

                local success = SetAchievementComparisonUnit(unit);
                
            else
                --debug
                if debugMode then
                    print("The player " .. name  .. "-" .. realm .." was too far away");
                end

                currentUnitChecked = currentUnitChecked + 1;
                end
            end
        
            if #unitsToCheck < currentUnitChecked and updating == false then
                frame:SetScript("OnUpdate", nil);
                if AchievementFrameComparison ~= nil then
                    AchievementFrameComparison:RegisterEvent(EVENT_INSPECT_ACHIEVEMENT_READY);
                end
                
                runningCheck = false;
                unitsToCheck = {};
                currentUnitChecked = 1;
                print("indexing done for your group/raid");
            end
            total = 0;
    end
end

local function initCheck()
    --debug
    if debugMode then
        print("starting OnUpdate");
    end
    
    if AchievementFrameComparison ~= nil then
        AchievementFrameComparison:UnregisterEvent(EVENT_INSPECT_ACHIEVEMENT_READY);
    end
        
    runningCheck = true;
    frame:SetScript("OnUpdate", OnUpdate);
end

SLASH_SENDER1 = '/KOS'
function SlashCmdList.SENDER(msg, editbox) 
    unitsToCheck = {};
    
    if msg == "clear" then
        print("All players have been un-indexed, have a nice day!");
        KOS.Players = {};
    else 
        print("starting to index players!");
        
        if IsInGroup() and not IsInRaid() then
           local members = GetNumGroupMembers();
           table.insert(unitsToCheck, "player");
           
           for i = 1, members do
              if UnitIsConnected("party" .. i) then
                 table.insert(unitsToCheck, "party" .. i);
                 --queue up the work.
              end
           end
           initCheck();
           
        elseif IsInRaid() then
           local members = GetNumGroupMembers();
               
           --player is in raid, doesn't need to be added
           for i = 1, members do
              if UnitIsConnected("raid" .. i) then
                 table.insert(unitsToCheck, "raid" .. i);
                 --queue up the work.
              end
           end
           initCheck();
        elseif debugMode and not IsInGroup() and not IsInRaid() then
            table.insert(unitsToCheck, "player");
            initCheck();
        else
           print("sorry, you need to be in a party or raid.");
        end
    end
end

frame:SetScript("OnEvent", OnEvent);
frame:RegisterEvent(EVENT_INSPECT_ACHIEVEMENT_READY);
frame:RegisterEvent(EVENT_ADDON_LOADED);
frame:RegisterEvent(EVENT_CHAT_MSG);
