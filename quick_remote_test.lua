-- Quick Remote Test untuk Fisch
-- Tes cepat untuk menemukan remote yang benar

local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🧪 QUICK REMOTE TEST STARTED")
print("=" * 40)

-- Function to search recursively
local function searchRemotes(obj, path, depth)
    depth = depth or 0
    if depth > 4 then return end
    
    path = path or obj.Name
    
    -- Check for SkinCrates related remotes
    if obj.ClassName == "RemoteFunction" then
        if string.find(obj.Name:lower(), "purchase") and 
           (string.find(path:lower(), "skin") or string.find(path:lower(), "crate")) then
            print("🎯 PURCHASE REMOTE FOUND: " .. path)
            
            -- Test the remote
            local testSuccess = pcall(function()
                local response = obj:InvokeServer("Moosewood")
                print("   📝 Test response: " .. tostring(response))
            end)
            
            if testSuccess then
                print("   ✅ Remote is callable!")
            else
                print("   ❌ Remote test failed (might need parameters)")
            end
        end
        
        if string.find(obj.Name:lower(), "spin") and 
           (string.find(path:lower(), "skin") or string.find(path:lower(), "crate")) then
            print("🎲 SPIN REMOTE FOUND: " .. path)
        end
    end
    
    -- Search children
    for _, child in pairs(obj:GetChildren()) do
        searchRemotes(child, path .. "." .. child.Name, depth + 1)
    end
end

-- Quick test specific paths
local function testSpecificPaths()
    print("\n🎯 TESTING SPECIFIC PATHS:")
    print("-" * 30)
    
    local paths = {
        "ReplicatedStorage.packages.Net.RF.SkinCrates.Purchase",
        "ReplicatedStorage.packages.Net.RemoteFunction.SkinCrates.Purchase",
        "ReplicatedStorage.packages.Net.Remotes.SkinCrates.Purchase"
    }
    
    for _, pathStr in ipairs(paths) do
        local success = pcall(function()
            local parts = {}
            for part in pathStr:gmatch("[^%.]+") do
                table.insert(parts, part)
            end
            
            local current = game
            for _, part in ipairs(parts) do
                current = current[part]
            end
            
            print("✅ FOUND: " .. pathStr)
            print("   Type: " .. current.ClassName)
            
            -- Try to call it
            if current.ClassName == "RemoteFunction" then
                local callSuccess = pcall(function()
                    local response = current:InvokeServer("Moosewood")
                    print("   📝 Call response: " .. tostring(response))
                end)
                
                if callSuccess then
                    print("   ✅ Successfully called!")
                else
                    print("   ⚠️ Call failed (normal if no money)")
                end
            end
            
        end)
        
        if not success then
            print("❌ NOT FOUND: " .. pathStr)
        end
    end
end

-- Alternative: Check what's actually in Net folder
local function inspectNetFolder()
    print("\n📁 INSPECTING NET FOLDER STRUCTURE:")
    print("-" * 40)
    
    local success = pcall(function()
        local net = ReplicatedStorage.packages.Net
        print("✅ Net folder found")
        
        print("📂 Direct children of Net:")
        for _, child in pairs(net:GetChildren()) do
            print("  - " .. child.Name .. " (" .. child.ClassName .. ")")
            
            if child.ClassName == "Folder" then
                print("    📂 Children of " .. child.Name .. ":")
                for _, subchild in pairs(child:GetChildren()) do
                    print("      - " .. subchild.Name .. " (" .. subchild.ClassName .. ")")
                    
                    if subchild.ClassName == "Folder" and subchild.Name == "SkinCrates" then
                        print("        🎯 FOUND SKINCRATES FOLDER!")
                        print("        📂 SkinCrates contents:")
                        for _, skinchild in pairs(subchild:GetChildren()) do
                            print("          - " .. skinchild.Name .. " (" .. skinchild.ClassName .. ")")
                            
                            if skinchild.Name == "Purchase" then
                                print("            🛒 PURCHASE REMOTE FOUND!")
                                -- Try to use it
                                if skinchild.ClassName == "RemoteFunction" then
                                    local callTest = pcall(function()
                                        local response = skinchild:InvokeServer("Moosewood")
                                        print("            📝 Test response: " .. tostring(response))
                                        return response
                                    end)
                                    
                                    if callTest then
                                        print("            ✅ REMOTE IS WORKING!")
                                        _G.WorkingPurchaseRemote = skinchild
                                    else
                                        print("            ⚠️ Remote callable but failed (normal)")
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
    
    if not success then
        print("❌ Could not inspect Net folder")
    end
end

-- Run all tests
searchRemotes(ReplicatedStorage.packages.Net, "ReplicatedStorage.packages.Net")
testSpecificPaths()
inspectNetFolder()

print("\n🏁 QUICK TEST COMPLETE!")
print("Check for lines with 🎯 and ✅ for working remotes")
print("If _G.WorkingPurchaseRemote is set, you can use it directly")

-- Save working remote globally
if _G.WorkingPurchaseRemote then
    print("\n🎉 WORKING REMOTE SAVED!")
    print("Use: _G.WorkingPurchaseRemote:InvokeServer('Moosewood')")
end