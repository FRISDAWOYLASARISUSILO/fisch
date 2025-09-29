-- Compact Fisch Auto Buy UI
-- Mobile-friendly version

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
    selectedCrates = skinCratesData, -- ALL CRATES! Change back to {"Moosewood", "Ancient"} for selective buying
    autoSpin = true
}

-- UI Variables
local gui = nil
local statusLabel = nil
local purchaseCountLabel = nil

-- Remote references
local remotes = {}

-- Initialize remotes
local function initRemotes()
    local success = pcall(function()
        local netPackages = ReplicatedStorage:WaitForChild("packages"):WaitForChild("Net")
        remotes.purchase = netPackages:WaitForChild("RF"):WaitForChild("SkinCrates"):WaitForChild("Purchase")
        remotes.spin = netPackages:WaitForChild("RF"):WaitForChild("SkinCrates"):WaitForChild("RequestSpin")
    end)
    return success
end

-- Purchase functions
local function purchaseCrate(crateName)
    if not remotes.purchase then return false end
    
    local success, response = pcall(function()
        return remotes.purchase:InvokeServer(crateName)
    end)
    
    return success
end

local function spinCrate(crateName)
    if not remotes.spin then return false end
    
    local success, response = pcall(function()
        return remotes.spin:InvokeServer(crateName)
    end)
    
    return success
end

-- Update status
local function updateStatus(text, color)
    if statusLabel then
        statusLabel.Text = text
        statusLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    end
end

-- Auto buy function
local function startAutoBuy()
    if not initRemotes() then
        updateStatus("❌ Failed to init remotes", Color3.fromRGB(255, 0, 0))
        return
    end
    
    if #settings.selectedCrates == 0 then
        updateStatus("⚠️ No crates selected", Color3.fromRGB(255, 255, 0))
        return
    end
    
    local totalPurchases = 0
    
    for i = 1, settings.maxPurchases do
        if not settings.enabled then break end
        
        for j, crateName in ipairs(settings.selectedCrates) do
            if not settings.enabled then break end
            
            updateStatus(string.format("🛒 Buying %s (%d/%d)", crateName, i, settings.maxPurchases), Color3.fromRGB(0, 255, 255))
            
            local purchaseSuccess = purchaseCrate(crateName)
            
            if purchaseSuccess then
                totalPurchases = totalPurchases + 1
                updateStatus("✅ Bought " .. crateName, Color3.fromRGB(0, 255, 0))
                
                if settings.autoSpin then
                    wait(0.5)
                    spinCrate(crateName)
                    updateStatus("🎲 Spun " .. crateName, Color3.fromRGB(100, 255, 100))
                end
            else
                updateStatus("❌ Failed: " .. crateName, Color3.fromRGB(255, 0, 0))
            end
            
            if purchaseCountLabel then
                purchaseCountLabel.Text = "Purchases: " .. totalPurchases
            end
            
            wait(settings.buyDelay)
        end
    end
    
    updateStatus("🏁 Auto buy completed!", Color3.fromRGB(0, 255, 0))
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

