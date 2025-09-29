-- FIXED Fisch Auto Buy UI
-- Updated dengan path yang BENAR dari hasil scan

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Skin Crates data (dari dump.txt)
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

-- Remote references
local remotes = {}

-- Debug logging
local function debugLog(message)
    if settings.debugMode then
        print("[FIXED] " .. message)
    end
end

-- FIXED: Initialize remotes dengan path yang BENAR dari scan results
local function initRemotes()
    debugLog("Initializing remotes with CORRECT paths...")
    
    local success = pcall(function()
        -- Menggunakan path BENAR dari scan: RF/SkinCrates/Purchase (bukan RF.SkinCrates.Purchase)
        local netPackages = ReplicatedStorage:WaitForChild("packages"):WaitForChild("Net")
        
        -- BENAR: RF/SkinCrates/Purchase
        remotes.purchase = netPackages:WaitForChild("RF"):WaitForChild("SkinCrates"):WaitForChild("Purchase")
        debugLog("✅ Purchase remote found: " .. tostring(remotes.purchase))
        
        -- BENAR: RF/SkinCrates/RequestSpin  
        remotes.spin = netPackages:WaitForChild("RF"):WaitForChild("SkinCrates"):WaitForChild("RequestSpin")
        debugLog("✅ RequestSpin remote found: " .. tostring(remotes.spin))
        
        -- BONUS: Toggle remote (RE/ToggleSkinCrates)
        remotes.toggle = netPackages:WaitForChild("RE"):WaitForChild("ToggleSkinCrates")
        debugLog("✅ Toggle remote found: " .. tostring(remotes.toggle))
        
        debugLog("🎯 ALL REMOTES INITIALIZED SUCCESSFULLY!")
    end)
    
    if not success then
        debugLog("❌ Failed to initialize remotes")
        return false
    end
    
    return true
end

-- FIXED: Purchase functions dengan error handling yang lebih baik
local function purchaseCrate(crateName)
    if not remotes.purchase then 
        debugLog("❌ Purchase remote not available")
        return false, "Purchase remote not available"
    end
    
    debugLog("🛒 Attempting to purchase: " .. crateName)
    
    local success, response = pcall(function()
        return remotes.purchase:InvokeServer(crateName)
    end)
    
    if success then
        debugLog("✅ Purchase response for " .. crateName .. ": " .. tostring(response))
        -- Response bisa berupa boolean, table, atau string
        if response == true or (type(response) == "table" and response.success) or response == "success" then
            return true, response
        else
            return false, response
        end
    else
        debugLog("❌ Purchase error for " .. crateName .. ": " .. tostring(response))
        return false, response
    end
end

local function spinCrate(crateName)
    if not remotes.spin then 
        debugLog("❌ Spin remote not available")
        return false, "Spin remote not available"
    end
    
    debugLog("🎲 Attempting to spin: " .. crateName)
    
    local success, response = pcall(function()
        return remotes.spin:InvokeServer(crateName)
    end)
    
    if success then
        debugLog("✅ Spin response for " .. crateName .. ": " .. tostring(response))
        return true, response
    else
        debugLog("❌ Spin error for " .. crateName .. ": " .. tostring(response))
        return false, response
    end
end

-- Update status with color coding
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

-- ENHANCED auto buy function
local function startAutoBuy()
    debugLog("🚀 Starting auto buy with FIXED remotes...")
    
    if not initRemotes() then
        updateStatus("❌ FAILED: Could not connect to game remotes", Color3.fromRGB(255, 0, 0), true)
        return
    end
    
    if #settings.selectedCrates == 0 then
        updateStatus("⚠️ No crates selected", Color3.fromRGB(255, 255, 0))
        return
    end
    
    updateStatus("🎯 REMOTES CONNECTED! Starting purchases...", Color3.fromRGB(0, 255, 0))
    
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
                updateStatus("✅ SUCCESS: Bought " .. crateName, Color3.fromRGB(0, 255, 0))
                
                if settings.autoSpin then
                    wait(0.5)
                    local spinSuccess, spinResponse = spinCrate(crateName)
                    if spinSuccess then
                        updateStatus("🎲 SPUN: " .. crateName, Color3.fromRGB(100, 255, 100))
                    else
                        updateStatus("⚠️ Bought but spin failed: " .. crateName, Color3.fromRGB(255, 255, 0))
                    end
                end
            else
                failedPurchases = failedPurchases + 1
                local errorMsg = "❌ FAILED: " .. crateName
                if purchaseResponse then
                    if type(purchaseResponse) == "string" then
                        errorMsg = errorMsg .. " (" .. purchaseResponse .. ")"
                    elseif type(purchaseResponse) == "table" and purchaseResponse.error then
                        errorMsg = errorMsg .. " (" .. tostring(purchaseResponse.error) .. ")"
                    end
                end
                updateStatus(errorMsg, Color3.fromRGB(255, 0, 0), true)
            end
            
            if purchaseCountLabel then
                purchaseCountLabel.Text = string.format("✅ Success: %d | ❌ Failed: %d | 📊 Total: %d", 
                    successfulPurchases, failedPurchases, totalPurchases)
            end
            
            wait(settings.buyDelay)
        end
    end
    
    local finalMessage = string.format("🏁 COMPLETE! ✅ %d success | ❌ %d failed", successfulPurchases, failedPurchases)
    updateStatus(finalMessage, successfulPurchases > 0 and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 100, 0))
    settings.enabled = false
    updateMainButton()
