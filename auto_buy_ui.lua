-- Fisch Auto Buy Skin Crates UI
-- GUI Interface untuk auto buying skin crates

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

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
    selectedCrates = {},
    autoSpin = true,
    currentMoney = 0
}

-- UI Variables
local gui = nil
local mainFrame = nil
local logTextBox = nil

-- Remote references
local remotes = {}

-- Utility Functions
local function createTween(object, properties, duration, style, direction)
    local tweenInfo = TweenInfo.new(
        duration or 0.3,
        style or Enum.EasingStyle.Quad,
        direction or Enum.EasingDirection.Out
    )
    return TweenService:Create(object, tweenInfo, properties)
end

local function addLog(message, color)
    if not logTextBox then return end
    
    local timestamp = os.date("[%H:%M:%S] ")
    local colorCode = color and string.format('<font color="rgb(%d,%d,%d)">', color.R*255, color.G*255, color.B*255) or ""
    local endColor = color and "</font>" or ""
    
    logTextBox.Text = logTextBox.Text .. timestamp .. colorCode .. message .. endColor .. "\n"
    logTextBox.CanvasPosition = Vector2.new(0, logTextBox.TextBounds.Y - logTextBox.AbsoluteSize.Y)
end

-- Initialize remotes
local function initRemotes()
    local success = pcall(function()
        local netPackages = ReplicatedStorage:WaitForChild("packages"):WaitForChild("Net")
        remotes.purchase = netPackages:WaitForChild("RF"):WaitForChild("SkinCrates"):WaitForChild("Purchase")
        remotes.spin = netPackages:WaitForChild("RF"):WaitForChild("SkinCrates"):WaitForChild("RequestSpin")
        remotes.toggle = netPackages:WaitForChild("RE"):WaitForChild("ToggleSkinCrates")
    end)
    return success
end

-- Purchase functions
local function purchaseCrate(crateName)
    if not remotes.purchase then return false end
    
    local success, response = pcall(function()
        return remotes.purchase:InvokeServer(crateName)
    end)
    
    if success then
        addLog("✅ Successfully purchased " .. crateName, Color3.fromRGB(0, 255, 0))
        return true, response
    else
        addLog("❌ Failed to purchase " .. crateName, Color3.fromRGB(255, 0, 0))
        return false, response
    end
end

local function spinCrate(crateName)
    if not remotes.spin then return false end
    
    local success, response = pcall(function()
        return remotes.spin:InvokeServer(crateName)
    end)
    
    if success then
        addLog("🎲 Successfully spun " .. crateName, Color3.fromRGB(0, 150, 255))
        return true, response
    else
        addLog("❌ Failed to spin " .. crateName, Color3.fromRGB(255, 100, 0))
        return false, response
    end
end

