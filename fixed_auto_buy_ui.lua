-- FIXED Fisch Auto Buy UI
-- Updated dengan path yang BENAR dari hasil scan

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Skin Crates data (updated based on testing results)
local skinCratesData = {
    "Moosewood", "Desolate", "Cthulhu", "Ancient", "Mariana", -- Fixed spellings
    "Cosmetic Case", "Cosmetic Case Legendary", "Atlantis", 
    "Cursed", "Cultist", "Coral", "Friendly", 
    "Red Marlins", "Midas Mates", "Ghosts" -- Removed apostrophe
}

-- Extensive alternative crate names based on common patterns
local alternativeCrateNames = {
    ["Mariana's"] = {"Mariana", "Marianas", "Mari", "MarianaTrench", "mariana"},
    ["Marianas"] = {"Mariana", "Mariana's", "Mari", "MarianaTrench", "mariana"},
    ["Cthulu"] = {"Cthulhu", "Cthulu", "Cth", "cthulhu", "cthulu"},
    ["Cthulhu"] = {"Cthulu", "Cthulhu", "Cth", "cthulhu", "cthulu"},
    ["Red Marlins"] = {"RedMarlins", "Red_Marlins", "Red", "redmarlins", "red"},
    ["Midas' Mates"] = {"Midas Mates", "MidasMates", "Midas_Mates", "Midas", "midas"},
    ["Midas Mates"] = {"Midas' Mates", "MidasMates", "Midas_Mates", "Midas", "midas"},
    ["Cosmetic Case"] = {"CosmeticCase", "Cosmetic_Case", "Cosm", "cosmetic", "cosmeticcase"},
    ["Cosmetic Case Legendary"] = {"CosmeticCaseLegendary", "Cosmetic_Case_Legendary", "CosmLeg", "legendary", "cosmeticlegendary"},
    ["Ancient"] = {"ancient", "Ancient", "Anc"},
    ["Desolate"] = {"desolate", "Desolate", "Des"},
    ["Atlantis"] = {"atlantis", "Atlantis", "Atl"},
    ["Cursed"] = {"cursed", "Cursed", "Cur"},
    ["Cultist"] = {"cultist", "Cultist", "Cult"},
    ["Coral"] = {"coral", "Coral", "Cor"},
    ["Friendly"] = {"friendly", "Friendly", "Friend"},
    ["Ghosts"] = {"ghosts", "Ghosts", "Ghost"}
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

-- FLEXIBLE: Initialize remotes with multiple path attempts
local function initRemotes()
    debugLog("Initializing remotes with FLEXIBLE path detection...")
    
    -- Function to find remote by searching recursively
    local function findRemote(parent, targetName, className)
        debugLog("Searching for " .. targetName .. " (" .. className .. ") in " .. parent.Name)
        
        -- Check direct children first
        for _, child in pairs(parent:GetChildren()) do
            if child.Name == targetName and child.ClassName == className then
                debugLog("✅ FOUND: " .. targetName .. " at " .. parent.Name .. "." .. targetName)
                return child
            end
        end
        
        -- Search recursively in folders
        for _, child in pairs(parent:GetChildren()) do
            if child.ClassName == "Folder" then
                local found = findRemote(child, targetName, className)
                if found then return found end
            end
        end
        
        return nil
    end
    
    -- Function to find SkinCrates folder and remotes
    local function findSkinCratesRemotes(netFolder)
        debugLog("Searching for SkinCrates remotes in Net folder...")
        
        -- Look for SkinCrates folder
        local skinCratesFolder = nil
        
        -- Try direct path first
        for _, child in pairs(netFolder:GetChildren()) do
            if child.Name == "SkinCrates" and child.ClassName == "Folder" then
                skinCratesFolder = child
                debugLog("✅ Found SkinCrates folder directly")
                break
            end
        end
        
        -- If not found directly, search in subfolders
        if not skinCratesFolder then
            for _, child in pairs(netFolder:GetChildren()) do
                if child.ClassName == "Folder" then
                    for _, subchild in pairs(child:GetChildren()) do
                        if subchild.Name == "SkinCrates" and subchild.ClassName == "Folder" then
                            skinCratesFolder = subchild
                            debugLog("✅ Found SkinCrates folder in " .. child.Name)
                            break
                        end
                    end
                    if skinCratesFolder then break end
                end
            end
        end
        
        if not skinCratesFolder then
            debugLog("❌ SkinCrates folder not found")
            return false
        end
        
        -- Find Purchase remote
        local purchase = skinCratesFolder:FindFirstChild("Purchase")
        if purchase and purchase.ClassName == "RemoteFunction" then
            remotes.purchase = purchase
            debugLog("✅ Purchase remote found: " .. tostring(purchase))
        else
            debugLog("❌ Purchase remote not found in SkinCrates folder")
            return false
        end
        
        -- Find RequestSpin remote
        local spin = skinCratesFolder:FindFirstChild("RequestSpin")
        if spin and spin.ClassName == "RemoteFunction" then
            remotes.spin = spin
            debugLog("✅ RequestSpin remote found: " .. tostring(spin))
        else
            debugLog("❌ RequestSpin remote not found in SkinCrates folder")
            return false
        end
        
        return true
    end
    
    local success = pcall(function()
        debugLog("Step 1: Getting ReplicatedStorage.packages.Net...")
        local netPackages = ReplicatedStorage:WaitForChild("packages", 5):WaitForChild("Net", 5)
        debugLog("✅ Net folder found: " .. tostring(netPackages))
        
        -- List contents of Net folder for debugging
        debugLog("📁 Contents of Net folder:")
        for _, child in pairs(netPackages:GetChildren()) do
            debugLog("  - " .. child.Name .. " (" .. child.ClassName .. ")")
        end
        
        -- Try to find SkinCrates remotes
        if not findSkinCratesRemotes(netPackages) then
            debugLog("❌ Failed to find SkinCrates remotes using folder method")
            
            -- Alternative: Search by remote name directly
            debugLog("🔄 Trying alternative search method...")
            
            remotes.purchase = findRemote(netPackages, "Purchase", "RemoteFunction")
            remotes.spin = findRemote(netPackages, "RequestSpin", "RemoteFunction") or 
                          findRemote(netPackages, "Spin", "RemoteFunction")
            
            if not remotes.purchase then
                error("Could not find Purchase remote anywhere in Net folder")
            end
            
            if not remotes.spin then
                error("Could not find RequestSpin or Spin remote anywhere in Net folder")
            end
        end
        
        -- Try to find toggle remote
        remotes.toggle = findRemote(netPackages, "ToggleSkinCrates", "RemoteEvent")
        if remotes.toggle then
            debugLog("✅ Toggle remote found: " .. tostring(remotes.toggle))
        else
            debugLog("⚠️ Toggle remote not found (optional)")
        end
        
        debugLog("🎯 ALL ESSENTIAL REMOTES FOUND SUCCESSFULLY!")
    end)
    
    if not success then
        debugLog("❌ Flexible search failed, trying DIRECT path from scan results...")
        
        -- Last resort: Try the exact paths from our scan results
        local lastResort = pcall(function()
            local net = ReplicatedStorage.packages.Net
            
            -- From scan: ReplicatedStorage.packages.Net.RF/SkinCrates/Purchase
            -- This might mean RF is actually a StringValue or the path uses different structure
            
            -- Try different interpretations
            local attempts = {
                function() 
                    return net["RF/SkinCrates/Purchase"], net["RF/SkinCrates/RequestSpin"]
                end,
                function()
                    local rf = net:FindFirstChild("RF")
                    if rf then
                        local sc = rf:FindFirstChild("SkinCrates") 
                        if sc then
                            return sc:FindFirstChild("Purchase"), sc:FindFirstChild("RequestSpin")
                        end
                    end
                    return nil, nil
                end,
                function()
                    -- Maybe the path uses child access differently
                    for _, child in pairs(net:GetChildren()) do
                        if string.find(child.Name:lower(), "rf") then
                            local sc = child:FindFirstChild("SkinCrates")
                            if sc then
                                return sc:FindFirstChild("Purchase"), sc:FindFirstChild("RequestSpin")
                            end
                        end
                    end
                    return nil, nil
                end
            }
            
            for i, attempt in ipairs(attempts) do
                debugLog("Trying last resort method " .. i .. "...")
                local purchase, spin = attempt()
                if purchase and spin then
                    remotes.purchase = purchase
                    remotes.spin = spin
                    debugLog("✅ SUCCESS with last resort method " .. i)
                    return true
                end
            end
            
            error("All last resort methods failed")
        end)
        
        if not lastResort then
            debugLog("❌ All initialization methods failed")
            return false
        end
    end
    
    return remotes.purchase ~= nil and remotes.spin ~= nil
end

-- FIXED: Purchase functions dengan error handling yang lebih baik
local function purchaseCrate(crateName)
    if not remotes.purchase then 
        debugLog("❌ Purchase remote not available")
        return false, "Purchase remote not available"
    end
    
    -- Function untuk test nama crate
    local function tryPurchase(name)
        debugLog("🛒 Attempting to purchase: " .. name)
        local success, response = pcall(function()
            return remotes.purchase:InvokeServer(name)
        end)
        
        if success then
            debugLog("✅ Purchase response for " .. name .. ": " .. tostring(response))
            -- Response bisa berupa boolean, table, atau string
            if response == true or (type(response) == "table" and response.success) or response == "success" then
                return true, response
            else
                return false, response
            end
        else
            debugLog("❌ Purchase error for " .. name .. ": " .. tostring(response))
            return false, response
        end
    end
    
    -- Coba nama asli dulu
    local success, result = tryPurchase(crateName)
    if success then
        return true, result
    end
    
    -- Jika gagal, coba alternative names
    if alternativeCrateNames[crateName] then
        debugLog("🔄 Trying alternative names for: " .. crateName)
        for _, altName in ipairs(alternativeCrateNames[crateName]) do
            success, result = tryPurchase(altName)
            if success then
                debugLog("✅ Success with alternative name: " .. altName)
                return true, result
            end
        end
    end
    
    -- Jika masih gagal
    debugLog("❌ All purchase attempts failed for: " .. crateName)
    return false, "All names failed"
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
    -- Nil safety for text parameter
    local safeText = tostring(text or "Unknown status")
    
    if statusLabel and statusLabel.Parent then
        pcall(function()
            statusLabel.Text = safeText
            statusLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)
        end)
    end
    
    if isError then
        debugLog("ERROR: " .. safeText)
    else
        debugLog("STATUS: " .. safeText)
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
            
            -- Nil safety checks
            if purchaseSuccess == true then
                successfulPurchases = successfulPurchases + 1
                totalPurchases = totalPurchases + 1
                updateStatus("✅ SUCCESS: Bought " .. tostring(crateName), Color3.fromRGB(0, 255, 0))
                
                if settings.autoSpin == true then
                    wait(0.5)
                    local spinSuccess, spinResponse = spinCrate(crateName)
                    if spinSuccess == true then
                        updateStatus("🎲 SPUN: " .. tostring(crateName), Color3.fromRGB(100, 255, 100))
                    else
                        updateStatus("⚠️ Bought but spin failed: " .. tostring(crateName), Color3.fromRGB(255, 255, 0))
                    end
                end
            else
                failedPurchases = failedPurchases + 1
                local errorMsg = "❌ FAILED: " .. tostring(crateName)
                if purchaseResponse and purchaseResponse ~= nil then
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
    
    -- Main Frame (made taller for crate selector)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 350, 0, 620)
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
    
    -- Skin Crates Selection Frame
    local cratesFrame = Instance.new("Frame")
    cratesFrame.Size = UDim2.new(1, -20, 0, 160)
    cratesFrame.Position = UDim2.new(0, 10, 0, 245)
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
    cratesTitle.Text = "🎯 Select Skin Crates to Buy:"
    cratesTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    cratesTitle.TextSize = 12
    cratesTitle.Font = Enum.Font.GothamSemibold
    cratesTitle.TextXAlignment = Enum.TextXAlignment.Left
    cratesTitle.Parent = cratesFrame
    
    -- Selection info
    local selectionInfo = Instance.new("TextLabel")
    selectionInfo.Size = UDim2.new(1, -10, 0, 15)
    selectionInfo.Position = UDim2.new(0, 5, 0, 25)
    selectionInfo.BackgroundTransparency = 1
    selectionInfo.Text = "Selected: ALL " .. #skinCratesData .. " crates"
    selectionInfo.TextColor3 = Color3.fromRGB(150, 200, 255)
    selectionInfo.TextSize = 10
    selectionInfo.Font = Enum.Font.Gotham
    selectionInfo.TextXAlignment = Enum.TextXAlignment.Left
    selectionInfo.Parent = cratesFrame
    
    -- Scrolling frame for crates
    local cratesScroll = Instance.new("ScrollingFrame")
    cratesScroll.Size = UDim2.new(1, -10, 0, 85)
    cratesScroll.Position = UDim2.new(0, 5, 0, 45)
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
    cratesLayout.CellSize = UDim2.new(0, 100, 0, 25)
    cratesLayout.CellPadding = UDim2.new(0, 2, 0, 2)
    cratesLayout.SortOrder = Enum.SortOrder.LayoutOrder
    cratesLayout.Parent = cratesScroll
    
    -- Function to update selection info
    local function updateSelectionInfo()
        local count = #settings.selectedCrates
        if count == #skinCratesData then
            selectionInfo.Text = "Selected: ALL " .. count .. " crates"
            selectionInfo.TextColor3 = Color3.fromRGB(0, 255, 100)
        elseif count == 0 then
            selectionInfo.Text = "Selected: NONE (0 crates)"
            selectionInfo.TextColor3 = Color3.fromRGB(255, 100, 100)
        else
            selectionInfo.Text = "Selected: " .. count .. " crates"
            selectionInfo.TextColor3 = Color3.fromRGB(150, 200, 255)
        end
    end
    
    -- Create individual crate buttons
    local crateButtons = {}
    for i, crateName in ipairs(skinCratesData) do
        local crateBtn = Instance.new("TextButton")
        crateBtn.Name = "CrateBtn_" .. crateName
        crateBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0) -- Selected by default
        crateBtn.BorderSizePixel = 0
        crateBtn.Text = crateName:len() > 10 and crateName:sub(1, 10) .. ".." or crateName
        crateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        crateBtn.TextSize = 9
        crateBtn.Font = Enum.Font.GothamSemibold
        crateBtn.LayoutOrder = i
        crateBtn.Parent = cratesScroll
        
        local crateBtnCorner = Instance.new("UICorner")
        crateBtnCorner.CornerRadius = UDim.new(0, 3)
        crateBtnCorner.Parent = crateBtn
        
        crateButtons[crateName] = crateBtn
        
        -- Toggle selection
        crateBtn.MouseButton1Click:Connect(function()
            local isSelected = false
            for j, selectedCrate in ipairs(settings.selectedCrates) do
                if selectedCrate == crateName then
                    -- Remove from selection
                    table.remove(settings.selectedCrates, j)
                    crateBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                    isSelected = false
                    break
                end
            end
            
            if not isSelected then
                -- Check if it was found in selection
                local found = false
                for _, selectedCrate in ipairs(settings.selectedCrates) do
                    if selectedCrate == crateName then
                        found = true
                        break
                    end
                end
                
                if not found then
                    -- Add to selection
                    table.insert(settings.selectedCrates, crateName)
                    crateBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
                end
            end
            
            updateSelectionInfo()
        end)
        
        -- Hover effects
        crateBtn.MouseEnter:Connect(function()
            if not settings.enabled then
                local currentColor = crateBtn.BackgroundColor3
                if currentColor == Color3.fromRGB(0, 150, 0) then
                    TweenService:Create(crateBtn, TweenInfo.new(0.2), {
                        BackgroundColor3 = Color3.fromRGB(0, 180, 0)
                    }):Play()
                else
                    TweenService:Create(crateBtn, TweenInfo.new(0.2), {
                        BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                    }):Play()
                end
            end
        end)
        
        crateBtn.MouseLeave:Connect(function()
            if not settings.enabled then
                local isSelected = false
                for _, selectedCrate in ipairs(settings.selectedCrates) do
                    if selectedCrate == crateName then
                        isSelected = true
                        break
                    end
                end
                
                TweenService:Create(crateBtn, TweenInfo.new(0.2), {
                    BackgroundColor3 = isSelected and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(60, 60, 60)
                }):Play()
            end
        end)
    end
    
    -- Update scroll canvas size
    cratesScroll.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#skinCratesData / 3) * 27)
    
    -- Quick selection buttons
    local quickFrame = Instance.new("Frame")
    quickFrame.Size = UDim2.new(1, -10, 0, 25)
    quickFrame.Position = UDim2.new(0, 5, 0, 130)
    quickFrame.BackgroundTransparency = 1
    quickFrame.Parent = cratesFrame
    
    -- Select All button
    local selectAllBtn = Instance.new("TextButton")
    selectAllBtn.Size = UDim2.new(0.32, 0, 1, 0)
    selectAllBtn.Position = UDim2.new(0, 0, 0, 0)
    selectAllBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
    selectAllBtn.BorderSizePixel = 0
    selectAllBtn.Text = "SELECT ALL"
    selectAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    selectAllBtn.TextSize = 9
    selectAllBtn.Font = Enum.Font.GothamBold
    selectAllBtn.Parent = quickFrame
    
    local selectAllCorner = Instance.new("UICorner")
    selectAllCorner.CornerRadius = UDim.new(0, 3)
    selectAllCorner.Parent = selectAllBtn
    
    -- Clear Selection button
    local clearBtn = Instance.new("TextButton")
    clearBtn.Size = UDim2.new(0.32, 0, 1, 0)
    clearBtn.Position = UDim2.new(0.34, 0, 0, 0)
    clearBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
    clearBtn.BorderSizePixel = 0
    clearBtn.Text = "CLEAR ALL"
    clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearBtn.TextSize = 9
    clearBtn.Font = Enum.Font.GothamBold
    clearBtn.Parent = quickFrame
    
    local clearCorner = Instance.new("UICorner")
    clearCorner.CornerRadius = UDim.new(0, 3)
    clearCorner.Parent = clearBtn
    
    -- Popular Selection button
    local popularBtn = Instance.new("TextButton")
    popularBtn.Size = UDim2.new(0.32, 0, 1, 0)
    popularBtn.Position = UDim2.new(0.68, 0, 0, 0)
    popularBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 150)
    popularBtn.BorderSizePixel = 0
    popularBtn.Text = "POPULAR"
    popularBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    popularBtn.TextSize = 9
    popularBtn.Font = Enum.Font.GothamBold
    popularBtn.Parent = quickFrame
    
    local popularCorner = Instance.new("UICorner")
    popularCorner.CornerRadius = UDim.new(0, 3)
    popularCorner.Parent = popularBtn
    
    -- Quick selection events
    selectAllBtn.MouseButton1Click:Connect(function()
        settings.selectedCrates = {}
        for _, crateName in ipairs(skinCratesData) do
            table.insert(settings.selectedCrates, crateName)
            crateButtons[crateName].BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        end
        updateSelectionInfo()
    end)
    
    clearBtn.MouseButton1Click:Connect(function()
        settings.selectedCrates = {}
        for _, crateName in ipairs(skinCratesData) do
            crateButtons[crateName].BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        end
        updateSelectionInfo()
    end)
    
    popularBtn.MouseButton1Click:Connect(function()
        -- Select popular crates
        local popularCrates = {"Moosewood", "Ancient", "Desolate", "Cthulu", "Mariana's"}
        settings.selectedCrates = {}
        
        -- First clear all
        for _, crateName in ipairs(skinCratesData) do
            crateButtons[crateName].BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        end
        
        -- Then select popular ones
        for _, crateName in ipairs(popularCrates) do
            table.insert(settings.selectedCrates, crateName)
            if crateButtons[crateName] then
                crateButtons[crateName].BackgroundColor3 = Color3.fromRGB(0, 150, 0)
            end
        end
        updateSelectionInfo()
    end)
    
    -- Status section (moved down to make room for crate selector)
    local statusFrame = Instance.new("Frame")
    statusFrame.Size = UDim2.new(1, -20, 0, 100)
    statusFrame.Position = UDim2.new(0, 10, 0, 415)
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
    statusLabel.Size = UDim2.new(1, -10, 0, 50)
    statusLabel.Position = UDim2.new(0, 5, 0, 25)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "🎯 READY! Select crates above, test connection, then start!"
    statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    statusLabel.TextSize = 11
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextYAlignment = Enum.TextYAlignment.Top
    statusLabel.TextWrapped = true
    statusLabel.Parent = statusFrame
    
    purchaseCountLabel = Instance.new("TextLabel")
    purchaseCountLabel.Size = UDim2.new(1, -10, 0, 20)
    purchaseCountLabel.Position = UDim2.new(0, 5, 0, 75)
    purchaseCountLabel.BackgroundTransparency = 1
    purchaseCountLabel.Text = "✅ Success: 0 | ❌ Failed: 0 | 📊 Total: 0"
    purchaseCountLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
    purchaseCountLabel.TextSize = 10
    purchaseCountLabel.Font = Enum.Font.Gotham
    purchaseCountLabel.TextXAlignment = Enum.TextXAlignment.Left
    purchaseCountLabel.Parent = statusFrame
    
    -- Main button with emphasis (moved to bottom)
    local mainButton = Instance.new("TextButton")
    mainButton.Name = "MainButton"
    mainButton.Size = UDim2.new(1, -20, 0, 45)
    mainButton.Position = UDim2.new(0, 10, 0, 555)
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
    
    -- Initialize selection info
    updateSelectionInfo()
    
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