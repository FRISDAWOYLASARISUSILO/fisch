-- Fisch Crate Name Tester
-- Test nama-nama crates yang valid

local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🧪 FISCH CRATE NAME TESTER")
print("=" * 40)

-- Possible crate names from different sources
local possibleCrateNames = {
    -- From dump.txt analysis
    "Moosewood",
    "Desolate", 
    "Cthulu",
    "Ancient",
    "Mariana's",
    "Cosmetic Case",
    "Cosmetic Case Legendary", 
    "Atlantis",
    "Cursed",
    "Cultist", 
    "Coral",
    "Friendly",
    "Red Marlins",
    "Midas' Mates",
    "Ghosts",
    
    -- Alternative spellings
    "Marianas",
    "Mariana",
    "Cthulhu",
    "Desolate Deep",
    "Ancient Depths",
    "Cosmetic_Case",
    "Cosmetic_Case_Legendary",
    "RedMarlins",
    "Red_Marlins",
    "Midas_Mates",
    "MidasMates",
    
    -- Shortened versions
    "Moose",
    "Deso",
    "Cth",
    "Anc",
    "Mari",
    "Cosm",
    "Atl",
    "Curs",
    "Cult",
    "Cor",
    "Friend",
    "Red",
    "Midas",
    "Ghost"
}

-- Find the working remote first
local workingRemote = nil

local function findWorkingRemote()
    local success = pcall(function()
        local net = ReplicatedStorage.packages.Net
        
        -- Search for purchase remote
        local function searchRecursively(obj, path)
            for _, child in pairs(obj:GetChildren()) do
                if child.ClassName == "RemoteFunction" and 
                   (child.Name == "Purchase" or string.find(child.Name:lower(), "purchase")) then
                    -- Test if it works with Moosewood
                    local testSuccess = pcall(function()
                        child:InvokeServer("Moosewood")
                    end)
                    if testSuccess then
                        workingRemote = child
                        print("✅ Found working remote: " .. path .. "." .. child.Name)
                        return true
                    end
                end
                
                if child.ClassName == "Folder" then
                    if searchRecursively(child, path .. "." .. child.Name) then
                        return true
                    end
                end
            end
            return false
        end
        
        searchRecursively(net, "ReplicatedStorage.packages.Net")
    end)
    
    return workingRemote ~= nil
end

-- Test crate names
local function testCrateNames()
    if not workingRemote then
        print("❌ No working remote found")
        return
    end
    
    print("\n🎯 TESTING CRATE NAMES:")
    print("-" * 30)
    
    local validCrates = {}
    local invalidCrates = {}
    
    for _, crateName in ipairs(possibleCrateNames) do
        local success, response = pcall(function()
            return workingRemote:InvokeServer(crateName)
        end)
        
        if success then
            if response ~= nil then
                table.insert(validCrates, crateName)
                print("✅ VALID: " .. crateName .. " (Response: " .. tostring(response) .. ")")
            else
                -- nil response might mean insufficient funds, but valid name
                table.insert(validCrates, crateName)  
                print("⚠️ VALID (nil): " .. crateName .. " (Likely insufficient funds)")
            end
        else
            table.insert(invalidCrates, crateName)
            print("❌ INVALID: " .. crateName .. " (Error: " .. tostring(response) .. ")")
        end
        
        wait(0.1) -- Small delay to avoid rate limiting
    end
    
    print("\n📊 RESULTS SUMMARY:")
    print("Valid crates (" .. #validCrates .. "):")
    for _, name in ipairs(validCrates) do
        print("  ✅ " .. name)
    end
    
    print("\nInvalid crates (" .. #invalidCrates .. "):")
    for _, name in ipairs(invalidCrates) do
        print("  ❌ " .. name)
    end
    
    -- Save valid crates globally
    _G.ValidCrateNames = validCrates
    print("\n💾 Valid crate names saved to _G.ValidCrateNames")
    
    return validCrates
end

-- Alternative: Try to get crate names from game data
local function tryGetCrateNamesFromGame()
    print("\n🔍 TRYING TO GET CRATE NAMES FROM GAME DATA:")
    print("-" * 40)
    
    local success = pcall(function()
        -- Look for crate data in various locations
        local possibleLocations = {
            ReplicatedStorage,
            game.ReplicatedFirst,
            game.StarterGui,
            game.StarterPlayer
        }
        
        local function searchForCrateData(obj, path, depth)
            if depth > 3 then return end
            
            for _, child in pairs(obj:GetChildren()) do
                if child.ClassName == "ModuleScript" or child.ClassName == "Folder" then
                    if string.find(child.Name:lower(), "crate") or 
                       string.find(child.Name:lower(), "skin") or
                       string.find(child.Name:lower(), "shop") then
                        print("🎯 Found potential crate data: " .. path .. "." .. child.Name)
                        
                        if child.ClassName == "ModuleScript" then
                            local moduleSuccess = pcall(function()
                                local module = require(child)
                                if type(module) == "table" then
                                    for key, value in pairs(module) do
                                        if type(key) == "string" and 
                                           (string.find(key:lower(), "crate") or string.find(key:lower(), "skin")) then
                                            print("   📝 Found key: " .. key)
                                        end
                                    end
                                end
                            end)
                        end
                    end
                end
                
                if child.ClassName == "Folder" then
                    searchForCrateData(child, path .. "." .. child.Name, depth + 1)
                end
            end
        end
        
        for _, location in ipairs(possibleLocations) do
            searchForCrateData(location, location.Name, 0)
        end
    end)
    
    if not success then
        print("❌ Could not search game data")
    end
end

-- Run all tests
print("🔍 Step 1: Finding working remote...")
if findWorkingRemote() then
    print("🔍 Step 2: Testing crate names...")
    local validCrates = testCrateNames()
    
    print("🔍 Step 3: Searching game data...")
    tryGetCrateNamesFromGame()
    
    print("\n🎉 TESTING COMPLETE!")
    print("Use _G.ValidCrateNames to get the list of working crate names")
else
    print("❌ Could not find working remote")
end