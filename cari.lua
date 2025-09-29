-- Fisch Structure Explorer
-- Untuk mencari struktur RemoteFunction/RemoteEvent yang benar

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Function to explore structure
local function exploreStructure(obj, depth, maxDepth)
    depth = depth or 0
    maxDepth = maxDepth or 3
    
    if depth > maxDepth then return end
    
    local indent = string.rep("  ", depth)
    print(indent .. "📁 " .. obj.Name .. " (" .. obj.ClassName .. ")")
    
    -- Look for RemoteFunction and RemoteEvent specifically
    for _, child in ipairs(obj:GetChildren()) do
        if child.ClassName == "RemoteFunction" or child.ClassName == "RemoteEvent" then
            print(indent .. "  🔗 " .. child.Name .. " (" .. child.ClassName .. ")")
        elseif child.ClassName == "Folder" or child.ClassName == "ModuleScript" then
            exploreStructure(child, depth + 1, maxDepth)
        end
    end
end

-- Function to find SkinCrates related remotes
local function findSkinCratesRemotes()
    print("🔍 Searching for SkinCrates remotes...")
    
    local function searchRecursively(obj, path)
        path = path or obj.Name
        
        -- Check if this object has SkinCrates in name
        if string.find(obj.Name:lower(), "skin") or string.find(obj.Name:lower(), "crate") then
            print("🎯 Found potential match: " .. path .. " (" .. obj.ClassName .. ")")
        end
        
        -- Check for Purchase or Spin remotes
        if (string.find(obj.Name:lower(), "purchase") or string.find(obj.Name:lower(), "spin")) and 
           (obj.ClassName == "RemoteFunction" or obj.ClassName == "RemoteEvent") then
            print("💰 Found purchase/spin remote: " .. path .. " (" .. obj.ClassName .. ")")
        end
        
        -- Continue searching in children
        for _, child in ipairs(obj:GetChildren()) do
            searchRecursively(child, path .. "." .. child.Name)
        end
    end
    
    -- Start search from ReplicatedStorage
    if ReplicatedStorage then
        searchRecursively(ReplicatedStorage, "ReplicatedStorage")
    end
end

-- Function to check exact paths from dump.txt
local function checkDumpPaths()
    print("📋 Checking paths from dump.txt...")
    
    local pathsToCheck = {
        "ReplicatedStorage.packages.Net.RF.SkinCrates.Purchase",
        "ReplicatedStorage.packages.Net.RF.SkinCrates.RequestSpin",
        "ReplicatedStorage.packages.Net.RE.ToggleSkinCrates"
    }
    
    for _, path in ipairs(pathsToCheck) do
        local success = pcall(function()
            local parts = path:split(".")
            local current = game
            
            for i, part in ipairs(parts) do
                current = current:WaitForChild(part, 2)
                if not current then
                    error("Failed at: " .. part)
                end
            end
            
            print("✅ Found: " .. path .. " (" .. current.ClassName .. ")")
        end)
        
        if not success then
            print("❌ Missing: " .. path)
        end
    end
end

-- Create simple UI for exploration
local function createExplorerUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "StructureExplorer"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 200)
    frame.Position = UDim2.new(0.5, -150, 0.5, -100)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BorderSizePixel = 0
    frame.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "🔍 Structure Explorer"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    
    local exploreBtn = Instance.new("TextButton")
    exploreBtn.Size = UDim2.new(1, -20, 0, 30)
    exploreBtn.Position = UDim2.new(0, 10, 0, 50)
    exploreBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
    exploreBtn.BorderSizePixel = 0
    exploreBtn.Text = "🔍 Explore ReplicatedStorage"
    exploreBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    exploreBtn.TextSize = 12
    exploreBtn.Font = Enum.Font.GothamSemibold
    exploreBtn.Parent = frame
    
    local exploreCorner = Instance.new("UICorner")
    exploreCorner.CornerRadius = UDim.new(0, 5)
    exploreCorner.Parent = exploreBtn
    
    local searchBtn = Instance.new("TextButton")
    searchBtn.Size = UDim2.new(1, -20, 0, 30)
    searchBtn.Position = UDim2.new(0, 10, 0, 90)
    searchBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
    searchBtn.BorderSizePixel = 0
    searchBtn.Text = "🎯 Find SkinCrates Remotes"
    searchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBtn.TextSize = 12
    searchBtn.Font = Enum.Font.GothamSemibold
    searchBtn.Parent = frame
    
    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 5)
    searchCorner.Parent = searchBtn
    
    local checkBtn = Instance.new("TextButton")
    checkBtn.Size = UDim2.new(1, -20, 0, 30)
    checkBtn.Position = UDim2.new(0, 10, 0, 130)
    checkBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 150)
    checkBtn.BorderSizePixel = 0
    checkBtn.Text = "📋 Check Dump Paths"
    checkBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    checkBtn.TextSize = 12
    checkBtn.Font = Enum.Font.GothamSemibold
    checkBtn.Parent = frame
    
    local checkCorner = Instance.new("UICorner")
    checkCorner.CornerRadius = UDim.new(0, 5)
    checkCorner.Parent = checkBtn
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    closeBtn.Position = UDim2.new(1, -35, 0, 10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 12
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = frame
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 4)
    closeBtnCorner.Parent = closeBtn
    
    -- Event handlers
    exploreBtn.MouseButton1Click:Connect(function()
        print("\n" .. "="*50)
        print("🔍 EXPLORING REPLICATED STORAGE STRUCTURE")
        print("="*50)
        exploreStructure(ReplicatedStorage, 0, 4)
        print("="*50 .. "\n")
    end)
    
    searchBtn.MouseButton1Click:Connect(function()
        print("\n" .. "="*50)
        print("🎯 SEARCHING FOR SKINCRATES REMOTES")
        print("="*50)
        findSkinCratesRemotes()
        print("="*50 .. "\n")
    end)
    
    checkBtn.MouseButton1Click:Connect(function()
        print("\n" .. "="*50)
        print("📋 CHECKING DUMP.TXT PATHS")
        print("="*50)
        checkDumpPaths()
        print("="*50 .. "\n")
    end)
    
    closeBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)
end

-- Create UI
createExplorerUI()

-- Global function
_G.exploreStructure = function()
    exploreStructure(ReplicatedStorage, 0, 5)
end

_G.findSkinCrates = findSkinCratesRemotes
_G.checkPaths = checkDumpPaths

print("🔍 Structure Explorer loaded!")
print("Use the UI or call _G.exploreStructure() in console")
