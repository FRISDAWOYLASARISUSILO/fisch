-- Advanced Fisch Remote Scanner with Auto-Save
-- Multiple save methods for different executors

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local config = {
    maxDepth = 6,
    saveEnabled = true,
    fileName = "fisch_remote_scan_" .. os.date("%Y%m%d_%H%M%S") .. ".txt",
    showTimestamp = true
}

-- Storage for log data
local logData = {}
local foundRemotes = {}
local skinCratesRemotes = {}

-- Function to add timestamp
local function timestamp()
    return config.showTimestamp and "[" .. os.date("%H:%M:%S") .. "] " or ""
end

-- Enhanced logging function
local function logPrint(text, category)
    local entry = timestamp() .. text
    print(entry)
    table.insert(logData, entry)
    
    -- Categorize important findings
    if category == "remote" then
        table.insert(foundRemotes, text)
    elseif category == "skincrates" then
        table.insert(skinCratesRemotes, text)
    end
end

-- Multiple save methods
local function saveToFile()
    local content = table.concat(logData, "\n")
    local summary = "\n" .. string.rep("=", 50) .. "\n"
    summary = summary .. "FISCH REMOTE SCAN SUMMARY\n"
    summary = summary .. "Scan Date: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n"
    summary = summary .. "Total Entries: " .. #logData .. "\n"
    summary = summary .. "Found Remotes: " .. #foundRemotes .. "\n"
    summary = summary .. "SkinCrates Related: " .. #skinCratesRemotes .. "\n"
    summary = summary .. string.rep("=", 50) .. "\n\n"
    
    local fullContent = summary .. content
    
    local saveResults = {}
    
    -- Method 1: writefile (most common in executors)
    local success1 = pcall(function()
        if writefile then
            writefile(config.fileName, fullContent)
            table.insert(saveResults, "✅ Saved via writefile: " .. config.fileName)
        else
            table.insert(saveResults, "❌ writefile not available")
        end
    end)
    
    -- Method 2: Create StringValue in workspace
    local success2 = pcall(function()
        local stringValue = Instance.new("StringValue")
        stringValue.Name = "FischRemoteScanLog"
        stringValue.Value = fullContent
        stringValue.Parent = workspace
        table.insert(saveResults, "✅ Saved to workspace.FischRemoteScanLog.Value")
    end)
    
    -- Method 3: Create TextLabel with copyable text
    local success3 = pcall(function()
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        if player and player.PlayerGui then
            local gui = Instance.new("ScreenGui")
            gui.Name = "FischRemoteLog"
            gui.ResetOnSpawn = false
            gui.Parent = player.PlayerGui
            
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(0, 400, 0, 300)
            frame.Position = UDim2.new(0.5, -200, 0.5, -150)
            frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            frame.BorderSizePixel = 0
            frame.Parent = gui
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 10)
            corner.Parent = frame
            
            local title = Instance.new("TextLabel")
            title.Size = UDim2.new(1, -20, 0, 30)
            title.Position = UDim2.new(0, 10, 0, 10)
            title.BackgroundTransparency = 1
            title.Text = "📄 Remote Scan Results"
            title.TextColor3 = Color3.fromRGB(255, 255, 255)
            title.TextSize = 16
            title.Font = Enum.Font.GothamBold
            title.Parent = frame
            
            local scrollFrame = Instance.new("ScrollingFrame")
            scrollFrame.Size = UDim2.new(1, -20, 1, -80)
            scrollFrame.Position = UDim2.new(0, 10, 0, 40)
            scrollFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            scrollFrame.BorderSizePixel = 0
            scrollFrame.ScrollBarThickness = 6
            scrollFrame.Parent = frame
            
            local scrollCorner = Instance.new("UICorner")
            scrollCorner.CornerRadius = UDim.new(0, 5)
            scrollCorner.Parent = scrollFrame
            
            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, -10, 0, 0)
            textLabel.Position = UDim2.new(0, 5, 0, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.Text = fullContent
            textLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            textLabel.TextSize = 10
            textLabel.Font = Enum.Font.Code
            textLabel.TextXAlignment = Enum.TextXAlignment.Left
            textLabel.TextYAlignment = Enum.TextYAlignment.Top
            textLabel.TextWrapped = true
            textLabel.Parent = scrollFrame
            
            -- Auto-size text label
            local textSize = game:GetService("TextService"):GetTextSize(
                fullContent, 10, Enum.Font.Code, Vector2.new(380, math.huge)
            )
            textLabel.Size = UDim2.new(1, -10, 0, textSize.Y + 20)
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, textSize.Y + 20)
            
            local closeBtn = Instance.new("TextButton")
            closeBtn.Size = UDim2.new(0, 60, 0, 25)
            closeBtn.Position = UDim2.new(1, -70, 1, -35)
            closeBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
            closeBtn.BorderSizePixel = 0
            closeBtn.Text = "Close"
            closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            closeBtn.TextSize = 12
            closeBtn.Font = Enum.Font.GothamSemibold
            closeBtn.Parent = frame
            
            local closeBtnCorner = Instance.new("UICorner")
            closeBtnCorner.CornerRadius = UDim.new(0, 4)
            closeBtnCorner.Parent = closeBtn
            
            closeBtn.MouseButton1Click:Connect(function()
                gui:Destroy()
            end)
            
            table.insert(saveResults, "✅ Created GUI with results (check your screen)")
        end
    end)
    
    -- Print save results
    logPrint("\n💾 SAVE RESULTS:")
    for _, result in ipairs(saveResults) do
        logPrint(result)
    end
