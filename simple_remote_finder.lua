-- Simple Fisch Remote Finder
-- Mencari RemoteFunction dan RemoteEvent untuk SkinCrates
-- Auto-save results to file

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Auto-save variables
local logData = {}
local fileName = "fisch_remote_scan_" .. os.date("%Y%m%d_%H%M%S") .. ".txt"

-- Function to add to log and print
local function logPrint(text)
    print(text)
    table.insert(logData, text)
end

-- Function to save log to file
local function saveLogToFile()
    local success, result = pcall(function()
        -- Try different file write methods
        local content = table.concat(logData, "\n")
        
        -- Method 1: Try writefile (most common)
        if writefile then
            writefile(fileName, content)
            return "writefile"
        end
        
        -- Method 2: Try using workspace
        if workspace and workspace.CurrentCamera then
            -- Create a StringValue to hold the data
            local stringValue = Instance.new("StringValue")
            stringValue.Name = "RemoteScanLog"
            stringValue.Value = content
            stringValue.Parent = workspace
            return "workspace"
        end
        
        return false
    end)
    
    if success and result then
        if result == "writefile" then
            logPrint("💾 Log saved to: " .. fileName)
            logPrint("� File location: Executor folder or Documents")
        elseif result == "workspace" then
            logPrint("💾 Log saved to workspace as StringValue")
            logPrint("📱 You can copy the data from workspace.RemoteScanLog.Value")
        end
    else
        logPrint("❌ Could not save file automatically")
        logPrint("📋 Copy the console output manually")
    end
end

logPrint("�🔍 FISCH REMOTE FINDER STARTED")
logPrint("💾 Auto-save enabled: " .. fileName)
logPrint(string.rep("=", 40))

-- Function to find all RemoteFunctions and RemoteEvents
local function findAllRemotes(obj, path, depth)
    path = path or obj.Name
    depth = depth or 0
    
    if depth > 5 then return end -- Limit depth to prevent infinite recursion
    
    -- Check if this is a RemoteFunction or RemoteEvent
    if obj.ClassName == "RemoteFunction" then
        logPrint("🔵 RemoteFunction: " .. path)
        
        -- Check if related to SkinCrates
        if string.find(path:lower(), "skin") or string.find(path:lower(), "crate") or 
           string.find(path:lower(), "purchase") or string.find(path:lower(), "spin") then
            logPrint("   🎯 SKIN CRATES RELATED!")
        end
        
    elseif obj.ClassName == "RemoteEvent" then
        logPrint("🟢 RemoteEvent: " .. path)
        
        -- Check if related to SkinCrates  
        if string.find(path:lower(), "skin") or string.find(path:lower(), "crate") or 
           string.find(path:lower(), "purchase") or string.find(path:lower(), "spin") then
            logPrint("   🎯 SKIN CRATES RELATED!")
        end
    end
    
    -- Search in children
    for _, child in ipairs(obj:GetChildren()) do
        findAllRemotes(child, path .. "." .. child.Name, depth + 1)
    end
end

-- Function to check specific structure
local function checkSpecificPaths()
    logPrint("\n📋 CHECKING SPECIFIC STRUCTURES:")
    logPrint(string.rep("-", 30))
    
    -- Check if packages exists
    local packages = ReplicatedStorage:FindFirstChild("packages")
    if packages then
        logPrint("✅ packages folder found")
        
        local net = packages:FindFirstChild("Net")
        if net then
            logPrint("✅ Net folder found")
            
            -- List all children in Net
            logPrint("📁 Contents of Net folder:")
            for _, child in ipairs(net:GetChildren()) do
                logPrint("  - " .. child.Name .. " (" .. child.ClassName .. ")")
                
                -- If it's a folder, check inside
                if child.ClassName == "Folder" then
                    logPrint("    📂 Contents of " .. child.Name .. ":")
                    for _, subchild in ipairs(child:GetChildren()) do
                        logPrint("      - " .. subchild.Name .. " (" .. subchild.ClassName .. ")")
                        
                        -- Check one more level
                        if subchild.ClassName == "Folder" then
                            for _, subsubchild in ipairs(subchild:GetChildren()) do
                                logPrint("        - " .. subsubchild.Name .. " (" .. subsubchild.ClassName .. ")")
                            end
                        end
                    end
                end
            end
        else
            logPrint("❌ Net folder not found in packages")
        end
    else
        logPrint("❌ packages folder not found")
    end
end

-- Function to try different path combinations
local function tryAlternativePaths()
    logPrint("\n🔄 TRYING ALTERNATIVE PATHS:")
    logPrint(string.rep("-", 30))
    
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
            logPrint("✅ FOUND: " .. fullPath .. " (" .. current.ClassName .. ")")
        else
            logPrint("❌ Failed: ReplicatedStorage." .. table.concat(pathParts, "."))
        end
    end
end

-- Run all checks
findAllRemotes(ReplicatedStorage, "ReplicatedStorage", 0)
checkSpecificPaths()
tryAlternativePaths()

logPrint("\n🎯 SEARCH COMPLETE!")
logPrint("Look for lines marked with 🎯 SKIN CRATES RELATED!")
logPrint(string.rep("=", 40))

-- Auto-save results to file
logPrint("\n💾 SAVING RESULTS...")
saveLogToFile()

-- Additional info for manual copy
logPrint("\n📋 MANUAL COPY INSTRUCTIONS:")
logPrint("1. Copy all console output above")
logPrint("2. Paste into notepad and save as .txt")
logPrint("3. Or use the auto-saved file if available")

-- Create a summary
logPrint("\n📊 SCAN SUMMARY:")
logPrint("- Total log entries: " .. #logData)
logPrint("- Scan date: " .. os.date("%Y-%m-%d %H:%M:%S"))
logPrint("- File name: " .. fileName)