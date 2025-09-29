-- CRASH-PROOF Fisch Auto Buy (Ultra Safe Version)
-- No nil errors, comprehensive safety checks

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Ultra safe function wrappers
local function safeString(value)
    if value == nil then return "nil" end
    if type(value) == "string" then return value end
    return tostring(value)
end

local function safeNumber(value)
    local num = tonumber(value)
    return num or 0
end

local function safeBool(value)
    if value == nil then return false end
    return value == true
end

-- Debug logging
local function debugLog(message)
    local safeMsg = safeString(message)
    print("[CRASH-PROOF] " .. safeMsg)
end

-- Working crates (based on your testing)
local workingCrates = {
    "Moosewood"  -- Only confirmed working crate
}

-- Settings with nil protection
local settings = {
    enabled = false,
    buyDelay = 2,
    maxPurchases = 1,
    selectedCrates = {"Moosewood"}, -- Start with only working crate
    autoSpin = false -- Disabled to avoid issues
}

-- UI Variables with nil safety
local gui = nil
local statusLabel = nil
local mainButton = nil

-- Remote references
local remotes = {}

-- Safe remote initialization
local function initRemotes()
    debugLog("🔍 Searching for remotes safely...")
    
    local success = false
    
    -- Method 1: Standard path with full protection
    pcall(function()
        local repStorage = ReplicatedStorage
        if not repStorage then return end
        
        local packages = repStorage:FindFirstChild("packages")
        if not packages then return end
        
        local netFolder = packages:FindFirstChild("Net")
        if not netFolder then return end
        
        local rfFolder = netFolder:FindFirstChild("RF")
        if not rfFolder then return end
        
        local skinCratesFolder = rfFolder:FindFirstChild("SkinCrates")
        if not skinCratesFolder then return end
        
        local purchaseRemote = skinCratesFolder:FindFirstChild("Purchase")
        local spinRemote = skinCratesFolder:FindFirstChild("RequestSpin")
        
        if purchaseRemote and purchaseRemote:IsA("RemoteFunction") then
            remotes.purchase = purchaseRemote
            debugLog("✅ Found Purchase remote")
            success = true
        end
        
        if spinRemote and spinRemote:IsA("RemoteFunction") then
            remotes.spin = spinRemote
            debugLog("✅ Found Spin remote")
        end
    end)
    
    -- Method 2: Search method if standard fails
    if not success then
        debugLog("🔄 Trying search method...")
        
        local function safeSearch(parent, targetName, depth)
            if not parent or depth > 3 then return nil end
            
            local children = {}
            pcall(function()
                for _, child in pairs(parent:GetChildren()) do
                    table.insert(children, child)
                end
            end)
            
            for _, child in pairs(children) do
                if child and child.Name == targetName and child:IsA("RemoteFunction") then
                    return child
                elseif child and child:IsA("Folder") then
                    local found = safeSearch(child, targetName, depth + 1)
                    if found then return found end
                end
            end
            return nil
        end
        
        local purchaseRemote = safeSearch(ReplicatedStorage, "Purchase", 0)
        if purchaseRemote then
            remotes.purchase = purchaseRemote
            debugLog("✅ Found Purchase remote via search")
            success = true
        end
    end
    
    debugLog("🎯 Remote init result: " .. tostring(success))
    return success
end

-- Ultra safe purchase function
local function purchaseCrate(crateName)
    local safeName = safeString(crateName)
    debugLog("🛒 Attempting to purchase: " .. safeName)
    
    if not remotes.purchase then
        debugLog("❌ No purchase remote available")
        return false, "No remote"
    end
    
    local success, response = pcall(function()
        return remotes.purchase:InvokeServer(safeName)
    end)
    
    if success then
        local responseStr = safeString(response)
        debugLog("📤 Response: " .. responseStr .. " (type: " .. type(response) .. ")")
        
        -- Check for success indicators
        if response == true or response == "success" or 
           (type(response) == "table" and response.success) then
            return true, response
        else
            return false, response
        end
    else
        local errorStr = safeString(response)
        debugLog("💥 Purchase error: " .. errorStr)
        return false, response
    end
end

-- Safe status update
local function updateStatus(text, color)
    local safeText = safeString(text)
    local safeColor = color or Color3.fromRGB(255, 255, 255)
    
    debugLog("STATUS: " .. safeText)
    
    if statusLabel and statusLabel.Parent then
        pcall(function()
            statusLabel.Text = safeText
            statusLabel.TextColor3 = safeColor
        end)
    end
end

