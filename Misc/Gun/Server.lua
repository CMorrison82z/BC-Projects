local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")

local Tool = script.Parent

local iFastCast = require(game:GetService("ReplicatedStorage").Imported.FastCastRedux)

-- New raycast parameters.
local CastParams = RaycastParams.new()
CastParams.IgnoreWater = true
CastParams.FilterType = Enum.RaycastFilterType.Blacklist
CastParams.FilterDescendantsInstances = {}

local bulletCaster = iFastCast.new()
local castBehavior = iFastCast.newBehavior()
castBehavior.CosmeticBulletContainer = workspace
castBehavior.CosmeticBulletTemplate = Tool.Bullet:Clone() Tool.Bullet:Destroy()
castBehavior.RaycastParams = CastParams
castBehavior.AutoIgnoreContainer = false

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
	Reload = Handle.Reload
}

local RemoteEvent = Tool.RemoteEvent

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

-- Combat Source :

local _lastShot = 0

local function OnActivated(player, mousePoint)
	if Ammo.Value <= 0 then return end
	if (tick() - _lastShot) < Configuration.FireRate.Value then return end
	_lastShot = tick()
	
	Sounds.Fire:Play()
	
	Ammo.Value -= 4
	
	for i = 1, 4 do
		local newCast = bulletCaster:Fire(Muzzle.Position, (mousePoint - Muzzle.Position).Unit, Configuration.BulletSpeed.Value, castBehavior)
		
		wait()
	end
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

Tool.Unequipped:Connect(OnUnequipped)
Tool.Equipped:Connect(OnEquipped)
RemoteEvent.OnServerEvent:Connect(EventHandler)


-- Fast Cast connections : 

bulletCaster.RayHit:Connect(function(cast, raycastResult : RaycastResult)
	local otherPart = raycastResult.Instance

	if otherPart.Name == "Bullet" then return end
	if otherPart:IsDescendantOf(Tool) then return end

	local humanoid : Humanoid = otherPart.Parent:FindFirstChild("Humanoid")

	local _sound = Tool.BulletHit:Clone()
	_sound.Parent = otherPart
	_sound:Play()

	_sound.Ended:Connect(function()
		_sound:Destroy()
	end)

	if not humanoid then return end

	humanoid:TakeDamage(25)
end)

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