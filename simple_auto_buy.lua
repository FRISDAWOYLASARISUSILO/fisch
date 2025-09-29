-- Simple Auto Buy Skin Crates Script
-- Berdasarkan analisis data Fisch

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Configuration
local CONFIG = {
    DELAY_BETWEEN_BUYS = 2, -- detik
    MAX_RETRIES = 3,
    AUTO_SPIN = true,
    TARGET_CRATES = {
        "Moosewood",
        "Ancient", 
        "Atlantis",
        "Cursed",
        "Friendly"
    }
}

-- Get remotes
local function getRemotes()
    local success, remotes = pcall(function()
        local netFolder = ReplicatedStorage.packages.Net
        return {
            purchase = netFolder.RF.SkinCrates.Purchase,
            spin = netFolder.RF.SkinCrates.RequestSpin,
            toggle = netFolder.RE.ToggleSkinCrates
        }
    end)
    
    return success and remotes or nil
end

-- Main auto buy function
local function startAutoBuy(crateList, buyCount)
    local remotes = getRemotes()
    if not remotes then
        warn("❌ Tidak dapat menemukan remotes!")
        return
    end
    
    buyCount = buyCount or 1
    crateList = crateList or CONFIG.TARGET_CRATES
    
    print("🎯 Starting auto buy untuk", #crateList, "crates")
    
    for _, crateName in ipairs(crateList) do
        for i = 1, buyCount do
            print(string.format("🛒 Membeli %s (%d/%d)...", crateName, i, buyCount))
            
            -- Purchase attempt
            local success, result = pcall(function()
                return remotes.purchase:InvokeServer(crateName)
            end)
            
            if success and result then
                print("✅ Berhasil beli", crateName)
                
                -- Auto spin if enabled
                if CONFIG.AUTO_SPIN then
                    wait(0.5)
                    local spinSuccess = pcall(function()
                        return remotes.spin:InvokeServer(crateName) 
                    end)
                    
                    if spinSuccess then
                        print("🎲 Spin", crateName, "berhasil!")
                    end
                end
            else
                warn("❌ Gagal beli", crateName, ":", tostring(result))
            end
            
            -- Delay
            if i < buyCount then
                wait(CONFIG.DELAY_BETWEEN_BUYS)
            end
        end
    end
    
    print("🏁 Auto buy selesai!")
end

-- Quick functions
_G.buyAll = function(count) startAutoBuy(nil, count) end
_G.buySpecific = function(crates, count) startAutoBuy(crates, count) end
_G.toggleCrates = function()
    local remotes = getRemotes()
    if remotes then remotes.toggle:FireServer() end
end

-- Start auto buy
print("🚀 Auto Buy Skin Crates loaded!")
print("Commands:")
print("  _G.buyAll(5) -- Buy all crates 5x each")
print("  _G.buySpecific({'Moosewood', 'Ancient'}, 3) -- Buy specific crates")
print("  _G.toggleCrates() -- Toggle UI")

-- Auto start (uncomment to enable)
-- startAutoBuy({"Moosewood", "Ancient"}, 1)