end

-- Enhanced remote finder with more details
local function findAllRemotes(obj, path, depth)
    path = path or obj.Name
    depth = depth or 0
    
    if depth > config.maxDepth then return end
    
    if obj.ClassName == "RemoteFunction" then
        local info = "🔵 RemoteFunction: " .. path
        logPrint(info, "remote")
        
        if string.find(path:lower(), "skin") or string.find(path:lower(), "crate") or 
           string.find(path:lower(), "purchase") or string.find(path:lower(), "spin") then
            local important = "   🎯 SKIN CRATES: " .. path .. " (" .. obj.ClassName .. ")"
            logPrint(important, "skincrates")
        end
        
    elseif obj.ClassName == "RemoteEvent" then
        local info = "🟢 RemoteEvent: " .. path
        logPrint(info, "remote")
        
        if string.find(path:lower(), "skin") or string.find(path:lower(), "crate") or 
           string.find(path:lower(), "purchase") or string.find(path:lower(), "spin") then
            local important = "   🎯 SKIN CRATES: " .. path .. " (" .. obj.ClassName .. ")"
            logPrint(important, "skincrates")
        end
    end
    
    for _, child in ipairs(obj:GetChildren()) do
        findAllRemotes(child, path .. "." .. child.Name, depth + 1)
    end
end

-- Start scanning
logPrint("🔍 FISCH ADVANCED REMOTE SCANNER")
logPrint("💾 Auto-save: " .. (config.saveEnabled and "ON" or "OFF"))
logPrint("📁 File: " .. config.fileName)
logPrint(string.rep("=", 50))

-- Run comprehensive scan
findAllRemotes(ReplicatedStorage, "ReplicatedStorage", 0)

-- Check workspace as well (some games put remotes there)
logPrint("\n🌍 SCANNING WORKSPACE:")
logPrint(string.rep("-", 30))
findAllRemotes(workspace, "workspace", 0)

-- Final summary
logPrint("\n📊 SCAN COMPLETE!")
logPrint("Found " .. #foundRemotes .. " total remotes")
logPrint("Found " .. #skinCratesRemotes .. " SkinCrates related")
logPrint(string.rep("=", 50))

-- Save to file if enabled
if config.saveEnabled then
    saveToFile()
else
    logPrint("💾 Auto-save disabled")
end

-- Global functions for manual use
_G.FischScanner = {
    rescan = function()
        logData = {}
        foundRemotes = {}
        skinCratesRemotes = {}
        findAllRemotes(ReplicatedStorage, "ReplicatedStorage", 0)
        saveToFile()
    end,
    saveNow = saveToFile,
    getLog = function() return table.concat(logData, "\n") end,
    getSkinCratesRemotes = function() return skinCratesRemotes end,
    config = config
}

logPrint("\n🔧 Commands available:")
logPrint("_G.FischScanner.rescan() - Run scan again")
logPrint("_G.FischScanner.saveNow() - Save results now")
logPrint("_G.FischScanner.getLog() - Get full log as string")