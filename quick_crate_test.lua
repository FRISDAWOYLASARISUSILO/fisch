-- Quick Crate Name Test Script
-- Test beberapa nama crates dengan alternative names

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Alternative crate names to try if main name fails
local alternativeCrateNames = {
    ["Mariana's"] = {"Marianas", "Mariana", "Mari"},
    ["Cthulu"] = {"Cthulhu", "Cth"},
    ["Red Marlins"] = {"RedMarlins", "Red_Marlins", "Red"},
    ["Midas' Mates"] = {"Midas_Mates", "MidasMates", "Midas"}
}

-- Test crates
local testCrates = {"Moosewood", "Mariana's", "Cthulu", "Red Marlins", "Midas' Mates"}

-- Find remotes dengan flexible approach
local function findRemotes()
    local remotes = {}
    
    -- Method 1: Standard path
    local success = pcall(function()
        local netPackages = ReplicatedStorage:WaitForChild("packages", 5):WaitForChild("Net", 5)
        remotes.purchase = netPackages:WaitForChild("RF", 5):WaitForChild("SkinCrates", 5):WaitForChild("Purchase", 5)
    end)
    
    if success and remotes.purchase then
        print("✅ Found remotes via standard path")
        return remotes
    end
    
    -- Method 2: Search dalam ReplicatedStorage
    local function searchForRemote(parent, targetName, depth)
        if depth > 3 then return nil end
        
        for _, child in pairs(parent:GetChildren()) do
            if child.Name == targetName and child:IsA("RemoteFunction") then
                return child
            elseif child:IsA("Folder") then
                local found = searchForRemote(child, targetName, depth + 1)
                if found then return found end
            end
        end
        return nil
    end
    
    remotes.purchase = searchForRemote(ReplicatedStorage, "Purchase", 0)
    
    if remotes.purchase then
        print("✅ Found purchase remote via search")
        return remotes
    end
    
    print("❌ Could not find purchase remote")
    return nil
end

-- Test purchase function
local function testPurchase(crateName, remote)
    local function tryName(name)
        print("🧪 Testing: " .. name)
        local success, response = pcall(function()
            return remote:InvokeServer(name)
        end)
        
        if success then
            print("  📤 Response: " .. tostring(response) .. " (type: " .. type(response) .. ")")
            -- Check if response indicates success
            if response == true or response == "success" or (type(response) == "table" and response.success) then
                return true
            elseif response ~= nil and response ~= false then
                -- Non-nil response might indicate some success
                return true
            end
        else
            print("  ❌ Error: " .. tostring(response))
        end
        return false
    end
    
    print("\n🎯 Testing crate: " .. crateName)
    
    -- Try original name
    if tryName(crateName) then
        print("✅ SUCCESS with original name: " .. crateName)
        return true
    end
    
    -- Try alternatives
    if alternativeCrateNames[crateName] then
        print("🔄 Trying alternatives...")
        for _, altName in ipairs(alternativeCrateNames[crateName]) do
            if tryName(altName) then
                print("✅ SUCCESS with alternative: " .. altName)
                return true
            end
        end
    end
    
    print("❌ All attempts failed for: " .. crateName)
    return false
end

-- Main test
print("🚀 Starting Quick Crate Test...")
print("==============================")

local remotes = findRemotes()
if not remotes or not remotes.purchase then
    print("❌ Cannot find purchase remote - aborting test")
    return
end

print("🎯 Testing " .. #testCrates .. " crates...")

local results = {}
for _, crateName in ipairs(testCrates) do
    local success = testPurchase(crateName, remotes.purchase)
    results[crateName] = success
    wait(1) -- Small delay between tests
end

print("\n📊 RESULTS SUMMARY:")
print("==================")
for crateName, success in pairs(results) do
    local status = success and "✅ WORKS" or "❌ FAILED"
    print(crateName .. ": " .. status)
end

print("\n🎯 Recommendation:")
if results["Moosewood"] then
    print("✅ Connection works - focus on fixing crate names")
    
    local workingCount = 0
    for _, success in pairs(results) do
        if success then workingCount = workingCount + 1 end
    end
    
    print("📈 " .. workingCount .. " out of " .. #testCrates .. " crates working")
else
    print("❌ Basic connection issue - check remote paths")
end