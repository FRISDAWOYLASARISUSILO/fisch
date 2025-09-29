-- Debug Version of Fisch Auto Buy UI
-- Enhanced error handling and debugging

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Skin Crates data
local skinCratesData = {
    "Moosewood", "Desolate", "Cthulu", "Ancient", "Mariana's",
    "Cosmetic Case", "Cosmetic Case Legendary", "Atlantis", 
    "Cursed", "Cultist", "Coral", "Friendly", 
    "Red Marlins", "Midas' Mates", "Ghosts"
}

-- Settings
local settings = {
    enabled = false,
    buyDelay = 2,
    maxPurchases = 1,
    selectedCrates = skinCratesData,
    autoSpin = true,
    debugMode = true
}

-- UI Variables
local gui = nil
local statusLabel = nil
local purchaseCountLabel = nil
local debugLabel = nil

-- Remote references
local remotes = {}

-- Debug logging
local function debugLog(message)
    if settings.debugMode then
        print("[DEBUG] " .. message)
        if debugLabel then
            debugLabel.Text = "Debug: " .. message
        end
    end
end

-- Initialize remotes with detailed error checking
local function initRemotes()
    debugLog("Initializing remotes...")
    
    local success = pcall(function()
        -- Check if ReplicatedStorage exists
        local repStorage = ReplicatedStorage
        if not repStorage then
            error("ReplicatedStorage not found")
        end
        debugLog("ReplicatedStorage found")
        
        -- Check packages
        local packages = repStorage:WaitForChild("packages", 5)
        if not packages then
            error("packages not found in ReplicatedStorage")
        end
        debugLog("packages found")
        
        -- Check Net
        local netPackages = packages:WaitForChild("Net", 5)
        if not netPackages then
            error("Net not found in packages")
        end
        debugLog("Net found")
        
        -- Check RF folder
        local rfFolder = netPackages:WaitForChild("RF", 5)
        if not rfFolder then
            error("RF folder not found in Net")
        end
        debugLog("RF folder found")
        
        -- Check SkinCrates folder
        local skinCratesFolder = rfFolder:WaitForChild("SkinCrates", 5)
        if not skinCratesFolder then
            error("SkinCrates folder not found in RF")
        end
        debugLog("SkinCrates folder found")
        
        -- Get Purchase remote
        local purchaseRemote = skinCratesFolder:WaitForChild("Purchase", 5)
        if not purchaseRemote then
            error("Purchase remote not found in SkinCrates")
        end
        debugLog("Purchase remote found: " .. tostring(purchaseRemote))
        
        -- Get RequestSpin remote
        local spinRemote = skinCratesFolder:WaitForChild("RequestSpin", 5)
        if not spinRemote then
            error("RequestSpin remote not found in SkinCrates")
        end
        debugLog("RequestSpin remote found: " .. tostring(spinRemote))
        
        remotes.purchase = purchaseRemote
        remotes.spin = spinRemote
        
        debugLog("All remotes initialized successfully!")
    end)
    
    if not success then
        debugLog("Failed to initialize remotes")
        return false
    end
    
    return true
end

-- Purchase functions with detailed error handling
local function purchaseCrate(crateName)
    if not remotes.purchase then 
        debugLog("Purchase remote not available")
        return false, "Purchase remote not available"
    end
    
    debugLog("Attempting to purchase: " .. crateName)
    
    local success, response = pcall(function()
        return remotes.purchase:InvokeServer(crateName)
    end)
    
    if success then
        debugLog("Purchase response: " .. tostring(response))
        if response == true or (type(response) == "table" and response.success) then
            debugLog("Purchase successful for: " .. crateName)
            return true, response
        else
            debugLog("Purchase failed for: " .. crateName .. " (Response: " .. tostring(response) .. ")")
            return false, response
        end
    else
        debugLog("Purchase error for: " .. crateName .. " (Error: " .. tostring(response) .. ")")
        return false, response
    end
end

local function spinCrate(crateName)
    if not remotes.spin then 
        debugLog("Spin remote not available")
        return false, "Spin remote not available"
    end
    
    debugLog("Attempting to spin: " .. crateName)
    
    local success, response = pcall(function()
        return remotes.spin:InvokeServer(crateName)
    end)
    
    if success then
        debugLog("Spin response: " .. tostring(response))
        return true, response
    else
        debugLog("Spin error for: " .. crateName .. " (Error: " .. tostring(response) .. ")")
        return false, response
    end