-- Main auto buy function (crash-proof)
local function startAutoBuy()
    debugLog("🚀 Starting crash-proof auto buy...")
    
    -- Initialize counters with absolute safety
    local successCount = 0
    local failCount = 0
    local totalAttempts = 0
    
    -- Safety check: remotes
    if not initRemotes() then
        updateStatus("❌ Could not find game remotes", Color3.fromRGB(255, 0, 0))
        return
    end
    
    -- Safety check: selected crates
    local selectedCrates = settings.selectedCrates or {"Moosewood"}
    if #selectedCrates == 0 then
        updateStatus("⚠️ No crates selected", Color3.fromRGB(255, 255, 0))
        return
    end
    
    updateStatus("🎯 Starting safe purchase process...", Color3.fromRGB(0, 255, 0))
    
    -- Main purchase loop with full safety
    local maxPurchases = safeNumber(settings.maxPurchases)
    if maxPurchases <= 0 then maxPurchases = 1 end
    
    for i = 1, maxPurchases do
        if not safeBool(settings.enabled) then 
            debugLog("⏹️ Stopped by user")
            break 
        end
        
        for j, crateName in ipairs(selectedCrates) do
            if not safeBool(settings.enabled) then break end
            
            local safeCrateName = safeString(crateName)
            totalAttempts = totalAttempts + 1
            
            updateStatus(string.format("🛒 Buying %s (%d/%d)", safeCrateName, i, maxPurchases), Color3.fromRGB(0, 255, 255))
            
            -- Safe purchase attempt
            local purchaseSuccess, purchaseResponse = purchaseCrate(safeCrateName)
            
            if safeBool(purchaseSuccess) then
                successCount = successCount + 1
                updateStatus("✅ SUCCESS: Bought " .. safeCrateName, Color3.fromRGB(0, 255, 0))
            else
                failCount = failCount + 1
                local responseStr = safeString(purchaseResponse)
                updateStatus("❌ FAILED: " .. safeCrateName .. " (" .. responseStr .. ")", Color3.fromRGB(255, 0, 0))
            end
            
            -- Safe delay
            local delay = safeNumber(settings.buyDelay)
            if delay > 0 then
                wait(delay)
            end
        end
    end
    
    -- Final message with guaranteed safety
    local finalMsg = string.format("🏁 COMPLETE! ✅ %d success | ❌ %d failed", successCount, failCount)
    updateStatus(finalMsg, successCount > 0 and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 100, 0))
    
    settings.enabled = false
    
    -- Safe button update
    if mainButton and mainButton.Parent then
        pcall(function()
            mainButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
            mainButton.Text = "▶️ START AUTO BUY"
        end)
    end
end

-- Create ultra-safe UI
local function createUI()
    debugLog("🎨 Creating crash-proof UI...")
    
    -- Remove existing GUI safely
    if gui and gui.Parent then
        pcall(function()
            gui:Destroy()
        end)
    end
    
    -- Create main GUI
    gui = Instance.new("ScreenGui")
    gui.Name = "CrashProofFischUI"
    gui.Parent = playerGui
    gui.ResetOnSpawn = false
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Parent = gui
    mainFrame.Size = UDim2.new(0, 320, 0, 200)
    mainFrame.Position = UDim2.new(0.5, -160, 0.5, -100)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    
    -- Corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Parent = mainFrame
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🎣 CRASH-PROOF FISCH AUTO BUY"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    
    -- Status label
    statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Parent = mainFrame
    statusLabel.Size = UDim2.new(1, -20, 0, 60)
    statusLabel.Position = UDim2.new(0, 10, 0, 40)
    statusLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    statusLabel.BorderSizePixel = 0
    statusLabel.Text = "🟡 Ready to start (Only Moosewood enabled for safety)"
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.TextScaled = true
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextWrapped = true
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 8)
    statusCorner.Parent = statusLabel
    
    -- Main button
    mainButton = Instance.new("TextButton")
    mainButton.Name = "MainButton"
    mainButton.Parent = mainFrame
    mainButton.Size = UDim2.new(1, -20, 0, 40)
    mainButton.Position = UDim2.new(0, 10, 0, 110)
    mainButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    mainButton.BorderSizePixel = 0
    mainButton.Text = "▶️ START AUTO BUY"
    mainButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    mainButton.TextScaled = true
    mainButton.Font = Enum.Font.GothamBold
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = mainButton
    
    -- Button click handler
    mainButton.MouseButton1Click:Connect(function()
        pcall(function()
            if safeBool(settings.enabled) then
                settings.enabled = false
                mainButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
                mainButton.Text = "▶️ START AUTO BUY"
                updateStatus("⏹️ Stopped by user", Color3.fromRGB(255, 100, 0))
            else
                settings.enabled = true
                mainButton.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
                mainButton.Text = "⏹️ STOP AUTO BUY"
                spawn(startAutoBuy)
            end
        end)
    end)
    
    -- Info label
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Name = "InfoLabel"
    infoLabel.Parent = mainFrame
    infoLabel.Size = UDim2.new(1, -20, 0, 30)
    infoLabel.Position = UDim2.new(0, 10, 0, 160)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "💡 Safe mode: Only tested crates enabled"
    infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    infoLabel.TextScaled = true
    infoLabel.Font = Enum.Font.Gotham
    
    debugLog("✅ UI created successfully")
    updateStatus("🟢 UI loaded - Ready to start!", Color3.fromRGB(0, 255, 0))
end

-- Initialize everything safely
debugLog("🚀 Initializing Crash-Proof Fisch Auto Buy...")
pcall(createUI)

debugLog("✅ Script loaded successfully!")
debugLog("🎯 Only Moosewood crate enabled for maximum safety")
debugLog("💡 If you want to test other crates, use the simple_crate_tester.lua first")