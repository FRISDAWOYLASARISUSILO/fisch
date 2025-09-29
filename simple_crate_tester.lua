-- Simple Individual Crate Tester
-- Tests each crate one by one with detailed logging

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Test data - focusing on potential working names
local testCrates = {
    "Moosewood",          -- Known to work
    "Desolate",           
    "Cthulhu",            -- Fixed spelling
    "Ancient",
    "Mariana",            -- Without apostrophe
    "Cosmetic Case",
    "Atlantis",
    "Cursed",
    "Cultist", 
    "Coral",
    "Friendly",
    "Red Marlins",
    "Midas Mates",       -- Without apostrophe
    "Ghosts"
}

-- Alternative spellings for problematic ones
local alternatives = {
    "marianas", "mariana", "cthulu", "cthulhu", "redmarlins", "midasmates",
    "cosmeticcase", "ancient", "desolate", "atlantis", "cursed", "cultist",
    "coral", "friendly", "ghosts", "moosewood"
}

-- Simple remote finder
local function findRemote()
    local remote = nil
    
    -- Try standard path
    pcall(function()
        local netPackages = ReplicatedStorage:WaitForChild("packages", 2):WaitForChild("Net", 2)
        remote = netPackages:WaitForChild("RF", 2):WaitForChild("SkinCrates", 2):WaitForChild("Purchase", 2)
    end)
    
    if remote then
        print("✅ Found remote via standard path")
        return remote
    end
    
    -- Search method
    local function searchFor(parent, name, depth)
        if depth > 4 then return nil end
        for _, child in pairs(parent:GetChildren()) do
            if child.Name == name and child:IsA("RemoteFunction") then
                return child
            elseif child:IsA("Folder") then
                local found = searchFor(child, name, depth + 1)
                if found then return found end
            end
        end
        return nil
    end
    
    remote = searchFor(ReplicatedStorage, "Purchase", 0)
    if remote then
        print("✅ Found remote via search")
        return remote
    end
    
    print("❌ Could not find Purchase remote")
    return nil
end

-- Test function
local function testCrate(crateName, remote)
    print("\n🧪 Testing: " .. crateName)
    
    local success, response = pcall(function()
        return remote:InvokeServer(crateName)
    end)
    
    if success then
        local responseStr = tostring(response)
        local typeStr = type(response)
        print("  📤 Response: " .. responseStr .. " (" .. typeStr .. ")")
        
        -- Determine if this indicates success
        if response == true or response == "success" or 
           (type(response) == "table" and response.success) or
           (response ~= nil and response ~= false and response ~= "failed") then
            print("  ✅ LIKELY SUCCESS")
            return true
        else
            print("  ❌ LIKELY FAILED")
            return false
        end
    else
        print("  💥 ERROR: " .. tostring(response))
        return false
    end
end

-- Main execution
print("🚀 Starting Simple Crate Test")
print("=" .. string.rep("=", 40))

local remote = findRemote()
if not remote then
    print("❌ Cannot continue without remote")
    return
end

print("📋 Testing " .. #testCrates .. " main crates...")

local workingCrates = {}
local failedCrates = {}

-- Test main crates
for i, crateName in ipairs(testCrates) do
    if testCrate(crateName, remote) then
        table.insert(workingCrates, crateName)
    else
        table.insert(failedCrates, crateName)
    end
    wait(0.5) -- Small delay between tests
end

print("\n" .. string.rep("=", 50))
print("📊 RESULTS:")
print("=" .. string.rep("=", 40))

print("\n✅ WORKING CRATES (" .. #workingCrates .. "):")
for _, name in ipairs(workingCrates) do
    print("  • " .. name)
end

print("\n❌ FAILED CRATES (" .. #failedCrates .. "):")
for _, name in ipairs(failedCrates) do
    print("  • " .. name)
end

-- If any failed, test alternatives
if #failedCrates > 0 then
    print("\n🔄 Testing alternative spellings...")
    local altWorking = {}
    
    for _, altName in ipairs(alternatives) do
        if testCrate(altName, remote) then
            table.insert(altWorking, altName)
        end
        wait(0.5)
    end
    
    if #altWorking > 0 then
        print("\n✅ WORKING ALTERNATIVES:")
        for _, name in ipairs(altWorking) do
            print("  • " .. name)
        end
    end
end

print("\n🎯 RECOMMENDATION:")
if #workingCrates >= 5 then
    print("✅ Good! Use these working crates in your main script")
elseif #workingCrates >= 1 then
    print("⚠️ Limited success - focus on working names only")
else
    print("❌ Major issue - check game updates or remote paths")
end

print("\n🔧 Next steps:")
print("1. Use only the WORKING crates in your main script")
print("2. Update skinCratesData with working names only")
print("3. Remove non-working crates to avoid errors")