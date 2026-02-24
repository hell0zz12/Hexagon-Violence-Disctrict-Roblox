-- Основные сервисы
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Локальный игрок
local localPlayer = Players.LocalPlayer
local localCharacter = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local localHumanoidRootPart = localCharacter:WaitForChild("HumanoidRootPart")

-- Конфигурация
local CONFIG = {
    -- Настройки для моделей
    Models = {
        Generator = {
            colorRed = Color3.fromRGB(255, 50, 50),      -- Красный (есть части)
            colorGreen = Color3.fromRGB(50, 255, 50),    -- Зеленый (нет частей)
            outlineRed = Color3.fromRGB(255, 100, 100),
            outlineGreen = Color3.fromRGB(100, 255, 100),
            checkParts = true,
            requiredParts = {"GeneratorPoint1", "GeneratorPoint2", "GeneratorPoint3", "GeneratorPoint4"}
        },
        Palletwrong = {
            color = Color3.fromRGB(255, 165, 0),         -- Оранжевый
            outline = Color3.fromRGB(255, 200, 100),
            checkParts = false
        },
        Hook = {
            color = Color3.fromRGB(148, 0, 211),         -- Фиолетовый
            outline = Color3.fromRGB(200, 100, 255),
            checkParts = false
        }
    },
    
    -- Настройки для игроков
    Players = {
        SurvivorColor = Color3.fromRGB(0, 120, 255),     -- Синий для выживших
        KillerColor = Color3.fromRGB(255, 50, 50),       -- Красный для убийцы
        Transparency = 0.60,                             -- Прозрачность
        OutlineTransparency = 0.1,
        
        -- Настройки текста дистанции
        DistanceText = {
            Color = Color3.fromRGB(255, 255, 255),       -- Белый цвет текста
            OutlineColor = Color3.fromRGB(0, 0, 0),      -- Черная обводка
            Size = 20,                                   -- Размер текста
            Offset = Vector3.new(0, 3, 0),               -- Смещение над головой
            Font = Enum.Font.GothamBold                   -- Шрифт
        },
        
        -- Настройки текста HP
        HPText = {
            Color = Color3.fromRGB(0, 255, 0),           -- Зеленый для HP
            OutlineColor = Color3.fromRGB(0, 0, 0),
            Size = 18,
            Offset = Vector3.new(0, 2.2, 0),             -- Смещение под дистанцией
            Font = Enum.Font.GothamBold
        },
        
        -- Настройки текста имени
        NameText = {
            Color = Color3.fromRGB(255, 255, 255),       -- Белый цвет
            OutlineColor = Color3.fromRGB(0, 0, 0),
            Size = 16,
            Offset = Vector3.new(0, 4, 0),               -- Смещение над дистанцией
            Font = Enum.Font.GothamBold
        }
    }
}

-- Кэш для подсветок и текстов
local playerHighlights = {}
local modelHighlights = {}

-- Функция для определения команды игрока
local function getPlayerTeam(player)
    -- Проверяем различные способы определения команды
    if player:FindFirstChild("Team") then
        return player.Team.Value
    elseif player:FindFirstChild("leaderstats") then
        local ls = player.leaderstats
        if ls:FindFirstChild("Team") then
            return ls.Team.Value
        end
    end
    
    -- Проверяем по имени (для примера)
    local playerName = player.Name:lower()
    if playerName:find("killer") or playerName:find("убийца") then
        return "Killer"
    end
    
    -- По умолчанию считаем выжившим
    return "Survivor"
end