end

-- Update status with more detailed info
local function updateStatus(text, color, isError)
    if statusLabel then
        statusLabel.Text = text
        statusLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    end
    
    if isError then
        debugLog("ERROR: " .. text)
    else
        debugLog("STATUS: " .. text)
    end
end

-- Enhanced auto buy function
local function startAutoBuy()
    debugLog("Starting auto buy process...")
    
    if not initRemotes() then
        updateStatus("❌ Failed to initialize remotes - Check console", Color3.fromRGB(255, 0, 0), true)
        return
    end
    
    if #settings.selectedCrates == 0 then
        updateStatus("⚠️ No crates selected", Color3.fromRGB(255, 255, 0))
        return
    end
    
    local totalPurchases = 0
    local successfulPurchases = 0
    local failedPurchases = 0
    
    for i = 1, settings.maxPurchases do
        if not settings.enabled then break end
        
        for j, crateName in ipairs(settings.selectedCrates) do
            if not settings.enabled then break end
            
            updateStatus(string.format("🛒 Buying %s (%d/%d)", crateName, i, settings.maxPurchases), Color3.fromRGB(0, 255, 255))
            
            local purchaseSuccess, purchaseResponse = purchaseCrate(crateName)
            
            if purchaseSuccess then
                successfulPurchases = successfulPurchases + 1
                totalPurchases = totalPurchases + 1
                updateStatus("✅ Bought " .. crateName, Color3.fromRGB(0, 255, 0))
                
                if settings.autoSpin then
                    wait(0.5)
                    local spinSuccess, spinResponse = spinCrate(crateName)
                    if spinSuccess then
                        updateStatus("🎲 Spun " .. crateName, Color3.fromRGB(100, 255, 100))
                    else
                        updateStatus("⚠️ Bought but failed to spin: " .. crateName, Color3.fromRGB(255, 255, 0))
                    end
                end
            else
                failedPurchases = failedPurchases + 1
                local errorMsg = "❌ Failed: " .. crateName
                if purchaseResponse then
                    errorMsg = errorMsg .. " (" .. tostring(purchaseResponse) .. ")"
                end
                updateStatus(errorMsg, Color3.fromRGB(255, 0, 0), true)
            end
            
            if purchaseCountLabel then
                purchaseCountLabel.Text = string.format("Success: %d | Failed: %d | Total: %d", 
                    successfulPurchases, failedPurchases, totalPurchases)
            end
            
            wait(settings.buyDelay)
        end
    end
    
    local finalMessage = string.format("🏁 Complete! Success: %d | Failed: %d", successfulPurchases, failedPurchases)
    updateStatus(finalMessage, Color3.fromRGB(0, 255, 0))
    settings.enabled = false
    updateMainButton()
end

-- Update main button
local function updateMainButton()
    local mainButton = gui and gui:FindFirstChild("MainButton")
    if mainButton then
        mainButton.BackgroundColor3 = settings.enabled and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(0, 200, 100)
        mainButton.Text = settings.enabled and "⏹️ STOP" or "▶️ START"
    end
end

