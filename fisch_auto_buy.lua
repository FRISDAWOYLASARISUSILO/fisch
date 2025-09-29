--- AUTO BUY SKIN CRATES SCRIPT
--- Menggunakan data dari dump.txt Fisch
--- Author: Based on game analysis

wait(2) -- Wait for game to load

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Skin Crates data dari dump.txt
local skinCratesData = {
    "Moosewood",
    "Desolate",
    "Cthulu", 
    "Ancient",
    "Mariana's",
    "Cosmetic Case",
    "Cosmetic Case Legendary",
    "Atlantis",
    "Cursed",
    "Cultist",
    "Coral",
    "Friendly",
    "Red Marlins",
    "Midas' Mates",
    "Ghosts"
}

-- Settings
local settings = {
    enabled = false,
    buyDelay = 2,
    maxPurchases = 1,
    selectedCrates = {"Moosewood", "Ancient", "Atlantis"},
    autoSpin = true
}

-- Remote references
local remotes = {}

-- Initialize remotes
local function initRemotes()
    local success = pcall(function()
        local netPackages = ReplicatedStorage:WaitForChild("packages"):WaitForChild("Net")
        
        -- Purchase remote
        remotes.purchase = netPackages:WaitForChild("RF"):WaitForChild("SkinCrates"):WaitForChild("Purchase")
        
        -- Spin remote  
        remotes.spin = netPackages:WaitForChild("RF"):WaitForChild("SkinCrates"):WaitForChild("RequestSpin")
        
        -- Toggle UI remote
        remotes.toggle = netPackages:WaitForChild("RE"):WaitForChild("ToggleSkinCrates")
        
        -- Buy product (general monetization)
        remotes.buyProduct = netPackages:WaitForChild("RE"):WaitForChild("Monetization"):WaitForChild("BuyProduct")
    end)
    
    return success
end

-- Purchase function
local function purchaseCrate(crateName)
    if not remotes.purchase then
        warn("Purchase remote not found!")
        return false
    end
    
    local success, response = pcall(function()
        return remotes.purchase:InvokeServer(crateName)
    end)
    
    if success then
        print("[AUTO BUY] ✅ Successfully purchased " .. crateName)
        return true, response
    else
        warn("[AUTO BUY] ❌ Failed to purchase " .. crateName .. ": " .. tostring(response))
        return false, response
    end
end

-- Spin crate function
local function spinCrate(crateName)
    if not remotes.spin then
        warn("Spin remote not found!")
        return false
    end
    
    local success, response = pcall(function()
        return remotes.spin:InvokeServer(crateName)
    end)
    
    if success then
        print("[AUTO BUY] 🎲 Successfully spun " .. crateName)
        return true, response
    else
        warn("[AUTO BUY] ❌ Failed to spin " .. crateName .. ": " .. tostring(response))
        return false, response
    end
end

-- Main auto buy loop
local function startAutoBuy()
    if not initRemotes() then
        warn("[AUTO BUY] Failed to initialize remotes!")
        return
    end
    
    print("[AUTO BUY] 🚀 Starting auto buy for skin crates...")
    print("[AUTO BUY] Target crates: " .. table.concat(settings.selectedCrates, ", "))
    
    for i = 1, settings.maxPurchases do
        print(string.format("[AUTO BUY] === Round %d/%d ===", i, settings.maxPurchases))
        
        for _, crateName in ipairs(settings.selectedCrates) do
            if not settings.enabled then
                print("[AUTO BUY] ⏹️ Auto buy disabled, stopping...")
                return
            end
            
            -- Purchase attempt
            local purchaseSuccess, purchaseResult = purchaseCrate(crateName)
            
            if purchaseSuccess then
                -- Wait before spinning
                wait(1)
                
                -- Auto spin if enabled
                if settings.autoSpin then
                    local spinSuccess, spinResult = spinCrate(crateName)
                    if spinSuccess then
                        print("[AUTO BUY] 🎁 Spin result for " .. crateName .. ":", spinResult)
                    end
                end
            end
            
            -- Delay between purchases
            wait(settings.buyDelay)
        end
        
        if i < settings.maxPurchases then
            print("[AUTO BUY] ⏳ Waiting before next round...")
            wait(5)
        end
    end
    
    print("[AUTO BUY] 🏁 Auto buy process completed!")
    settings.enabled = false
end

-- Toggle function
local function toggleAutoBuy()
    settings.enabled = not settings.enabled
    
    if settings.enabled then
        print("[AUTO BUY] ▶️ Auto buy ENABLED")
        spawn(startAutoBuy)
    else
        print("[AUTO BUY] ⏹️ Auto buy DISABLED")
    end
end

-- Keybind (F4 to toggle)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F4 then
        toggleAutoBuy()
    elseif input.KeyCode == Enum.KeyCode.F5 then
        -- Toggle skin crates UI
        if remotes.toggle then
            remotes.toggle:FireServer()
            print("[AUTO BUY] 🔄 Toggled skin crates UI")
        end
    end
end)

-- Global functions for manual control
_G.FischAutoBuy = {
    start = function() 
        settings.enabled = true
        spawn(startAutoBuy) 
    end,
    
    stop = function() 
        settings.enabled = false 
    end,
    
    setCrates = function(crateList)
        settings.selectedCrates = crateList
        print("[AUTO BUY] Updated target crates:", table.concat(crateList, ", "))
    end,
    
    setMaxPurchases = function(count)
        settings.maxPurchases = count
        print("[AUTO BUY] Max purchases set to:", count)
    end,
    
    setDelay = function(delay)
        settings.buyDelay = delay
        print("[AUTO BUY] Buy delay set to:", delay, "seconds")
    end,
    
    buyOnce = function(crateName)
        if initRemotes() then
            purchaseCrate(crateName)
            if settings.autoSpin then
                wait(1)
                spinCrate(crateName)
            end
        end
    end,
    
    listCrates = function()
        print("[AUTO BUY] Available crates:", table.concat(skinCratesData, ", "))
    end,
    
    settings = settings
}

-- Initialize
print("=" .. string.rep("=", 60))
print("[AUTO BUY] 🎯 Fisch Auto Buy Skin Crates Loaded!")
print("[AUTO BUY] 📋 Commands:")
print("[AUTO BUY]   F4 = Toggle auto buy")
print("[AUTO BUY]   F5 = Toggle skin crates UI")
print("[AUTO BUY]   _G.FischAutoBuy.start() = Start manual")
print("[AUTO BUY]   _G.FischAutoBuy.stop() = Stop manual")
print("[AUTO BUY]   _G.FischAutoBuy.listCrates() = Show all crates")
print("=" .. string.rep("=", 60))

-- Show current settings
print("[AUTO BUY] 🔧 Current Settings:")
print("[AUTO BUY]   Target Crates:", table.concat(settings.selectedCrates, ", "))
print("[AUTO BUY]   Max Purchases:", settings.maxPurchases)
print("[AUTO BUY]   Buy Delay:", settings.buyDelay, "seconds")
print("[AUTO BUY]   Auto Spin:", settings.autoSpin and "ON" or "OFF")