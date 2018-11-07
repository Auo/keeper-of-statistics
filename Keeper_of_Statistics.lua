local frame = CreateFrame("frame");

local EVENT_INSPECT_ACHIEVEMENT_READY, EVENT_ADDON_LOADED, EVENT_CHAT_MSG_GUILD = "INSPECT_ACHIEVEMENT_READY", "ADDON_LOADED", "CHAT_MSG_GUILD";

--Use this if you're having some sort of issue and you want to debug it
--This will spam a lot
local debugMode = false;

local unitsToCheck = {};
local updating = false;
local total = 0;
local currentUnitChecked = 1;
local runningCheck = false;

function string.startsWith(str, subString)
   return string.sub(str, 1, string.len(subString)) == subString
end

function firstToUpper(str)
   return (str:gsub("^%l", string.upper))
end

Player = {};
function Player:new()
    local self = {};
    
    self.name = "";
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

    local coins = {" c"," s"," g"};
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

local function playerAlreadySaved(name)
    for i = 1, #KOS.Players do
        if (KOS.Players[i].name == name) then
            return true;
        end
    end
    return false;
end

local function getPlayerIndex(name)
    for i = 1, #KOS.Players do
        if (KOS.Players[i].name == name) then
            return i;
        end
    end
    
    return -1;
end



local function createNewPlayerStatistics(unitid)
    if debugMode then
        print("gathering information from player " .. GetUnitName(unitid));
    end
    
    local name = GetUnitName(unitid);
    
    if CheckInteractDistance(unitid, 4) then
        updating = true;
        if debugMode then
            print(GetUnitName(unitid) .. " is in range of indexing and running now!");
        end
                
        if (playerAlreadySaved(name)) then
            table.remove(KOS.Players, getPlayerIndex(name));
        end

        local player = Player:new();
        player.name = name;
        
        for i = 1, #KOS.defaultStatistics do
            local s = PlayerStatistic:new();
            s.name = KOS.defaultStatistics[i][2];
            
            if(KOS.defaultStatistics[i][3]) then
                local temp = GetComparisonStatistic(KOS.defaultStatistics[i][1]);
                s.value = addCoinText(temp);
            else
                s.value = GetComparisonStatistic(KOS.defaultStatistics[i][1]);
            end
            
            table.insert(player.stats, s);
        end
        table.insert(KOS.Players, player);
    else
        if debugMode then
            --out of range for indexing
            print(GetUnitName(unitid) .. " was not in range");
            
        end
    end
    --tell that we are ready for the next unitid
    updating = false;
    --update the current player, move to next unit
    currentUnitChecked = currentUnitChecked + 1;
    --ClearAchievementComparisonUnit();
end

local function OnEvent(self, event, arg1, arg2, ...)
    if event == EVENT_INSPECT_ACHIEVEMENT_READY and runningCheck then
	--debug
        if debugMode then
            print("inside event "  .. EVENT_INSPECT_ACHIEVEMENT_READY);
        end

        createNewPlayerStatistics(unitsToCheck[currentUnitChecked]);
    elseif event == EVENT_ADDON_LOADED then
        if KOS == nil then
            KOS = {};
            KOS.defaultStatistics = {
                { 114, "Falling deaths", false },
                { 321, "Total raid and dungeon deaths", false },
                { 60, "Total deaths", false },
                { 1197, "Total kills", false },
                { 753, "Average gold per day", true },
                { 328, "Total gold acquired", true },
                { 1456, "Fish and other things caught", false },
                { 1501, "Total deaths from other players", false },
                { 1148, "Gold spent on postage", true },
                { 319, "Duels won", false },
                { 1149, "Talent tree respecs", false },
                { 344, "Bandages used", false },
                { 342, "Epic items acquired", false },
                { 594, "Deaths by Hogger", false },
                { 349, "Flight paths taken", false },
                { 353, "Number of times hearthed", false },
                { 98, "Quests completed", false }
            };

            KOS.Players = {};
        end
    elseif event == EVENT_CHAT_MSG_GUILD then
            if string.startsWith(arg1, "!stats") then
                local p = strtrim(string.sub(arg1, strlen("!stats") + 1));
                p = firstToUpper(p);
            
                if #KOS.Players > 0 then
                    local ui = math.random(1, #KOS.Players);
                    local us = math.random(1, #KOS.defaultStatistics);
                    
                    if p ~=nil and strlen(p) > 2 then
                        ui = getPlayerIndex(p);
                    end
                
                    if ui == -1 then
                        SendChatMessage("Sorry no player found with name: " .. p, "GUILD");
                    else
                        SendChatMessage(KOS.Players[ui].name .. " " .. KOS.Players[ui].stats[us].name .." : ".. KOS.Players[ui].stats[us].value, "GUILD");
                    end
                else
                    SendChatMessage("Sorry, no players have been indexed", "GUILD");
                end
            end
    end
end


local function OnUpdate(self, elapsed)
    total = total + elapsed;

    if total > 1.5 then
        if updating == false and #unitsToCheck >= currentUnitChecked then
        
        if debugMode then
            print(unitsToCheck[currentUnitChecked] .. " unitsToCheck[]");
            print(UnitName(unitsToCheck[currentUnitChecked]));
            print(updating);
        end
        
        ClearAchievementComparisonUnit();
            --check range
        if CheckInteractDistance(unitsToCheck[currentUnitChecked], 4) then
            
            --debug
            if debugMode then
                print("inside, setting up for event");
            end

            local success = SetAchievementComparisonUnit(unitsToCheck[currentUnitChecked]);
            
        else
            --debug
            if debugMode then
                print("The player " .. UnitName(unitsToCheck[currentUnitChecked])  .. " was too far away");
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
frame:RegisterEvent(EVENT_CHAT_MSG_GUILD);

--if you want to add more statistics to track, 
-- /script print(GetMouseFocus().id)
-- open statistcs tab, hover over a stat and enter that
-- save the ID and the name in the KOS.defaultStatistics
-- if it contains currency add true else false. 
