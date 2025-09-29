-- Auto Buy Skin Crates Script untuk Fisch
-- Berdasarkan data dari dump.txt

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

-- Daftar Skin Crates berdasarkan data dump.txt
local SKIN_CRATES = {
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

-- Remote Functions/Events dari data dump
local function getRemotes()
    local remotes = {}
    
    -- Mencari remote functions untuk skin crates
    local netFolder = ReplicatedStorage:WaitForChild("packages"):WaitForChild("Net")
    
    -- Purchase skin crate
    remotes.purchase = netFolder:FindFirstChild("RF"):FindFirstChild("SkinCrates"):FindFirstChild("Purchase")
    
    -- Request spin
    remotes.requestSpin = netFolder:FindFirstChild("RF"):FindFirstChild("SkinCrates"):FindFirstChild("RequestSpin")
    
    -- Toggle skin crates UI
    remotes.toggle = netFolder:FindFirstChild("RE"):FindFirstChild("ToggleSkinCrates")
    
    -- Request open skin crates
    remotes.requestOpen = netFolder:FindFirstChild("RF"):FindFirstChild("RequestOpenSkinCrates")
    
    return remotes
end

-- Fungsi untuk mengecek currency player
local function checkCurrency()
    -- Implementasi check currency tergantung struktur data game
    local playerData = player:FindFirstChild("Data")
    if playerData then
        local currency = playerData:FindFirstChild("Currency") or playerData:FindFirstChild("Money") or playerData:FindFirstChild("Cash")
        return currency and currency.Value or 0
    end
    return 0
end

-- Fungsi untuk membeli skin crate
local function buySkinCrate(crateName)
    local remotes = getRemotes()
    
    if not remotes.purchase then
        warn("Purchase remote tidak ditemukan!")
        return false
    end
    
    local success, result = pcall(function()
        return remotes.purchase:InvokeServer(crateName)
    end)
    
    if success then
        print("✅ Berhasil membeli " .. crateName .. " crate!")
        return true
    else
        warn("❌ Gagal membeli " .. crateName .. " crate: " .. tostring(result))
        return false
    end
end

-- Fungsi untuk spin/open crate
local function spinCrate(crateName)
    local remotes = getRemotes()
    
    if not remotes.requestSpin then
        warn("RequestSpin remote tidak ditemukan!")
        return false
    end
    
    local success, result = pcall(function()
        return remotes.requestSpin:InvokeServer(crateName)
    end)
    
    if success then
        print("🎲 Berhasil spin " .. crateName .. " crate!")
        print("Hasil:", HttpService:JSONEncode(result))
        return true
    else
        warn("❌ Gagal spin " .. crateName .. " crate: " .. tostring(result))
        return false
    end
end

-- Main auto buy function
local function autoBuySkinCrates(options)
    options = options or {}
    local targetCrates = options.crates or SKIN_CRATES
    local maxBuys = options.maxBuys or 1
    local delay = options.delay or 2
    local autoSpin = options.autoSpin ~= false -- default true
    
    print("🚀 Memulai auto buy skin crates...")
    print("Target crates:", table.concat(targetCrates, ", "))
    
    for _, crateName in ipairs(targetCrates) do
        for i = 1, maxBuys do
            -- Check currency
            local currentMoney = checkCurrency()
            print("💰 Currency saat ini:", currentMoney)
            
            -- Attempt to buy
            local buySuccess = buySkinCrate(crateName)
            
            if buySuccess then
                wait(1) -- Wait sebelum spin
                
                -- Auto spin jika enabled
                if autoSpin then
                    spinCrate(crateName)
                end
                
                print(string.format("✅ Pembelian %d/%d untuk %s selesai", i, maxBuys, crateName))
            else
                print(string.format("❌ Gagal membeli %s (attempt %d/%d)", crateName, i, maxBuys))
                break -- Skip ke crate berikutnya jika gagal
            end
            
            -- Delay between purchases
            if i < maxBuys then
                print("⏳ Menunggu " .. delay .. " detik...")
                wait(delay)
            end
        end
        
        print("=" .. string.rep("=", 50))
    end
    
    print("🏁 Auto buy skin crates selesai!")
end

-- Fungsi untuk toggle skin crates UI
local function toggleSkinCratesUI()
    local remotes = getRemotes()
    
    if remotes.toggle then
        remotes.toggle:FireServer()
        print("🔄 Toggle skin crates UI")
    end
end

-- Export functions untuk penggunaan
return {
    autoBuy = autoBuySkinCrates,
    buySingle = buySkinCrate,
    spinCrate = spinCrate,
    toggleUI = toggleSkinCratesUI,
    getSkinCrates = function() return SKIN_CRATES end,
    checkMoney = checkCurrency
}

--[[
CONTOH PENGGUNAAN:

-- Load script
local autoBuy = loadstring(game:HttpGet("path/to/this/script.lua"))()

-- Buy semua crates (1x each)
autoBuy.autoBuy()

-- Buy specific crates dengan custom options
autoBuy.autoBuy({
    crates = {"Moosewood", "Ancient", "Atlantis"},
    maxBuys = 5,
    delay = 3,
    autoSpin = true
})

-- Buy single crate
autoBuy.buySingle("Moosewood")

-- Check currency
print("Money:", autoBuy.checkMoney())

-- Toggle UI
autoBuy.toggleUI()
]]