-- Create compact UI
local function createCompactUI()
    if gui then gui:Destroy() end
    
    -- Main GUI
    gui = Instance.new("ScreenGui")
    gui.Name = "FischCompactUI"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 300, 0, 520)
    mainFrame.Position = UDim2.new(1, -320, 0, 20)
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
    title.Text = "🎯 Auto Buy Crates"
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
    
    -- Settings Frame
    local settingsFrame = Instance.new("Frame")
    settingsFrame.Size = UDim2.new(1, -20, 0, 150)
    settingsFrame.Position = UDim2.new(0, 10, 0, 50)
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
    delayLabel.Position = UDim2.new(0, 10, 0, 40)
    delayLabel.BackgroundTransparency = 1
    delayLabel.Text = "Delay (sec):"
    delayLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    delayLabel.TextSize = 12
    delayLabel.Font = Enum.Font.Gotham
    delayLabel.TextXAlignment = Enum.TextXAlignment.Left
    delayLabel.Parent = settingsFrame
    
    local delayBox = Instance.new("TextBox")
    delayBox.Size = UDim2.new(0.35, 0, 0, 25)
    delayBox.Position = UDim2.new(0.65, 0, 0, 40)
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
    spinToggle.Position = UDim2.new(0, 10, 0, 70)
    spinToggle.BackgroundColor3 = settings.autoSpin and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    spinToggle.BorderSizePixel = 0
    spinToggle.Text = "🎲 Auto Spin: " .. (settings.autoSpin and "ON" or "OFF")
    spinToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    spinToggle.TextSize = 12
    spinToggle.Font = Enum.Font.GothamSemibold
    spinToggle.Parent = settingsFrame
    
    local spinToggleCorner = Instance.new("UICorner")
    spinToggleCorner.CornerRadius = UDim.new(0, 4)
    spinToggleCorner.Parent = spinToggle
    
    -- Selected crates display
    local selectedLabel = Instance.new("TextLabel")
    selectedLabel.Size = UDim2.new(1, -20, 0, 45)
    selectedLabel.Position = UDim2.new(0, 10, 0, 100)
    selectedLabel.BackgroundTransparency = 1
    selectedLabel.Text = "Selected: ALL CRATES (" .. #settings.selectedCrates .. ")"
    selectedLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
    selectedLabel.TextSize = 10
    selectedLabel.Font = Enum.Font.Gotham
    selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
    selectedLabel.TextWrapped = true
    selectedLabel.Parent = settingsFrame
    
    -- Individual Crates Selection Frame
    local cratesFrame = Instance.new("Frame")
    cratesFrame.Size = UDim2.new(1, -20, 0, 120)
    cratesFrame.Position = UDim2.new(0, 10, 0, 210)
    cratesFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    cratesFrame.BorderSizePixel = 0
    cratesFrame.Parent = mainFrame
    
    local cratesCorner = Instance.new("UICorner")
    cratesCorner.CornerRadius = UDim.new(0, 6)
    cratesCorner.Parent = cratesFrame
    
    local cratesTitle = Instance.new("TextLabel")
    cratesTitle.Size = UDim2.new(1, 0, 0, 20)
    cratesTitle.Position = UDim2.new(0, 5, 0, 5)
    cratesTitle.BackgroundTransparency = 1
    cratesTitle.Text = "🎯 Individual Crates:"
    cratesTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    cratesTitle.TextSize = 12
    cratesTitle.Font = Enum.Font.GothamSemibold
    cratesTitle.TextXAlignment = Enum.TextXAlignment.Left
    cratesTitle.Parent = cratesFrame
    
    -- Scrolling frame for all crates
    local cratesScroll = Instance.new("ScrollingFrame")
    cratesScroll.Size = UDim2.new(1, -10, 0, 90)
    cratesScroll.Position = UDim2.new(0, 5, 0, 25)
    cratesScroll.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    cratesScroll.BorderSizePixel = 0
    cratesScroll.ScrollBarThickness = 4
    cratesScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    cratesScroll.Parent = cratesFrame
    
    local cratesScrollCorner = Instance.new("UICorner")
    cratesScrollCorner.CornerRadius = UDim.new(0, 4)
    cratesScrollCorner.Parent = cratesScroll
    
    -- Grid layout for crates
    local cratesLayout = Instance.new("UIGridLayout")
    cratesLayout.CellSize = UDim2.new(0, 85, 0, 25)
    cratesLayout.CellPadding = UDim2.new(0, 2, 0, 2)
    cratesLayout.SortOrder = Enum.SortOrder.LayoutOrder
    cratesLayout.Parent = cratesScroll
    
    -- Create individual crate buttons
    for i, crateName in ipairs(skinCratesData) do
        local crateBtn = Instance.new("TextButton")
        crateBtn.Name = "CrateBtn_" .. crateName
        crateBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        crateBtn.BorderSizePixel = 0
        crateBtn.Text = crateName:len() > 8 and crateName:sub(1, 8) .. ".." or crateName
        crateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        crateBtn.TextSize = 8
        crateBtn.Font = Enum.Font.Gotham
        crateBtn.LayoutOrder = i
        crateBtn.Parent = cratesScroll
        
        local crateBtnCorner = Instance.new("UICorner")
        crateBtnCorner.CornerRadius = UDim.new(0, 3)
        crateBtnCorner.Parent = crateBtn
        
        -- Single purchase function
        crateBtn.MouseButton1Click:Connect(function()
            if not settings.enabled then
                -- Highlight selected crate
                crateBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
                wait(0.1)
                crateBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                
                -- Set to single crate and start purchase
                settings.selectedCrates = {crateName}
                selectedLabel.Text = "Buying: " .. crateName
                updateStatus("🛒 Single purchase: " .. crateName, Color3.fromRGB(0, 255, 255))
                
                -- Start single purchase
                spawn(function()
                    if initRemotes() then
                        local success = purchaseCrate(crateName)
                        if success then
                            if settings.autoSpin then
                                wait(0.5)
                                spinCrate(crateName)
                                updateStatus("✅ Bought & spun: " .. crateName, Color3.fromRGB(0, 255, 0))
                            else
                                updateStatus("✅ Bought only: " .. crateName .. " (no spin)", Color3.fromRGB(0, 255, 0))
                            end
                        else
                            updateStatus("❌ Failed to buy: " .. crateName, Color3.fromRGB(255, 0, 0))
                        end
                        selectedLabel.Text = "Selected: ALL CRATES (" .. #skinCratesData .. ")"
                    else
                        updateStatus("❌ Failed to initialize remotes", Color3.fromRGB(255, 0, 0))
                    end
                end)
            else
                updateStatus("⚠️ Stop auto buy first!", Color3.fromRGB(255, 255, 0))
            end
        end)
        
        -- Hover effects
        crateBtn.MouseEnter:Connect(function()
            if not settings.enabled then
                TweenService:Create(crateBtn, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                }):Play()
            end
        end)
        
        crateBtn.MouseLeave:Connect(function()
            if not settings.enabled then
                TweenService:Create(crateBtn, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                }):Play()
            end
        end)
    end
    
    -- Update scroll canvas size
    cratesScroll.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#skinCratesData / 3) * 27)
    
    -- Quick actions frame
    local quickActionsFrame = Instance.new("Frame")
    quickActionsFrame.Size = UDim2.new(1, -10, 0, 25)
    quickActionsFrame.Position = UDim2.new(0, 5, 0, 95)
    quickActionsFrame.BackgroundTransparency = 1
    quickActionsFrame.Parent = cratesFrame
    
    -- Select All button
    local selectAllBtn = Instance.new("TextButton")
    selectAllBtn.Size = UDim2.new(0.3, 0, 1, 0)
    selectAllBtn.Position = UDim2.new(0, 0, 0, 0)
    selectAllBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
    selectAllBtn.BorderSizePixel = 0
    selectAllBtn.Text = "SELECT ALL"
    selectAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    selectAllBtn.TextSize = 9
    selectAllBtn.Font = Enum.Font.GothamBold
    selectAllBtn.Parent = quickActionsFrame
    
    local selectAllCorner = Instance.new("UICorner")
    selectAllCorner.CornerRadius = UDim.new(0, 3)
    selectAllCorner.Parent = selectAllBtn
    
    -- Clear Selection button
    local clearBtn = Instance.new("TextButton")
    clearBtn.Size = UDim2.new(0.3, 0, 1, 0)
    clearBtn.Position = UDim2.new(0.35, 0, 0, 0)
    clearBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
    clearBtn.BorderSizePixel = 0
    clearBtn.Text = "CLEAR"
    clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearBtn.TextSize = 9
    clearBtn.Font = Enum.Font.GothamBold
    clearBtn.Parent = quickActionsFrame
    
    local clearCorner = Instance.new("UICorner")
    clearCorner.CornerRadius = UDim.new(0, 3)
    clearCorner.Parent = clearBtn
    
    -- Manual Spin All button
    local spinAllBtn = Instance.new("TextButton")
    spinAllBtn.Size = UDim2.new(0.3, 0, 1, 0)
    spinAllBtn.Position = UDim2.new(0.7, 0, 0, 0)
    spinAllBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 150)
    spinAllBtn.BorderSizePixel = 0
    spinAllBtn.Text = "SPIN ALL"
    spinAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    spinAllBtn.TextSize = 9
    spinAllBtn.Font = Enum.Font.GothamBold
    spinAllBtn.Parent = quickActionsFrame
    
    local spinAllCorner = Instance.new("UICorner")
    spinAllCorner.CornerRadius = UDim.new(0, 3)
    spinAllCorner.Parent = spinAllBtn
    
    -- Button events
    selectAllBtn.MouseButton1Click:Connect(function()
        settings.selectedCrates = skinCratesData
        selectedLabel.Text = "Selected: ALL CRATES (" .. #skinCratesData .. ")"
    end)
    
    clearBtn.MouseButton1Click:Connect(function()
        settings.selectedCrates = {}
        selectedLabel.Text = "Selected: None"
    end)
    
    spinAllBtn.MouseButton1Click:Connect(function()
        if not settings.enabled then
            updateStatus("🎲 Spinning all crates...", Color3.fromRGB(150, 0, 150))
            spawn(function()
                if initRemotes() then
                    local spinCount = 0
                    for _, crateName in ipairs(skinCratesData) do
                        local success = spinCrate(crateName)
                        if success then
                            spinCount = spinCount + 1
                        end
                        wait(0.5) -- Small delay between spins
                    end
                    updateStatus("🎲 Spun " .. spinCount .. "/" .. #skinCratesData .. " crates", Color3.fromRGB(150, 0, 150))
                else
                    updateStatus("❌ Failed to initialize remotes", Color3.fromRGB(255, 0, 0))
                end
            end)
        else
            updateStatus("⚠️ Stop auto buy first!", Color3.fromRGB(255, 255, 0))
        end
    end)
    
    -- Status section
    local statusFrame = Instance.new("Frame")
    statusFrame.Size = UDim2.new(1, -20, 0, 60)
    statusFrame.Position = UDim2.new(0, 10, 0, 340)
    statusFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    statusFrame.BorderSizePixel = 0
    statusFrame.Parent = mainFrame
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 6)
    statusCorner.Parent = statusFrame
    
    statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -10, 0, 30)
    statusLabel.Position = UDim2.new(0, 5, 0, 5)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Ready to start auto buy"
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLabel.TextSize = 11
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextWrapped = true
    statusLabel.Parent = statusFrame
    
    purchaseCountLabel = Instance.new("TextLabel")
    purchaseCountLabel.Size = UDim2.new(1, -10, 0, 20)
    purchaseCountLabel.Position = UDim2.new(0, 5, 0, 35)
    purchaseCountLabel.BackgroundTransparency = 1
    purchaseCountLabel.Text = "Purchases: 0"
    purchaseCountLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    purchaseCountLabel.TextSize = 10
    purchaseCountLabel.Font = Enum.Font.Gotham
    purchaseCountLabel.TextXAlignment = Enum.TextXAlignment.Left
    purchaseCountLabel.Parent = statusFrame
    
    -- Main button
    local mainButton = Instance.new("TextButton")
    mainButton.Name = "MainButton"
    mainButton.Size = UDim2.new(1, -20, 0, 40)
    mainButton.Position = UDim2.new(0, 10, 0, 470)
    mainButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    mainButton.BorderSizePixel = 0
    mainButton.Text = "▶️ START AUTO BUY"
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
        Position = UDim2.new(1, -320, 0, 20)
    }):Play()
end

-- Keybind (F3)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F3 then
        if gui and gui.Parent then
            gui:Destroy()
        else
            createCompactUI()
        end
    end
end)

-- Create UI on load
createCompactUI()

-- Global access
_G.FischCompactUI = {
    show = createCompactUI,
    hide = function() if gui then gui:Destroy() end end,
    toggle = function()
        if gui and gui.Parent then
            gui:Destroy()
        else
            createCompactUI()
        end
    end
}

print("🎯 Fisch Compact Auto Buy UI Loaded!")
print("Press F3 to toggle UI")