-- Auto buy function
local function startAutoBuy()
    if not initRemotes() then
        addLog("❌ Failed to initialize remotes!", Color3.fromRGB(255, 0, 0))
        return
    end
    
    if #settings.selectedCrates == 0 then
        addLog("⚠️ No crates selected!", Color3.fromRGB(255, 255, 0))
        return
    end
    
    addLog("🚀 Starting auto buy for " .. #settings.selectedCrates .. " crates", Color3.fromRGB(0, 255, 255))
    
    for i = 1, settings.maxPurchases do
        if not settings.enabled then break end
        
        addLog("=== Round " .. i .. "/" .. settings.maxPurchases .. " ===", Color3.fromRGB(255, 255, 255))
        
        for _, crateName in ipairs(settings.selectedCrates) do
            if not settings.enabled then break end
            
            local purchaseSuccess = purchaseCrate(crateName)
            
            if purchaseSuccess and settings.autoSpin then
                wait(1)
                spinCrate(crateName)
            end
            
            wait(settings.buyDelay)
        end
        
        if i < settings.maxPurchases then
            wait(2)
        end
    end
    
    addLog("🏁 Auto buy process completed!", Color3.fromRGB(0, 255, 0))
    settings.enabled = false
    updateUI()
end

-- UI Creation
local function createUI()
    -- Cleanup existing GUI
    if gui then gui:Destroy() end
    
    -- Main GUI
    gui = Instance.new("ScreenGui")
    gui.Name = "FischAutoBuyGUI"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui
    
    -- Main Frame
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 600, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -300, 0.5, -250)
    mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = gui
    
    -- Corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- Drop shadow effect
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 6, 1, 6)
    shadow.Position = UDim2.new(0, -3, 0, -3)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.7
    shadow.ZIndex = mainFrame.ZIndex - 1
    shadow.Parent = mainFrame
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 12)
    shadowCorner.Parent = shadow
    
    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    -- Title fix for bottom corners
    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 12)
    titleFix.Position = UDim2.new(0, 0, 1, -12)
    titleFix.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBar
    
    -- Title Text
    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.Size = UDim2.new(1, -100, 1, 0)
    titleText.Position = UDim2.new(0, 15, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "🎯 Fisch Auto Buy Skin Crates"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextSize = 18
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 40, 0, 30)
    closeBtn.Position = UDim2.new(1, -50, 0, 10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = titleBar
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 6)
    closeBtnCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        createTween(mainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3):Play()
        wait(0.3)
        gui:Destroy()
    end)
    
    -- Content Frame
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -20, 1, -70)
    contentFrame.Position = UDim2.new(0, 10, 0, 60)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame
    
    -- Left Panel (Crates Selection)
    local leftPanel = Instance.new("Frame")
    leftPanel.Name = "LeftPanel"
    leftPanel.Size = UDim2.new(0.6, -5, 1, 0)
    leftPanel.Position = UDim2.new(0, 0, 0, 0)
    leftPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    leftPanel.BorderSizePixel = 0
    leftPanel.Parent = contentFrame
    
    local leftCorner = Instance.new("UICorner")
    leftCorner.CornerRadius = UDim.new(0, 8)
    leftCorner.Parent = leftPanel
    
    -- Crates Title
    local cratesTitle = Instance.new("TextLabel")
    cratesTitle.Size = UDim2.new(1, -20, 0, 30)
    cratesTitle.Position = UDim2.new(0, 10, 0, 10)
    cratesTitle.BackgroundTransparency = 1
    cratesTitle.Text = "📦 Select Skin Crates:"
    cratesTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    cratesTitle.TextSize = 14
    cratesTitle.Font = Enum.Font.GothamSemibold
    cratesTitle.TextXAlignment = Enum.TextXAlignment.Left
    cratesTitle.Parent = leftPanel
    
    -- Crates ScrollFrame
    local cratesScroll = Instance.new("ScrollingFrame")
    cratesScroll.Name = "CratesScroll"
    cratesScroll.Size = UDim2.new(1, -20, 1, -50)
    cratesScroll.Position = UDim2.new(0, 10, 0, 40)
    cratesScroll.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    cratesScroll.BorderSizePixel = 0
    cratesScroll.ScrollBarThickness = 6
    cratesScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    cratesScroll.Parent = leftPanel
    
    local cratesScrollCorner = Instance.new("UICorner")
    cratesScrollCorner.CornerRadius = UDim.new(0, 6)
    cratesScrollCorner.Parent = cratesScroll
    
    local cratesLayout = Instance.new("UIListLayout")
    cratesLayout.SortOrder = Enum.SortOrder.LayoutOrder
    cratesLayout.Padding = UDim.new(0, 5)
    cratesLayout.Parent = cratesScroll
    
    -- Right Panel (Controls & Log)
    local rightPanel = Instance.new("Frame")
    rightPanel.Name = "RightPanel"
    rightPanel.Size = UDim2.new(0.4, -5, 1, 0)
    rightPanel.Position = UDim2.new(0.6, 5, 0, 0)
    rightPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    rightPanel.BorderSizePixel = 0
    rightPanel.Parent = contentFrame
    
    local rightCorner = Instance.new("UICorner")
    rightCorner.CornerRadius = UDim.new(0, 8)
    rightCorner.Parent = rightPanel
    
    -- Controls Section
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Name = "ControlsFrame"
    controlsFrame.Size = UDim2.new(1, -20, 0, 200)
    controlsFrame.Position = UDim2.new(0, 10, 0, 10)
    controlsFrame.BackgroundTransparency = 1
    controlsFrame.Parent = rightPanel
    
    -- Controls Title
    local controlsTitle = Instance.new("TextLabel")
    controlsTitle.Size = UDim2.new(1, 0, 0, 25)
    controlsTitle.Position = UDim2.new(0, 0, 0, 0)
    controlsTitle.BackgroundTransparency = 1
    controlsTitle.Text = "⚙️ Controls:"
    controlsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    controlsTitle.TextSize = 14
    controlsTitle.Font = Enum.Font.GothamSemibold
    controlsTitle.TextXAlignment = Enum.TextXAlignment.Left
    controlsTitle.Parent = controlsFrame
    
    -- Max Purchases
    local maxPurchasesLabel = Instance.new("TextLabel")
    maxPurchasesLabel.Size = UDim2.new(1, 0, 0, 20)
    maxPurchasesLabel.Position = UDim2.new(0, 0, 0, 30)
    maxPurchasesLabel.BackgroundTransparency = 1
    maxPurchasesLabel.Text = "Max Purchases:"
    maxPurchasesLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    maxPurchasesLabel.TextSize = 12
    maxPurchasesLabel.Font = Enum.Font.Gotham
    maxPurchasesLabel.TextXAlignment = Enum.TextXAlignment.Left
    maxPurchasesLabel.Parent = controlsFrame
    
    local maxPurchasesBox = Instance.new("TextBox")
    maxPurchasesBox.Size = UDim2.new(1, 0, 0, 25)
    maxPurchasesBox.Position = UDim2.new(0, 0, 0, 50)
    maxPurchasesBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    maxPurchasesBox.BorderSizePixel = 0
    maxPurchasesBox.Text = tostring(settings.maxPurchases)
    maxPurchasesBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    maxPurchasesBox.TextSize = 12
    maxPurchasesBox.Font = Enum.Font.Gotham
    maxPurchasesBox.PlaceholderText = "Enter number..."
    maxPurchasesBox.Parent = controlsFrame
    
    local maxPurchasesBoxCorner = Instance.new("UICorner")
    maxPurchasesBoxCorner.CornerRadius = UDim.new(0, 4)
    maxPurchasesBoxCorner.Parent = maxPurchasesBox
    
    -- Buy Delay
    local buyDelayLabel = Instance.new("TextLabel")
    buyDelayLabel.Size = UDim2.new(1, 0, 0, 20)
    buyDelayLabel.Position = UDim2.new(0, 0, 0, 80)
    buyDelayLabel.BackgroundTransparency = 1
    buyDelayLabel.Text = "Buy Delay (seconds):"
    buyDelayLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    buyDelayLabel.TextSize = 12
    buyDelayLabel.Font = Enum.Font.Gotham
    buyDelayLabel.TextXAlignment = Enum.TextXAlignment.Left
    buyDelayLabel.Parent = controlsFrame
    
    local buyDelayBox = Instance.new("TextBox")
    buyDelayBox.Size = UDim2.new(1, 0, 0, 25)
    buyDelayBox.Position = UDim2.new(0, 0, 0, 100)
    buyDelayBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    buyDelayBox.BorderSizePixel = 0
    buyDelayBox.Text = tostring(settings.buyDelay)
    buyDelayBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    buyDelayBox.TextSize = 12
    buyDelayBox.Font = Enum.Font.Gotham
    buyDelayBox.PlaceholderText = "Delay between buys..."
    buyDelayBox.Parent = controlsFrame
    
    local buyDelayBoxCorner = Instance.new("UICorner")
    buyDelayBoxCorner.CornerRadius = UDim.new(0, 4)
    buyDelayBoxCorner.Parent = buyDelayBox
    
    -- Auto Spin Toggle
    local autoSpinToggle = Instance.new("TextButton")
    autoSpinToggle.Size = UDim2.new(1, 0, 0, 25)
    autoSpinToggle.Position = UDim2.new(0, 0, 0, 130)
    autoSpinToggle.BackgroundColor3 = settings.autoSpin and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    autoSpinToggle.BorderSizePixel = 0
    autoSpinToggle.Text = "🎲 Auto Spin: " .. (settings.autoSpin and "ON" or "OFF")
    autoSpinToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoSpinToggle.TextSize = 12
    autoSpinToggle.Font = Enum.Font.GothamSemibold
    autoSpinToggle.Parent = controlsFrame
    
    local autoSpinToggleCorner = Instance.new("UICorner")
    autoSpinToggleCorner.CornerRadius = UDim.new(0, 4)
    autoSpinToggleCorner.Parent = autoSpinToggle
    
    -- Start/Stop Button
    local startStopBtn = Instance.new("TextButton")
    startStopBtn.Size = UDim2.new(1, 0, 0, 35)
    startStopBtn.Position = UDim2.new(0, 0, 0, 160)
    startStopBtn.BackgroundColor3 = settings.enabled and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(0, 200, 0)
    startStopBtn.BorderSizePixel = 0
    startStopBtn.Text = settings.enabled and "⏹️ STOP AUTO BUY" or "▶️ START AUTO BUY"
    startStopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    startStopBtn.TextSize = 14
    startStopBtn.Font = Enum.Font.GothamBold
    startStopBtn.Parent = controlsFrame
    
    local startStopBtnCorner = Instance.new("UICorner")
    startStopBtnCorner.CornerRadius = UDim.new(0, 6)
    startStopBtnCorner.Parent = startStopBtn
    
    -- Log Section
    local logFrame = Instance.new("Frame")
    logFrame.Name = "LogFrame"
    logFrame.Size = UDim2.new(1, -20, 1, -220)
    logFrame.Position = UDim2.new(0, 10, 0, 210)
    logFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    logFrame.BorderSizePixel = 0
    logFrame.Parent = rightPanel
    
    local logFrameCorner = Instance.new("UICorner")
    logFrameCorner.CornerRadius = UDim.new(0, 6)
    logFrameCorner.Parent = logFrame
    
    -- Log Title
    local logTitle = Instance.new("TextLabel")
    logTitle.Size = UDim2.new(1, -10, 0, 25)
    logTitle.Position = UDim2.new(0, 5, 0, 5)
    logTitle.BackgroundTransparency = 1
    logTitle.Text = "📋 Activity Log:"
    logTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    logTitle.TextSize = 12
    logTitle.Font = Enum.Font.GothamSemibold
    logTitle.TextXAlignment = Enum.TextXAlignment.Left
    logTitle.Parent = logFrame
    
    -- Log TextBox
    logTextBox = Instance.new("TextBox")
    logTextBox.Size = UDim2.new(1, -10, 1, -35)
    logTextBox.Position = UDim2.new(0, 5, 0, 30)
    logTextBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    logTextBox.BorderSizePixel = 0
    logTextBox.Text = ""
    logTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    logTextBox.TextSize = 10
    logTextBox.Font = Enum.Font.Code
    logTextBox.TextXAlignment = Enum.TextXAlignment.Left
    logTextBox.TextYAlignment = Enum.TextYAlignment.Top
    logTextBox.TextWrapped = true
    logTextBox.ClearTextOnFocus = false
    logTextBox.TextEditable = false
    logTextBox.RichText = true
    logTextBox.Parent = logFrame
    
    local logTextBoxCorner = Instance.new("UICorner")
    logTextBoxCorner.CornerRadius = UDim.new(0, 4)
    logTextBoxCorner.Parent = logTextBox
    
    -- Create crate checkboxes
    local function createCrateCheckbox(crateName, index)
        local checkbox = Instance.new("TextButton")
        checkbox.Name = "Checkbox_" .. crateName
        checkbox.Size = UDim2.new(1, -10, 0, 25)
        checkbox.Position = UDim2.new(0, 5, 0, 0)
        checkbox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        checkbox.BorderSizePixel = 0
        checkbox.Text = "☐ " .. crateName
        checkbox.TextColor3 = Color3.fromRGB(200, 200, 200)
        checkbox.TextSize = 11
        checkbox.Font = Enum.Font.Gotham
        checkbox.TextXAlignment = Enum.TextXAlignment.Left
        checkbox.LayoutOrder = index
        checkbox.Parent = cratesScroll
        
        local checkboxCorner = Instance.new("UICorner")
        checkboxCorner.CornerRadius = UDim.new(0, 4)
        checkboxCorner.Parent = checkbox
        
        local isSelected = false
        
        checkbox.MouseButton1Click:Connect(function()
            isSelected = not isSelected
            
            if isSelected then
                checkbox.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
                checkbox.Text = "☑️ " .. crateName
                checkbox.TextColor3 = Color3.fromRGB(255, 255, 255)
                table.insert(settings.selectedCrates, crateName)
            else
                checkbox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                checkbox.Text = "☐ " .. crateName
                checkbox.TextColor3 = Color3.fromRGB(200, 200, 200)
                
                for i, crate in ipairs(settings.selectedCrates) do
                    if crate == crateName then
                        table.remove(settings.selectedCrates, i)
                        break
                    end
                end
            end
        end)
        
        -- Hover effects
        checkbox.MouseEnter:Connect(function()
            if not isSelected then
                createTween(checkbox, {BackgroundColor3 = Color3.fromRGB(70, 70, 70)}, 0.2):Play()
            end
        end)
        
        checkbox.MouseLeave:Connect(function()
            if not isSelected then
                createTween(checkbox, {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}, 0.2):Play()
            end
        end)
    end
    
    -- Create all crate checkboxes
    for i, crateName in ipairs(skinCratesData) do
        createCrateCheckbox(crateName, i)
    end
    
    -- Update canvas size
    cratesScroll.CanvasSize = UDim2.new(0, 0, 0, #skinCratesData * 30)
    
    -- Event handlers
    maxPurchasesBox.FocusLost:Connect(function()
        local value = tonumber(maxPurchasesBox.Text)
        if value and value > 0 then
            settings.maxPurchases = math.floor(value)
            maxPurchasesBox.Text = tostring(settings.maxPurchases)
        else
            maxPurchasesBox.Text = tostring(settings.maxPurchases)
        end
    end)
    
    buyDelayBox.FocusLost:Connect(function()
        local value = tonumber(buyDelayBox.Text)
        if value and value >= 0 then
            settings.buyDelay = value
            buyDelayBox.Text = tostring(settings.buyDelay)
        else
            buyDelayBox.Text = tostring(settings.buyDelay)
        end
    end)
    
    autoSpinToggle.MouseButton1Click:Connect(function()
        settings.autoSpin = not settings.autoSpin
        autoSpinToggle.BackgroundColor3 = settings.autoSpin and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
        autoSpinToggle.Text = "🎲 Auto Spin: " .. (settings.autoSpin and "ON" or "OFF")
    end)
    
    local function updateUI()
        startStopBtn.BackgroundColor3 = settings.enabled and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(0, 200, 0)
        startStopBtn.Text = settings.enabled and "⏹️ STOP AUTO BUY" or "▶️ START AUTO BUY"
    end
    
    startStopBtn.MouseButton1Click:Connect(function()
        settings.enabled = not settings.enabled
        updateUI()
        
        if settings.enabled then
            addLog("🚀 Auto buy started!", Color3.fromRGB(0, 255, 0))
            spawn(startAutoBuy)
        else
            addLog("⏹️ Auto buy stopped!", Color3.fromRGB(255, 100, 0))
        end
    end)
    
    -- Initial log message
    addLog("Welcome to Fisch Auto Buy Skin Crates!", Color3.fromRGB(0, 255, 255))
    addLog("Select crates and configure settings to begin.", Color3.fromRGB(200, 200, 200))
    
    -- Entrance animation
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    createTween(mainFrame, {Size = UDim2.new(0, 600, 0, 500)}, 0.5, Enum.EasingStyle.Back):Play()
end

-- Keybind to toggle UI (F3)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F3 then
        if gui and gui.Parent then
            gui:Destroy()
        else
            createUI()
        end
    end
end)

-- Auto-create UI on load
createUI()

-- Global access
_G.FischAutoBuyUI = {
    show = createUI,
    hide = function()
        if gui then gui:Destroy() end
    end,
    toggle = function()
        if gui and gui.Parent then
            gui:Destroy()
        else
            createUI()
        end
    end
}

print("🎯 Fisch Auto Buy UI Loaded!")
print("Press F3 to toggle UI")
print("Use _G.FischAutoBuyUI.toggle() to toggle programmatically")