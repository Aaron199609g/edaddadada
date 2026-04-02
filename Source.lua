-- ================================================
-- SCRIPT PARA ROBLOX STUDIO - Luau (Sistema COMPLETO)
-- Autor: Grok (programación Roblox Studio)
-- Descripción: Ahora TODO EL MUNDO ve:
--   • El aura blanca cuando seleccionas con CLICK DERECHO
--   • Cuando los bloques se mueven y forman el coche
-- Todo se controla en el SERVIDOR para que sea visible en todo el mundo.
-- ================================================

-- === PASO 1: Crea el RemoteEvent (obligatorio) ===
-- 1. Ve a ReplicatedStorage
-- 2. Insert Object → RemoteEvent
-- 3. Renómbralo exactamente a: "BloquesControlEvent"

-- === PASO 2: Crea el Script del SERVIDOR ===
-- 1. Ve a ServerScriptService
-- 2. Insert Object → Script (NO LocalScript)
-- 3. Renómbralo a: "ControlBloquesServer"
-- 4. Borra todo y pega este código:

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local event = ReplicatedStorage:WaitForChild("BloquesControlEvent")

local CAR_OFFSETS = {
	CFrame.new(0, 3, 0),      -- chasis
	CFrame.new(0, 7, -3),     -- techo
	CFrame.new(-8, 1, 8),     -- rueda DL
	CFrame.new(8, 1, 8),      -- rueda DR
	CFrame.new(-8, 1, -8),    -- rueda TL
	CFrame.new(8, 1, -8),     -- rueda TR
	CFrame.new(0, 5, -13),    -- spoiler
}

local function crearFormaDeCoche(partes, posicionCoche)
	local modeloCoche = Instance.new("Model")
	modeloCoche.Name = "CocheCreadoPorBloques"
	modeloCoche.Parent = workspace
	
	local partePrincipal = nil
	for i, parte in ipairs(partes) do
		parte.Parent = modeloCoche
		if not partePrincipal then partePrincipal = parte end
		
		local offset = CAR_OFFSETS[i] or CFrame.new((i - 7) * 6, 2, 0)
		parte.CFrame = posicionCoche * offset
		
		if i >= 3 and i <= 6 then
			parte.Orientation = Vector3.new(0, 90, 0)
		end
	end
	modeloCoche.PrimaryPart = partePrincipal
	print("✅ Coche formado en el servidor (visible para TODO el mundo)")
end

local function seleccionarTodosLosBloques(player)
	local bloques = {}
	local cantidad = 0
	
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") 
			and not obj.Anchored 
			and obj.CanCollide 
			and not obj:IsDescendantOf(player.Character or Instance.new("Model"))
			and not obj:FindFirstChild("AuraBlancaSeleccion") then
			
			local highlight = Instance.new("Highlight")
			highlight.Name = "AuraBlancaSeleccion"
			highlight.Adornee = obj
			highlight.FillColor = Color3.fromRGB(255, 255, 255)
			highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
			highlight.FillTransparency = 0.75
			highlight.OutlineTransparency = 0.1
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.Parent = obj
			
			table.insert(bloques, obj)
			cantidad = cantidad + 1
		end
	end
	
	print(player.Name .. " seleccionó " .. cantidad .. " bloques con aura (visible para TODO el mundo)")
	return bloques
end

local function atraerBloquesYCrearCoche(player)
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end
	
	local root = character.HumanoidRootPart
	local posicionJugador = root.CFrame
	
	-- Recolectar bloques
	local bloques = {}
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") 
			and not obj.Anchored 
			and obj.CanCollide 
			and not obj:IsDescendantOf(character) then
			
			obj.Anchored = false
			table.insert(bloques, obj)
		end
	end
	
	if #bloques == 0 then return end
	
	print("🚀 " .. player.Name .. " está atrayendo " .. #bloques .. " bloques (visible para TODO el mundo)")
	
	-- Atracción suave (en servidor = todos ven el movimiento)
	local tweens = {}
	local puntoAtraccion = posicionJugador * CFrame.new(0, 8, 20)
	
	for i, bloque in ipairs(bloques) do
		local offsetAleatorio = Vector3.new(math.random(-12,12), math.random(3,12), math.random(-12,12))
		local targetCFrame = puntoAtraccion * CFrame.new(offsetAleatorio)
		
		local tweenInfo = TweenInfo.new(1.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		local tween = TweenService:Create(bloque, tweenInfo, {CFrame = targetCFrame})
		tween:Play()
		table.insert(tweens, tween)
	end
	
	task.wait(2)
	
	-- Formar coche en el servidor
	local posicionFinalCoche = posicionJugador * CFrame.new(0, 5, 30)
	crearFormaDeCoche(bloques, posicionFinalCoche)
end

-- Recibir órdenes del cliente
event.OnServerEvent:Connect(function(player, accion)
	if accion == "SeleccionarAura" then
		seleccionarTodosLosBloques(player)
	elseif accion == "AtraerYFormarCoche" then
		atraerBloquesYCrearCoche(player)
	end
end)

print("✅ Servidor listo: auras y movimientos visibles para TODO EL MUNDO")
