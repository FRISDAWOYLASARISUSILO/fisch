-- Analisa Mengapa Hanya Moosewood yang Berhasil
-- Script untuk investigasi mendalam server responses

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Test cases untuk analisa
local investigationCrates = {
    "Moosewood",      -- ✅ Known working
    "Desolate",       -- ❌ Failed
    "Ancient",        -- ❌ Failed  
    "Mariana's",      -- ❌ Failed
    "Cthulu",         -- ❌ Failed
    "Atlantis"        -- ❌ Failed
}

-- Alternative spellings untuk test
local alternativeTests = {
    ["Mariana's"] = {"Marianas", "Mariana", "mariana", "MARIANA", "Mari", "MarianaTrench"},
    ["Cthulu"] = {"Cthulhu", "cthulu", "CTHULU", "cthulhu", "CTHULHU", "Cth"},
    ["Desolate"] = {"desolate", "DESOLATE", "Des", "Desol"},
    ["Ancient"] = {"ancient", "ANCIENT", "Anc", "AncientCrate"},
    ["Atlantis"] = {"atlantis", "ATLANTIS", "Atl", "AtlantisCrate"}
}

-- Find remote function
local function findPurchaseRemote()
    local remote = nil
    
    pcall(function()
        local netPackages = ReplicatedStorage:WaitForChild("packages", 3):WaitForChild("Net", 3)
        remote = netPackages:WaitForChild("RF", 3):WaitForChild("SkinCrates", 3):WaitForChild("Purchase", 3)
    end)
    
    if remote then
        print("✅ Found Purchase remote")
        return remote
    end
    
    print("❌ Could not find remote")
    return nil
end

-- Detailed analysis function
local function analyzeResponse(crateName, response, success)
    print("\n🔍 DETAILED ANALYSIS for: " .. crateName)
    print("  📊 Success: " .. tostring(success))
    print("  📊 Response: " .. tostring(response))
    print("  📊 Type: " .. type(response))
    
    if type(response) == "table" then
        print("  📊 Table contents:")
        for k, v in pairs(response) do
            print("    • " .. tostring(k) .. " = " .. tostring(v))
        end
    end
    
    -- Analyze what might indicate success/failure
    if response == nil then
        print("  🔴 NIL RESPONSE - Server doesn't recognize this crate name")
        return "INVALID_NAME"
    elseif response == false then
        print("  🟡 FALSE RESPONSE - Valid name but purchase failed (maybe insufficient funds)")
        return "PURCHASE_FAILED"
    elseif response == true then
        print("  🟢 TRUE RESPONSE - Purchase successful!")
        return "SUCCESS"
    elseif type(response) == "string" then
        if string.lower(response):find("success") then
            print("  🟢 SUCCESS STRING - Purchase successful!")
            return "SUCCESS"
        elseif string.lower(response):find("fail") or string.lower(response):find("error") then
            print("  🔴 FAILURE STRING - Purchase failed")
            return "PURCHASE_FAILED"
        else
            print("  🟡 UNKNOWN STRING - Unclear response")
            return "UNCLEAR"
        end
    elseif type(response) == "number" then
        print("  🟡 NUMBER RESPONSE - Might be cost or result code")
        return "NUMBER_RESULT"
    else
        print("  🟡 UNKNOWN TYPE - Unexpected response type")
        return "UNKNOWN"
    end
end

-- Test specific crate with detailed logging
local function testCrateDetailed(crateName, remote)
    print("\n" .. string.rep("=", 50))
    print("🧪 TESTING: " .. crateName)
    print(string.rep("=", 50))
    
    local success, response = pcall(function()
        return remote:InvokeServer(crateName)
    end)
    
    local result = analyzeResponse(crateName, response, success)
    
    -- Additional checks
    if success then
        print("  ✅ Remote call successful (no error thrown)")
    else
        print("  ❌ Remote call failed with error: " .. tostring(response))
    end
    
    return result, response
end

-- Main investigation
print("🕵️ STARTING DEEP INVESTIGATION")
print("Why does only Moosewood work?")
print("=" .. string.rep("=", 60))

local remote = findPurchaseRemote()
if not remote then
    print("❌ Cannot continue without remote")
    return
end

-- Test all main crates
local results = {}
for _, crateName in ipairs(investigationCrates) do
    local result, response = testCrateDetailed(crateName, remote)
    results[crateName] = {result = result, response = response}
    wait(1) -- Delay between tests
end

-- Summary of main results
print("\n" .. string.rep("=", 60))
print("📊 MAIN RESULTS SUMMARY")
print("=" .. string.rep("=", 60))

for crateName, data in pairs(results) do
    local status = data.result == "SUCCESS" and "✅ WORKS" or 
                   data.result == "INVALID_NAME" and "❌ INVALID NAME" or
                   data.result == "PURCHASE_FAILED" and "⚠️ VALID NAME, PURCHASE FAILED" or
                   "🟡 UNCLEAR"
    print(crateName .. ": " .. status)
end

-- Test alternatives for failed ones
print("\n" .. string.rep("=", 60))
print("🔄 TESTING ALTERNATIVE SPELLINGS")
print("=" .. string.rep("=", 60))

local alternativeResults = {}
for originalName, alternatives in pairs(alternativeTests) do
    if results[originalName] and results[originalName].result ~= "SUCCESS" then
        print("\n🔄 Testing alternatives for: " .. originalName)
        
        for _, altName in ipairs(alternatives) do
            local result, response = testCrateDetailed(altName, remote)
            if result == "SUCCESS" then
                print("🎯 FOUND WORKING ALTERNATIVE: " .. altName .. " for " .. originalName)
                alternativeResults[originalName] = altName
                break -- Stop testing once we find a working one
            end
            wait(0.5)
        end
    end
end

-- Final analysis
print("\n" .. string.rep("=", 60))
print("🎯 FINAL ANALYSIS & CONCLUSIONS")
print("=" .. string.rep("=", 60))

print("\n1. 🟢 WORKING CRATES:")
for crateName, data in pairs(results) do
    if data.result == "SUCCESS" then
        print("   • " .. crateName .. " - Server accepts this exact spelling")
    end
end

print("\n2. 🔴 INVALID NAMES (nil response):")
for crateName, data in pairs(results) do
    if data.result == "INVALID_NAME" then
        print("   • " .. crateName .. " - Server doesn't recognize this name")
    end
end

print("\n3. 🟡 VALID NAMES BUT PURCHASE FAILED:")
for crateName, data in pairs(results) do
    if data.result == "PURCHASE_FAILED" then
        print("   • " .. crateName .. " - Server recognizes name but purchase failed")
        print("     (might need currency, different requirements, etc.)")
    end
end

print("\n4. ✅ WORKING ALTERNATIVES FOUND:")
for originalName, workingAlt in pairs(alternativeResults) do
    print("   • Use '" .. workingAlt .. "' instead of '" .. originalName .. "'")
end

print("\n💡 THEORY - Why only Moosewood works:")
print("   • Server has exact case-sensitive crate names")
print("   • Display names in UI might differ from server names")
print("   • Some crates might have different internal identifiers")
print("   • Game might have been updated and some names changed")

print("\n🔧 RECOMMENDATIONS:")
print("   1. Use only confirmed working crate names")
print("   2. Always test new crates individually first") 
print("   3. Check for game updates that might change crate names")
print("   4. Consider that some crates might be disabled server-side")

print("\n📝 Update your script with only WORKING crates to avoid failures!")