-- Create enhanced UI with debug info
local function createDebugUI()
    if gui then gui:Destroy() end
    
    -- Main GUI
    gui = Instance.new("ScreenGui")
    gui.Name = "FischDebugUI"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui
    
    -- Main Frame (taller for debug info)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 320, 0, 600)
    mainFrame.Position = UDim2.new(1, -340, 0, 20)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = gui
    
    -- Corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "🔧 Debug Auto Buy"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    closeBtn.Position = UDim2.new(1, -35, 0, 10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 12
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = mainFrame
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 4)
    closeBtnCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)
    
    -- Debug toggle
    local debugToggle = Instance.new("TextButton")
    debugToggle.Size = UDim2.new(1, -20, 0, 25)
    debugToggle.Position = UDim2.new(0, 10, 0, 50)
    debugToggle.BackgroundColor3 = settings.debugMode and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    debugToggle.BorderSizePixel = 0
    debugToggle.Text = "🔧 Debug Mode: " .. (settings.debugMode and "ON" or "OFF")
    debugToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    debugToggle.TextSize = 12
    debugToggle.Font = Enum.Font.GothamSemibold
    debugToggle.Parent = mainFrame
    
    local debugToggleCorner = Instance.new("UICorner")
    debugToggleCorner.CornerRadius = UDim.new(0, 4)
    debugToggleCorner.Parent = debugToggle
    
    debugToggle.MouseButton1Click:Connect(function()
        settings.debugMode = not settings.debugMode
        debugToggle.BackgroundColor3 = settings.debugMode and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
        debugToggle.Text = "🔧 Debug Mode: " .. (settings.debugMode and "ON" or "OFF")
    end)
    
    -- Test remotes button
    local testBtn = Instance.new("TextButton")
    testBtn.Size = UDim2.new(1, -20, 0, 25)
    testBtn.Position = UDim2.new(0, 10, 0, 85)
    testBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 200)
    testBtn.BorderSizePixel = 0
    testBtn.Text = "🧪 Test Remote Connection"
    testBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    testBtn.TextSize = 12
    testBtn.Font = Enum.Font.GothamSemibold
    testBtn.Parent = mainFrame
    
    local testBtnCorner = Instance.new("UICorner")
    testBtnCorner.CornerRadius = UDim.new(0, 4)
    testBtnCorner.Parent = testBtn
    
    testBtn.MouseButton1Click:Connect(function()
        updateStatus("🧪 Testing remotes...", Color3.fromRGB(100, 100, 200))
        spawn(function()
            local success = initRemotes()
            if success then
                updateStatus("✅ Remotes test passed!", Color3.fromRGB(0, 255, 0))
            else
                updateStatus("❌ Remotes test failed!", Color3.fromRGB(255, 0, 0), true)
            end
        end)
    end)
    
    -- Settings frame (smaller)
    local settingsFrame = Instance.new("Frame")
    settingsFrame.Size = UDim2.new(1, -20, 0, 80)
    settingsFrame.Position = UDim2.new(0, 10, 0, 120)
    settingsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    settingsFrame.BorderSizePixel = 0
    settingsFrame.Parent = mainFrame
    
    local settingsCorner = Instance.new("UICorner")
    settingsCorner.CornerRadius = UDim.new(0, 6)
    settingsCorner.Parent = settingsFrame
    
    -- Max purchases and delay in one row
    local maxLabel = Instance.new("TextLabel")
    maxLabel.Size = UDim2.new(0.5, -5, 0, 25)
    maxLabel.Position = UDim2.new(0, 10, 0, 10)
    maxLabel.BackgroundTransparency = 1
    maxLabel.Text = "Max:"
    maxLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    maxLabel.TextSize = 12
    maxLabel.Font = Enum.Font.Gotham
    maxLabel.TextXAlignment = Enum.TextXAlignment.Left
    maxLabel.Parent = settingsFrame
    
    local maxBox = Instance.new("TextBox")
    maxBox.Size = UDim2.new(0.5, -10, 0, 25)
    maxBox.Position = UDim2.new(0.5, 5, 0, 10)
    maxBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    maxBox.BorderSizePixel = 0
    maxBox.Text = tostring(settings.maxPurchases)
    maxBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    maxBox.TextSize = 12
    maxBox.Font = Enum.Font.Gotham
    maxBox.Parent = settingsFrame
    
    local maxBoxCorner = Instance.new("UICorner")
    maxBoxCorner.CornerRadius = UDim.new(0, 4)
    maxBoxCorner.Parent = maxBox
    
    local delayLabel = Instance.new("TextLabel")
    delayLabel.Size = UDim2.new(0.5, -5, 0, 25)
    delayLabel.Position = UDim2.new(0, 10, 0, 45)
    delayLabel.BackgroundTransparency = 1
    delayLabel.Text = "Delay:"
    delayLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    delayLabel.TextSize = 12
    delayLabel.Font = Enum.Font.Gotham
    delayLabel.TextXAlignment = Enum.TextXAlignment.Left
    delayLabel.Parent = settingsFrame
    
    local delayBox = Instance.new("TextBox")
    delayBox.Size = UDim2.new(0.5, -10, 0, 25)
    delayBox.Position = UDim2.new(0.5, 5, 0, 45)
    delayBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    delayBox.BorderSizePixel = 0
    delayBox.Text = tostring(settings.buyDelay)
    delayBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    delayBox.TextSize = 12
    delayBox.Font = Enum.Font.Gotham
    delayBox.Parent = settingsFrame
    
    local delayBoxCorner = Instance.new("UICorner")
    delayBoxCorner.CornerRadius = UDim.new(0, 4)
    delayBoxCorner.Parent = delayBox
    
    -- Status section
    local statusFrame = Instance.new("Frame")
    statusFrame.Size = UDim2.new(1, -20, 0, 80)
    statusFrame.Position = UDim2.new(0, 10, 0, 210)
    statusFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    statusFrame.BorderSizePixel = 0
    statusFrame.Parent = mainFrame
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 6)
    statusCorner.Parent = statusFrame
    
    statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -10, 0, 25)
    statusLabel.Position = UDim2.new(0, 5, 0, 5)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Ready to start debug auto buy"
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLabel.TextSize = 11
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextWrapped = true
    statusLabel.Parent = statusFrame
    
    purchaseCountLabel = Instance.new("TextLabel")
    purchaseCountLabel.Size = UDim2.new(1, -10, 0, 20)
    purchaseCountLabel.Position = UDim2.new(0, 5, 0, 30)
    purchaseCountLabel.BackgroundTransparency = 1
    purchaseCountLabel.Text = "Success: 0 | Failed: 0 | Total: 0"
    purchaseCountLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    purchaseCountLabel.TextSize = 10
    purchaseCountLabel.Font = Enum.Font.Gotham
    purchaseCountLabel.TextXAlignment = Enum.TextXAlignment.Left
    purchaseCountLabel.Parent = statusFrame
    
    -- Debug info label
    debugLabel = Instance.new("TextLabel")
    debugLabel.Size = UDim2.new(1, -10, 0, 20)
    debugLabel.Position = UDim2.new(0, 5, 0, 55)
    debugLabel.BackgroundTransparency = 1
    debugLabel.Text = "Debug: Ready"
    debugLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    debugLabel.TextSize = 9
    debugLabel.Font = Enum.Font.Gotham
    debugLabel.TextXAlignment = Enum.TextXAlignment.Left
    debugLabel.Parent = statusFrame
    
    -- Quick test buttons
    local quickFrame = Instance.new("Frame")
    quickFrame.Size = UDim2.new(1, -20, 0, 60)
    quickFrame.Position = UDim2.new(0, 10, 0, 300)
    quickFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    quickFrame.BorderSizePixel = 0
    quickFrame.Parent = mainFrame
    
    local quickCorner = Instance.new("UICorner")
    quickCorner.CornerRadius = UDim.new(0, 6)
    quickCorner.Parent = quickFrame
    
    local quickTitle = Instance.new("TextLabel")
    quickTitle.Size = UDim2.new(1, 0, 0, 20)
    quickTitle.Position = UDim2.new(0, 5, 0, 5)
    quickTitle.BackgroundTransparency = 1
    quickTitle.Text = "🚀 Quick Tests:"
    quickTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    quickTitle.TextSize = 12
    quickTitle.Font = Enum.Font.GothamSemibold
    quickTitle.TextXAlignment = Enum.TextXAlignment.Left
    quickTitle.Parent = quickFrame
    
    -- Test buy Moosewood
    local testMoosewood = Instance.new("TextButton")
    testMoosewood.Size = UDim2.new(0.48, 0, 0, 25)
    testMoosewood.Position = UDim2.new(0, 5, 0, 30)
    testMoosewood.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
    testMoosewood.BorderSizePixel = 0
    testMoosewood.Text = "Buy Moosewood"
    testMoosewood.TextColor3 = Color3.fromRGB(255, 255, 255)
    testMoosewood.TextSize = 10
    testMoosewood.Font = Enum.Font.GothamSemibold
    testMoosewood.Parent = quickFrame
    
    local testMoosewoodCorner = Instance.new("UICorner")
    testMoosewoodCorner.CornerRadius = UDim.new(0, 4)
    testMoosewoodCorner.Parent = testMoosewood
    
    -- Test buy Ancient
    local testAncient = Instance.new("TextButton")
    testAncient.Size = UDim2.new(0.48, 0, 0, 25)
    testAncient.Position = UDim2.new(0.52, 0, 0, 30)
    testAncient.BackgroundColor3 = Color3.fromRGB(150, 100, 0)
    testAncient.BorderSizePixel = 0
    testAncient.Text = "Buy Ancient"
    testAncient.TextColor3 = Color3.fromRGB(255, 255, 255)
    testAncient.TextSize = 10
    testAncient.Font = Enum.Font.GothamSemibold
    testAncient.Parent = quickFrame
    
    local testAncientCorner = Instance.new("UICorner")
    testAncientCorner.CornerRadius = UDim.new(0, 4)
    testAncientCorner.Parent = testAncient
    
    -- Main button
    local mainButton = Instance.new("TextButton")
    mainButton.Name = "MainButton"
    mainButton.Size = UDim2.new(1, -20, 0, 40)
    mainButton.Position = UDim2.new(0, 10, 0, 550)
    mainButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    mainButton.BorderSizePixel = 0
    mainButton.Text = "▶️ START DEBUG AUTO BUY"
    mainButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    mainButton.TextSize = 14
    mainButton.Font = Enum.Font.GothamBold
    mainButton.Parent = mainFrame
    
    local mainBtnCorner = Instance.new("UICorner")
    mainBtnCorner.CornerRadius = UDim.new(0, 8)
    mainBtnCorner.Parent = mainButton
    
    -- Event handlers
    maxBox.FocusLost:Connect(function()
        local value = tonumber(maxBox.Text)
        if value and value > 0 then
            settings.maxPurchases = math.floor(value)
        end
        maxBox.Text = tostring(settings.maxPurchases)
    end)
    
    delayBox.FocusLost:Connect(function()
        local value = tonumber(delayBox.Text)
        if value and value >= 0 then
            settings.buyDelay = value
        end
        delayBox.Text = tostring(settings.buyDelay)
    end)
    
    testMoosewood.MouseButton1Click:Connect(function()
        if not settings.enabled then
            updateStatus("🧪 Testing Moosewood purchase...", Color3.fromRGB(0, 150, 100))
            spawn(function()
                if initRemotes() then
                    local success, response = purchaseCrate("Moosewood")
                    if success then
                        updateStatus("✅ Moosewood test successful!", Color3.fromRGB(0, 255, 0))
                    else
                        updateStatus("❌ Moosewood test failed: " .. tostring(response), Color3.fromRGB(255, 0, 0), true)
                    end
                else
                    updateStatus("❌ Remote init failed", Color3.fromRGB(255, 0, 0), true)
                end
            end)
        end
    end)
    
    testAncient.MouseButton1Click:Connect(function()
        if not settings.enabled then
            updateStatus("🧪 Testing Ancient purchase...", Color3.fromRGB(150, 100, 0))
            spawn(function()
                if initRemotes() then
                    local success, response = purchaseCrate("Ancient")
                    if success then
                        updateStatus("✅ Ancient test successful!", Color3.fromRGB(0, 255, 0))
                    else
                        updateStatus("❌ Ancient test failed: " .. tostring(response), Color3.fromRGB(255, 0, 0), true)
                    end
                else
                    updateStatus("❌ Remote init failed", Color3.fromRGB(255, 0, 0), true)
                end
            end)
        end
    end)
    
    mainButton.MouseButton1Click:Connect(function()
        settings.enabled = not settings.enabled
        updateMainButton()
        
        if settings.enabled then
            spawn(startAutoBuy)
        else
            updateStatus("⏹️ Stopped by user", Color3.fromRGB(255, 100, 0))
        end
    end)
    
    -- Entrance animation
    mainFrame.Position = UDim2.new(1, 0, 0, 20)
    TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
        Position = UDim2.new(1, -340, 0, 20)
    }):Play()
    
    -- Auto-initialize remotes on UI load
    spawn(function()
        wait(1)
        debugLog("Auto-testing remotes on startup...")
        initRemotes()
    end)
end

-- Keybind (F4 for debug version)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F4 then
        if gui and gui.Parent then
            gui:Destroy()
        else
            createDebugUI()
        end
    end
end)

-- Create UI on load
createDebugUI()

-- Global access
_G.FischDebugUI = {
    show = createDebugUI,
    hide = function() if gui then gui:Destroy() end end,
    toggle = function()
        if gui and gui.Parent then
            gui:Destroy()
        else
            createDebugUI()
        end
    end,
    testRemotes = initRemotes,
    debugMode = function(enabled) settings.debugMode = enabled end
}

print("🔧 Fisch Debug Auto Buy UI Loaded!")
print("Press F4 to toggle debug UI")
print("Use debug mode to see detailed error messages")