end

-- Update main button
local function updateMainButton()
    local mainButton = gui and gui:FindFirstChild("MainButton")
    if mainButton then
        mainButton.BackgroundColor3 = settings.enabled and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(0, 200, 100)
        mainButton.Text = settings.enabled and "⏹️ STOP AUTO BUY" or "▶️ START AUTO BUY"
    end
end

-- Create FIXED UI
local function createFixedUI()
    if gui then gui:Destroy() end
    
    -- Main GUI
    gui = Instance.new("ScreenGui")
    gui.Name = "FischFixedUI"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 350, 0, 450)
    mainFrame.Position = UDim2.new(1, -370, 0, 20)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = gui
    
    -- Corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    -- Title with success indicator
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "🎯 FIXED Auto Buy (Paths Corrected!)"
    title.TextColor3 = Color3.fromRGB(0, 255, 100)
    title.TextSize = 14
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
    
    -- Test connection button
    local testBtn = Instance.new("TextButton")
    testBtn.Size = UDim2.new(1, -20, 0, 25)
    testBtn.Position = UDim2.new(0, 10, 0, 85)
    testBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 200)
    testBtn.BorderSizePixel = 0
    testBtn.Text = "🧪 TEST CONNECTION"
    testBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    testBtn.TextSize = 12
    testBtn.Font = Enum.Font.GothamSemibold
    testBtn.Parent = mainFrame
    
    local testBtnCorner = Instance.new("UICorner")
    testBtnCorner.CornerRadius = UDim.new(0, 4)
    testBtnCorner.Parent = testBtn
    
    testBtn.MouseButton1Click:Connect(function()
        updateStatus("🧪 Testing connection with FIXED paths...", Color3.fromRGB(100, 100, 200))
        spawn(function()
            local success = initRemotes()
            if success then
                updateStatus("✅ CONNECTION SUCCESS! Ready to buy crates!", Color3.fromRGB(0, 255, 0))
            else
                updateStatus("❌ CONNECTION FAILED! Check console for details", Color3.fromRGB(255, 0, 0), true)
            end
        end)
    end)
    
    -- Settings frame
    local settingsFrame = Instance.new("Frame")
    settingsFrame.Size = UDim2.new(1, -20, 0, 80)
    settingsFrame.Position = UDim2.new(0, 10, 0, 120)
    settingsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    settingsFrame.BorderSizePixel = 0
    settingsFrame.Parent = mainFrame
    
    local settingsCorner = Instance.new("UICorner")
    settingsCorner.CornerRadius = UDim.new(0, 6)
    settingsCorner.Parent = settingsFrame
    
    -- Max purchases
    local maxLabel = Instance.new("TextLabel")
    maxLabel.Size = UDim2.new(0.6, 0, 0, 25)
    maxLabel.Position = UDim2.new(0, 10, 0, 10)
    maxLabel.BackgroundTransparency = 1
    maxLabel.Text = "Max Purchases:"
    maxLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    maxLabel.TextSize = 12
    maxLabel.Font = Enum.Font.Gotham
    maxLabel.TextXAlignment = Enum.TextXAlignment.Left
    maxLabel.Parent = settingsFrame
    
    local maxBox = Instance.new("TextBox")
    maxBox.Size = UDim2.new(0.35, 0, 0, 25)
    maxBox.Position = UDim2.new(0.65, 0, 0, 10)
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
    
    -- Delay
    local delayLabel = Instance.new("TextLabel")
    delayLabel.Size = UDim2.new(0.6, 0, 0, 25)
    delayLabel.Position = UDim2.new(0, 10, 0, 45)
    delayLabel.BackgroundTransparency = 1
    delayLabel.Text = "Delay (seconds):"
    delayLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    delayLabel.TextSize = 12
    delayLabel.Font = Enum.Font.Gotham
    delayLabel.TextXAlignment = Enum.TextXAlignment.Left
    delayLabel.Parent = settingsFrame
    
    local delayBox = Instance.new("TextBox")
    delayBox.Size = UDim2.new(0.35, 0, 0, 25)
    delayBox.Position = UDim2.new(0.65, 0, 0, 45)
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
    
    -- Auto spin toggle
    local spinToggle = Instance.new("TextButton")
    spinToggle.Size = UDim2.new(1, -20, 0, 25)
    spinToggle.Position = UDim2.new(0, 10, 0, 210)
    spinToggle.BackgroundColor3 = settings.autoSpin and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    spinToggle.BorderSizePixel = 0
    spinToggle.Text = "🎲 Auto Spin: " .. (settings.autoSpin and "ON" or "OFF")
    spinToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    spinToggle.TextSize = 12
    spinToggle.Font = Enum.Font.GothamSemibold
    spinToggle.Parent = mainFrame
    
    local spinToggleCorner = Instance.new("UICorner")
    spinToggleCorner.CornerRadius = UDim.new(0, 4)
    spinToggleCorner.Parent = spinToggle
    
    -- Status section
    local statusFrame = Instance.new("Frame")
    statusFrame.Size = UDim2.new(1, -20, 0, 120)
    statusFrame.Position = UDim2.new(0, 10, 0, 245)
    statusFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    statusFrame.BorderSizePixel = 0
    statusFrame.Parent = mainFrame
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 6)
    statusCorner.Parent = statusFrame
    
    local statusTitle = Instance.new("TextLabel")
    statusTitle.Size = UDim2.new(1, -10, 0, 20)
    statusTitle.Position = UDim2.new(0, 5, 0, 5)
    statusTitle.BackgroundTransparency = 1
    statusTitle.Text = "📊 Status Monitor:"
    statusTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusTitle.TextSize = 12
    statusTitle.Font = Enum.Font.GothamSemibold
    statusTitle.TextXAlignment = Enum.TextXAlignment.Left
    statusTitle.Parent = statusFrame
    
    statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -10, 0, 60)
    statusLabel.Position = UDim2.new(0, 5, 0, 25)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "🎯 READY! Paths have been FIXED from scan results.\nClick TEST CONNECTION first!"
    statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    statusLabel.TextSize = 11
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextYAlignment = Enum.TextYAlignment.Top
    statusLabel.TextWrapped = true
    statusLabel.Parent = statusFrame
    
    purchaseCountLabel = Instance.new("TextLabel")
    purchaseCountLabel.Size = UDim2.new(1, -10, 0, 30)
    purchaseCountLabel.Position = UDim2.new(0, 5, 0, 85)
    purchaseCountLabel.BackgroundTransparency = 1
    purchaseCountLabel.Text = "✅ Success: 0 | ❌ Failed: 0 | 📊 Total: 0"
    purchaseCountLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
    purchaseCountLabel.TextSize = 10
    purchaseCountLabel.Font = Enum.Font.Gotham
    purchaseCountLabel.TextXAlignment = Enum.TextXAlignment.Left
    purchaseCountLabel.Parent = statusFrame
    
    -- Main button with emphasis
    local mainButton = Instance.new("TextButton")
    mainButton.Name = "MainButton"
    mainButton.Size = UDim2.new(1, -20, 0, 45)
    mainButton.Position = UDim2.new(0, 10, 0, 385)
    mainButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    mainButton.BorderSizePixel = 0
    mainButton.Text = "🎯 START FIXED AUTO BUY"
    mainButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    mainButton.TextSize = 16
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
    
    spinToggle.MouseButton1Click:Connect(function()
        settings.autoSpin = not settings.autoSpin
        spinToggle.BackgroundColor3 = settings.autoSpin and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
        spinToggle.Text = "🎲 Auto Spin: " .. (settings.autoSpin and "ON" or "OFF")
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
        Position = UDim2.new(1, -370, 0, 20)
    }):Play()
    
    -- Auto-test connection on load
    wait(1)
    debugLog("Auto-testing connection with FIXED paths...")
    spawn(function()
        initRemotes()
    end)
end

-- Keybind (F5 for fixed version)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F5 then
        if gui and gui.Parent then
            gui:Destroy()
        else
            createFixedUI()
        end
    end
end)

-- Create UI on load
createFixedUI()

-- Global access
_G.FischFixedUI = {
    show = createFixedUI,
    hide = function() if gui then gui:Destroy() end end,
    toggle = function()
        if gui and gui.Parent then
            gui:Destroy()
        else
            createFixedUI()
        end
    end,
    testConnection = initRemotes,
    settings = settings
}

print("🎯 FISCH FIXED AUTO BUY UI LOADED!")
print("✅ Paths corrected from scan results!")
print("🔑 Press F5 to toggle UI")
print("🧪 Use TEST CONNECTION button before buying!")
print("📊 All 15 skin crates supported with proper error handling")
