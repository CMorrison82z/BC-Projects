local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player : Player = game:GetService("Players").LocalPlayer

local mouse = player:GetMouse()
local Camera = workspace.CurrentCamera

local Tool = script.Parent

local Configuration = Tool:WaitForChild("Configuration")
local Ammo = Tool:WaitForChild("Ammo")
local UI = Tool:WaitForChild("UI")

local AmmoString = "%i / %i"

local RemoteEvent = Tool.RemoteEvent

local currentViewModel;

local function OnEquipped()
	-- Play animations
	-- Setup keybinds and UI
	
	ContextActionService:BindAction("Reload", function()
		RemoteEvent:FireServer("Reload")
	end, true, Enum.KeyCode.R)
	
	UI.Ammo.Text = AmmoString:format(Tool.Ammo.Value, Configuration.MaxAmmo.Value)
	
	UI.Parent = player.PlayerGui
	
	player.CameraMode = Enum.CameraMode.LockFirstPerson

	--RunService:BindToRenderStep("GunCamera", 300, function(dt)
	--	if Camera.CameraType ~= Enum.CameraType.Scriptable then
	--		Camera.CameraType = Enum.CameraType.Scriptable
	--	end
		
		
	--end)
end

local function OnUnequipped()
	UI.Parent = Tool
	
	player.CameraMode = Enum.CameraMode.Classic

	--RunService:UnbindFromRenderStep("GunCamera")
end

local _tweenDb = false

local function OnActivated()
	RemoteEvent:FireServer("Activated", mouse.Hit.Position)

	if Ammo.Value <= 0 then
		if _tweenDb then return end
		_tweenDb = true
		
		local _tween = TweenService:Create(UI.Ammo, TweenInfo.new(.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, true), {
			TextColor3 = Color3.new(1,0,0)
		})
		
		_tween:Play()
		
		_tween.Completed:Wait()
		
		_tweenDb = false
	end
	-- Animations, sounds, etc.
end

local function OnAmmoChanged(newValue)
	UI.Ammo.Text = AmmoString:format(newValue,Configuration.MaxAmmo.Value)
end

Tool.Equipped:Connect(OnEquipped)
Tool.Unequipped:Connect(OnUnequipped)
Tool.Activated:Connect(OnActivated) -- Highly advanced students should be aware of the dangers of having many RBXConnections.
Ammo.Changed:Connect(OnAmmoChanged)