-- Функция для подсветки игроков
local function setupPlayerHighlight(player)
    if player == localPlayer then return end
    
    local highlight = Instance.new("Highlight")
    local billboardGui = Instance.new("BillboardGui")
    local distanceText = Instance.new("TextLabel")
    local hpText = Instance.new("TextLabel")
    local nameText = Instance.new("TextLabel")
    
    -- Настройка BillboardGui
    billboardGui.Name = "PlayerInfo"
    billboardGui.Size = UDim2.new(0, 200, 0, 100)
    billboardGui.StudsOffset = Vector3.new(0, 5, 0)
    billboardGui.AlwaysOnTop = true
    billboardGui.MaxDistance = 100
    billboardGui.Enabled = true
    
    -- Настройка текста имени
    nameText.Name = "NameText"
    nameText.Size = UDim2.new(1, 0, 0, 20)
    nameText.Position = UDim2.new(0, 0, 0, 0)
    nameText.BackgroundTransparency = 1
    nameText.TextColor3 = CONFIG.Players.NameText.Color
    nameText.TextStrokeColor3 = CONFIG.Players.NameText.OutlineColor
    nameText.TextStrokeTransparency = 0
    nameText.TextSize = CONFIG.Players.NameText.Size
    nameText.Font = CONFIG.Players.NameText.Font
    nameText.Text = player.Name
    nameText.Parent = billboardGui
    
    -- Настройка текста дистанции
    distanceText.Name = "DistanceText"
    distanceText.Size = UDim2.new(1, 0, 0, 20)
    distanceText.Position = UDim2.new(0, 0, 0, 20)
    distanceText.BackgroundTransparency = 1
    distanceText.TextColor3 = CONFIG.Players.DistanceText.Color
    distanceText.TextStrokeColor3 = CONFIG.Players.DistanceText.OutlineColor
    distanceText.TextStrokeTransparency = 0
    distanceText.TextSize = CONFIG.Players.DistanceText.Size
    distanceText.Font = CONFIG.Players.DistanceText.Font
    distanceText.Text = "0m"
    distanceText.Parent = billboardGui
    
    -- Настройка текста HP
    hpText.Name = "HPText"
    hpText.Size = UDim2.new(1, 0, 0, 18)
    hpText.Position = UDim2.new(0, 0, 0, 40)
    hpText.BackgroundTransparency = 1
    hpText.TextColor3 = CONFIG.Players.HPText.Color
    hpText.TextStrokeColor3 = CONFIG.Players.HPText.OutlineColor
    hpText.TextStrokeTransparency = 0
    hpText.TextSize = CONFIG.Players.HPText.Size
    hpText.Font = CONFIG.Players.HPText.Font
    hpText.Text = "HP: 100"
    hpText.Parent = billboardGui
    
    -- Ждем появления персонажа
    local characterAdded
    characterAdded = player.CharacterAdded:Connect(function(character)
        wait(1) -- Даем время на загрузку
        
        local humanoid = character:WaitForChild("Humanoid", 5)
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
        
        if humanoid and humanoidRootPart then
            -- Настраиваем Highlight
            highlight.Adornee = character
            highlight.FillTransparency = CONFIG.Players.Transparency
            highlight.OutlineTransparency = CONFIG.Players.OutlineTransparency
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            
            -- Определяем команду и цвет
            local team = getPlayerTeam(player)
            if team == "Killer" then
                highlight.FillColor = CONFIG.Players.KillerColor
                highlight.OutlineColor = Color3.fromRGB(255, 100, 100)
                highlight.Name = "KillerHighlight"
            else
                highlight.FillColor = CONFIG.Players.SurvivorColor
                highlight.OutlineColor = Color3.fromRGB(100, 150, 255)
                highlight.Name = "SurvivorHighlight"
            end
            
            highlight.Parent = character
            
            -- Настраиваем BillboardGui
            billboardGui.Adornee = humanoidRootPart
            billboardGui.Parent = character
            
            -- Сохраняем в кэш
            playerHighlights[player] = {
                Highlight = highlight,
                Billboard = billboardGui,
                Character = character,
                Humanoid = humanoid,
                RootPart = humanoidRootPart
            }
            
            print("Подсветка создана для игрока: " .. player.Name .. " (Команда: " .. team .. ")")
        end
    end)
    
    -- Если персонаж уже есть
    if player.Character then
        characterAdded:Disconnect()
        task.spawn(function()
            characterAdded = nil
            local character = player.Character
            wait(0.5)
            
            local humanoid = character:WaitForChild("Humanoid", 3)
            local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 3)
            
            if humanoid and humanoidRootPart then
                -- Настраиваем Highlight
                highlight.Adornee = character
                highlight.FillTransparency = CONFIG.Players.Transparency
                highlight.OutlineTransparency = CONFIG.Players.OutlineTransparency
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                
                local team = getPlayerTeam(player)
                if team == "Killer" then
                    highlight.FillColor = CONFIG.Players.KillerColor
                    highlight.OutlineColor = Color3.fromRGB(255, 100, 100)
                    highlight.Name = "KillerHighlight"
                else
                    highlight.FillColor = CONFIG.Players.SurvivorColor
                    highlight.OutlineColor = Color3.fromRGB(100, 150, 255)
                    highlight.Name = "SurvivorHighlight"
                end
                
                highlight.Parent = character
                
                -- Настраиваем BillboardGui
                billboardGui.Adornee = humanoidRootPart
                billboardGui.Parent = character
                
                -- Сохраняем в кэш
                playerHighlights[player] = {
                    Highlight = highlight,
                    Billboard = billboardGui,
                    Character = character,
                    Humanoid = humanoid,
                    RootPart = humanoidRootPart
                }
                
                print("Подсветка создана для игрока: " .. player.Name .. " (Команда: " .. team .. ")")
            end
        end)
    end
    
    -- Обработка удаления персонажа
    player.CharacterRemoving:Connect(function()
        if playerHighlights[player] then
            playerHighlights[player].Highlight:Destroy()
            playerHighlights[player].Billboard:Destroy()
            playerHighlights[player] = nil
        end
    end)
    
    -- Обработка выхода игрока
    player.AncestryChanged:Connect(function()
        if not player:IsDescendantOf(game) then
            if playerHighlights[player] then
                playerHighlights[player].Highlight:Destroy()
                playerHighlights[player].Billboard:Destroy()
                playerHighlights[player] = nil
            end
        end
    end)
