-- Simple Fisch Remote Finder
-- Mencari RemoteFunction dan RemoteEvent untuk SkinCrates

local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🔍 FISCH REMOTE FINDER STARTED")
print(string.rep("=", 40))

-- Function to find all RemoteFunctions and RemoteEvents
local function findAllRemotes(obj, path, depth)
    path = path or obj.Name
    depth = depth or 0
    
    if depth > 5 then return end -- Limit depth to prevent infinite recursion
    
    -- Check if this is a RemoteFunction or RemoteEvent
    if obj.ClassName == "RemoteFunction" then
        print("🔵 RemoteFunction: " .. path)
        
        -- Check if related to SkinCrates
        if string.find(path:lower(), "skin") or string.find(path:lower(), "crate") or 
           string.find(path:lower(), "purchase") or string.find(path:lower(), "spin") then
            print("   🎯 SKIN CRATES RELATED!")
        end
        
    elseif obj.ClassName == "RemoteEvent" then
        print("🟢 RemoteEvent: " .. path)
        
        -- Check if related to SkinCrates  
        if string.find(path:lower(), "skin") or string.find(path:lower(), "crate") or 
           string.find(path:lower(), "purchase") or string.find(path:lower(), "spin") then
            print("   🎯 SKIN CRATES RELATED!")
        end
    end
    
    -- Search in children
    for _, child in ipairs(obj:GetChildren()) do
        findAllRemotes(child, path .. "." .. child.Name, depth + 1)
    end
end

-- Function to check specific structure
local function checkSpecificPaths()
    print("\n📋 CHECKING SPECIFIC STRUCTURES:")
    print(string.rep("-", 30))
    
    -- Check if packages exists
    local packages = ReplicatedStorage:FindFirstChild("packages")
    if packages then
        print("✅ packages folder found")
        
        local net = packages:FindFirstChild("Net")
        if net then
            print("✅ Net folder found")
            
            -- List all children in Net
            print("📁 Contents of Net folder:")
            for _, child in ipairs(net:GetChildren()) do
                print("  - " .. child.Name .. " (" .. child.ClassName .. ")")
                
                -- If it's a folder, check inside
                if child.ClassName == "Folder" then
                    print("    📂 Contents of " .. child.Name .. ":")
                    for _, subchild in ipairs(child:GetChildren()) do
                        print("      - " .. subchild.Name .. " (" .. subchild.ClassName .. ")")
                        
                        -- Check one more level
                        if subchild.ClassName == "Folder" then
                            for _, subsubchild in ipairs(subchild:GetChildren()) do
                                print("        - " .. subsubchild.Name .. " (" .. subsubchild.ClassName .. ")")
                            end
                        end
                    end
                end
            end
        else
            print("❌ Net folder not found in packages")
        end
    else
        print("❌ packages folder not found")
    end
end

-- Function to try different path combinations
local function tryAlternativePaths()
    print("\n🔄 TRYING ALTERNATIVE PATHS:")
    print(string.rep("-", 30))
    
    local alternatives = {
        {"packages", "Net", "RF", "SkinCrates", "Purchase"},
        {"packages", "Net", "RemoteFunctions", "SkinCrates", "Purchase"},  
        {"packages", "Net", "Remotes", "SkinCrates", "Purchase"},
        {"Remotes", "SkinCrates", "Purchase"},
        {"RemoteFunctions", "SkinCrates", "Purchase"},
        {"Net", "RF", "SkinCrates", "Purchase"},
        {"Net", "SkinCrates", "Purchase"}
    }
    
    for i, pathParts in ipairs(alternatives) do
        local current = ReplicatedStorage
        local fullPath = "ReplicatedStorage"
        local success = true
        
        for j, part in ipairs(pathParts) do
            local next = current:FindFirstChild(part)
            if next then
                current = next
                fullPath = fullPath .. "." .. part
            else
                success = false
                break
            end
        end
        
        if success then
            print("✅ FOUND: " .. fullPath .. " (" .. current.ClassName .. ")")
        else
            print("❌ Failed: ReplicatedStorage." .. table.concat(pathParts, "."))
        end
    end
end

-- Run all checks
findAllRemotes(ReplicatedStorage, "ReplicatedStorage", 0)
checkSpecificPaths()
tryAlternativePaths()

print("\n🎯 SEARCH COMPLETE!")
print("Look for lines marked with 🎯 SKIN CRATES RELATED!")
print(string.rep("=", 40))
