local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tool = script.Parent

local iFastCast = require(game:GetService("ReplicatedStorage").Imported.FastCastRedux)

local ProjectilesFolder = workspace:WaitForChild("_projectiles", 5)
if not ProjectilesFolder then
	ProjectilesFolder = Instance.new("Folder")
	ProjectilesFolder.Name = "_projectiles"
	ProjectilesFolder.Parent = workspace
end

-- New raycast parameters.
local CastParams = RaycastParams.new()
CastParams.IgnoreWater = true
CastParams.FilterType = Enum.RaycastFilterType.Blacklist
CastParams.FilterDescendantsInstances = {}

local ExplosionParams = OverlapParams.new()

local bulletCaster = iFastCast.new()
local castBehavior = iFastCast.newBehavior()
castBehavior.CosmeticBulletContainer = ProjectilesFolder
castBehavior.CosmeticBulletTemplate = ReplicatedStorage.Projectiles.SciCannon
castBehavior.RaycastParams = CastParams
castBehavior.Acceleration = Vector3.new(0, - workspace.Gravity / 5, 0)
castBehavior.AutoIgnoreContainer = true

local BulletGroup = "Bullets"
PhysicsService:CreateCollisionGroup(BulletGroup)
PhysicsService:CollisionGroupSetCollidable(BulletGroup, BulletGroup, false)


local Handle = Tool.Handle
local Muzzle = Tool.Model.Muzzle

local Configuration = Tool:WaitForChild("Configuration")

local Ammo = Tool.Ammo
Ammo.Value = Configuration.MaxAmmo.Value -- Convenience.

local Sounds = {
	Fire = Handle.Fire,
	FireFail = Handle.FireFail,
	Reload = Handle.Reload
}

local RemoteEvent = Tool.RemoteEvent

-- Combat Source :

local _lastShot = 0

local function OnActivated(player, mousePoint)
	if Ammo.Value <= 0 then Sounds.FireFail:Play() return end
	if (tick() - _lastShot) < Configuration.FireRate.Value then return end
	_lastShot = tick()
	
	Sounds.Fire:Play()
	
	Ammo.Value -= 1
	
	local newCast = bulletCaster:Fire(Muzzle.Position, (mousePoint - Muzzle.Position).Unit, Configuration.ProjectileSpeed.Value, castBehavior)
end

local function OnRayHit(cast, raycastResult : RaycastResult)
	local otherPart = raycastResult.Instance

	if otherPart.Name == "Projectile" then return end
	if otherPart:IsDescendantOf(Tool) then return end

	local _sound = Tool.ProjectileHit:Clone()
	_sound.Parent = otherPart
	_sound:Play()

	_sound.Ended:Connect(function()
		_sound:Destroy()
	end)

	local hitPos = raycastResult.Position
	
	local explosionPart = Instance.new("Part")
	explosionPart.Shape = Enum.PartType.Ball
	explosionPart.Size = Vector3.new(1,1,1)
	explosionPart.Position = hitPos
	explosionPart.CanCollide = false
	explosionPart.Anchored = true
	explosionPart.Color = Color3.new(0,1,1)
	explosionPart.Transparency = .25
	explosionPart.Parent = workspace
	
	local explosionTween = TweenService:Create(explosionPart, TweenInfo.new(.25, Enum.EasingStyle.Linear), {
		Size = Vector3.new(30,30,30),
		Color = Color3.new(),
		Transparency = 1
	})
	
	explosionTween.Completed:Connect(function()
		explosionPart:Destroy()
	end)
	
	explosionTween:Play()
	
	local explosion = Instance.new("Explosion")
	explosion.Position = hitPos
	explosion.Visible = false
	explosion.BlastRadius = 10
	explosion.Parent = workspace
end

-----------------------------------

local isReloading = false

local function OnReload()
	if isReloading then return end
	isReloading = true
	
	Sounds.Reload:Play()
	Sounds.Reload.Ended:Wait()
	
	Ammo.Value = Configuration.MaxAmmo.Value
	
	isReloading = false
end


local funcMap = {
	Activated = OnActivated,
	Reload = OnReload
}

local function EventHandler(player, functionName, ...)
	funcMap[functionName](player, ...)
end

local function OnEquipped()
	-- Remove collision:
	for _, v in ipairs(Tool:GetDescendants()) do
		if v == Handle then continue end

		if v:IsA("BasePart") then
			v.CanCollide = false
		end
	end
end

local function OnUnequipped()
	-- Add collision:
	for _, v : Instance in ipairs(Tool:GetDescendants()) do
		if v == Handle then continue end

		if v:IsA("BasePart") then
			v.CanCollide = true
		end
	end

	Handle.CanTouch = false

	task.delay(1, function()
		Handle.CanTouch = true
	end)
end

Tool.Unequipped:Connect(OnUnequipped)
Tool.Equipped:Connect(OnEquipped)
RemoteEvent.OnServerEvent:Connect(EventHandler)


-- Fast Cast connections : 

bulletCaster.RayHit:Connect(OnRayHit)

bulletCaster.LengthChanged:Connect(function(cast, lastPoint, rayDirection, displacement, _, cosmeticBullet)
	local currentPoint = lastPoint + (rayDirection * displacement)
	
	cosmeticBullet:PivotTo(CFrame.lookAt(currentPoint, currentPoint + rayDirection))
end)

bulletCaster.CastTerminating:Connect(function(cast)
	local cosmeticBullet = cast.RayInfo.CosmeticBulletObject
	
	if cosmeticBullet ~= nil then
		cosmeticBullet:Destroy()
	end
end)