end

-- Функция для обновления текстов игроков
local function updatePlayerTexts()
    if not localHumanoidRootPart then return end
    
    for player, data in pairs(playerHighlights) do
        if data.RootPart and data.Humanoid and data.Billboard then
            -- Обновляем дистанцию
            local distance = (localHumanoidRootPart.Position - data.RootPart.Position).Magnitude
            local distanceText = data.Billboard:FindFirstChild("DistanceText")
            if distanceText then
                distanceText.Text = string.format("%.1fm", distance)
                
                -- Меняем цвет дистанции в зависимости от расстояния
                if distance < 10 then
                    distanceText.TextColor3 = Color3.fromRGB(255, 50, 50)  -- Красный при близком расстоянии
                elseif distance < 30 then
                    distanceText.TextColor3 = Color3.fromRGB(255, 165, 0)  -- Оранжевый
                else
                    distanceText.TextColor3 = Color3.fromRGB(255, 255, 255) -- Белый
                end
            end
            
            -- Обновляем HP
            local hpText = data.Billboard:FindFirstChild("HPText")
            if hpText then
                local health = data.Humanoid.Health
                local maxHealth = data.Humanoid.MaxHealth
                hpText.Text = string.format("HP: %d/%d", math.floor(health), math.floor(maxHealth))
                
                -- Меняем цвет HP в зависимости от здоровья
                local healthPercent = health / maxHealth
                if healthPercent > 0.6 then
                    hpText.TextColor3 = Color3.fromRGB(0, 255, 0)      -- Зеленый
                elseif healthPercent > 0.3 then
                    hpText.TextColor3 = Color3.fromRGB(255, 165, 0)   -- Оранжевый
                else
                    hpText.TextColor3 = Color3.fromRGB(255, 50, 50)   -- Красный
                end
            end
            
            -- Обновляем имя (команда)
            local nameText = data.Billboard:FindFirstChild("NameText")
            if nameText then
                local team = getPlayerTeam(player)
                nameText.Text = player.Name .. " [" .. team .. "]"
            end
        end
    end
end

-- Функция для инициализации подсветки игроков
local function initializePlayerHighlights()
    print("Инициализация подсветки игроков...")
    
    -- Удаляем старые подсветки
    for player, data in pairs(playerHighlights) do
        if data.Highlight then data.Highlight:Destroy() end
        if data.Billboard then data.Billboard:Destroy() end
    end
    playerHighlights = {}
    
    -- Создаем подсветки для существующих игроков
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            setupPlayerHighlight(player)
        end
    end
    
    -- Обработка новых игроков
    Players.PlayerAdded:Connect(function(player)
        wait(1)
        if player ~= localPlayer then
            setupPlayerHighlight(player)
        end
    end)
    
    -- Запускаем обновление текстов
    RunService.RenderStepped:Connect(updatePlayerTexts)
    
    print("Подсветка игроков инициализирована")
end

-- Функция для подсветки моделей (из предыдущего скрипта)
local function highlightModels()
    local mapFolder = Workspace:FindFirstChild("Map")
    
    if not mapFolder then
        warn("Папка 'Map' не найдена в Workspace!")
        return
    end
    
    local stats = {GeneratorRed = 0, GeneratorGreen = 0, Palletwrong = 0, Hook = 0}
    
    local function findModels(parent)
        local foundModels = {}
        
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("Model") and CONFIG.Models[child.Name] then
                table.insert(foundModels, child)
            end
            
            if #child:GetChildren() > 0 then
                local nestedModels = findModels(child)
                for _, model in ipairs(nestedModels) do
                    table.insert(foundModels, model)
                end
            end
        end
        
        return foundModels
    end
    
    local allModels = findModels(mapFolder)
    
    for _, model in ipairs(allModels) do
        local modelConfig = CONFIG.Models[model.Name]
        
        if modelConfig then
            local finalColor, finalOutline, highlightName
            
            if model.Name == "Generator" and modelConfig.checkParts then
                local hasRequiredPart = false
                
                for _, partName in ipairs(modelConfig.requiredParts) do
                    local foundPart = model:FindFirstChild(partName, true)
                    if foundPart and foundPart:IsA("BasePart") then
                        hasRequiredPart = true
                        break
                    end
                end
                
                if hasRequiredPart then
                    finalColor = modelConfig.colorRed
                    finalOutline = modelConfig.outlineRed
                    highlightName = "GeneratorHighlightRed"
                    stats.GeneratorRed = stats.GeneratorRed + 1
                else
                    finalColor = modelConfig.colorGreen
                    finalOutline = modelConfig.outlineGreen
                    highlightName = "GeneratorHighlightGreen"
                    stats.GeneratorGreen = stats.GeneratorGreen + 1
                end
            else
                finalColor = modelConfig.color
                finalOutline = modelConfig.outline
                highlightName = model.Name .. "Highlight"
                
                if model.Name == "Palletwrong" then
                    stats.Palletwrong = stats.Palletwrong + 1
                elseif model.Name == "Hook" then
                    stats.Hook = stats.Hook + 1
                end
            end
            
            local highlight = model:FindFirstChildOfClass("Highlight")
            
            if not highlight then
                highlight = Instance.new("Highlight")
                highlight.Parent = model
            end
            
            highlight.FillColor = finalColor
            highlight.OutlineColor = finalOutline
            highlight.FillTransparency = 0.80
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Name = highlightName
            
            -- Сохраняем в кэш
            modelHighlights[model] = highlight
        end
    end
    
    print("\n📊 МОДЕЛИ:")
    print("─────────────────────────────────────")
    print("🔴 Generator (красные): " .. stats.GeneratorRed)
    print("🟢 Generator (зеленые): " .. stats.GeneratorGreen)
    print("🟠 Palletwrong: " .. stats.Palletwrong)
    print("🟣 Hook: " .. stats.Hook)
    print("Всего моделей: " .. #allModels)
    
    return allModels
end

-- Функция для очистки всех подсветок
local function clearAllHighlights()
    -- Очищаем подсветки игроков
    for player, data in pairs(playerHighlights) do
        if data.Highlight then data.Highlight:Destroy() end
        if data.Billboard then data.Billboard:Destroy() end
    end
    playerHighlights = {}
    
    -- Очищаем подсветки моделей
    for model, highlight in pairs(modelHighlights) do
        if highlight then highlight:Destroy() end
    end
    modelHighlights = {}
    
    print("Все подсветки удалены")
end

-- Функция для переключения видимости подсветки игроков
local function togglePlayerHighlights(visible)
    for player, data in pairs(playerHighlights) do
        if data.Highlight then
            data.Highlight.Enabled = visible
        end
        if data.Billboard then
            data.Billboard.Enabled = visible
        end
    end
    print("Подсветка игроков: " .. (visible and "ВКЛ" or "ВЫКЛ"))
end

-- Функция для переключения видимости подсветки моделей
local function toggleModelHighlights(visible)
    for model, highlight in pairs(modelHighlights) do
        if highlight then
            highlight.Enabled = visible
        end
    end
    print("Подсветка моделей: " .. (visible and "ВКЛ" or "ВЫКЛ"))
end

-- Основная инициализация
local function initialize()
    print("\n" .. string.rep("=", 70))
    print("СИСТЕМА ПОДСВЕТКИ V2.0")
    print(string.rep("-", 70))
    print("👤 ИГРОКИ:")
    print("   Выжившие (Survivors): 🔵 СИНИЙ, прозрачность 60%")
    print("   Убийца (Killer): 🔴 КРАСНЫЙ, прозрачность 60%")
    print("   Отображается: Имя, дистанция, HP")
    print(string.rep("-", 70))
    print("🏗️ МОДЕЛИ:")
    print("   Generator: 🔴/🟢 (красный/зеленый в зависимости от частей)")
    print("   Palletwrong: 🟠 ОРАНЖЕВЫЙ")
    print("   Hook: 🟣 ФИОЛЕТОВЫЙ")
    print(string.rep("=", 70))
    
    -- Ждем загрузки локального игрока
    localPlayer.CharacterAdded:Connect(function(character)
        wait(1)
        localHumanoidRootPart = character:WaitForChild("HumanoidRootPart")
    end)
    
    -- Инициализируем подсветку игроков
    initializePlayerHighlights()
    
    -- Инициализируем подсветку моделей
    highlightModels()
    
    -- Команды чата
    localPlayer.Chatted:Connect(function(message)
        message = message:lower()
        
        if message == "/highlight" then
            highlightModels()
            localPlayer:Chat("✅ Модели подсвечены!")
            
        elseif message == "/players" then
            initializePlayerHighlights()
            localPlayer:Chat("✅ Подсветка игроков обновлена!")
            
        elseif message == "/clear" then
            clearAllHighlights()
            localPlayer:Chat("✅ Все подсветки удалены!")
            
        elseif message == "/toggle players" then
            togglePlayerHighlights(not (playerHighlights[next(playerHighlights)] and 
                playerHighlights[next(playerHighlights)].Highlight.Enabled))
            
        elseif message == "/toggle models" then
            toggleModelHighlights(not (modelHighlights[next(modelHighlights)] and 
                modelHighlights[next(modelHighlights)].Enabled))
            
        elseif message == "/status" then
            local playerCount = 0
            for _ in pairs(playerHighlights) do playerCount = playerCount + 1 end
            
            local modelCount = 0
            for _ in pairs(modelHighlights) do modelCount = modelCount + 1 end
            
            localPlayer:Chat(string.format("📊 Статус: %d игроков, %d моделей", playerCount, modelCount))
            
        elseif message == "/help" then
            localPlayer:Chat("📋 Команды:")
            localPlayer:Chat("/highlight - подсветить модели")
            localPlayer:Chat("/players - обновить подсветку игроков")
            localPlayer:Chat("/clear - удалить все подсветки")
            localPlayer:Chat("/toggle players - вкл/выкл игроков")
            localPlayer:Chat("/toggle models - вкл/выкл модели")
            localPlayer:Chat("/status - показать статус")
        end
    end)
    
    print("\n✅ Система инициализирована!")
    print("📝 Используйте /help для списка команд")
end

-- Запускаем инициализацию с задержкой
wait(2)
initialize()
