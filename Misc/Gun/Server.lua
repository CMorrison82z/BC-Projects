local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")

local Tool = script.Parent

local iFastCast = require(4453855787) -- https://etithespir.it/FastCastAPIDocs/

local bulletCaster = iFastCast.new()
local castBehavior = iFastCast.newBehavior()
castBehavior.CosmeticBulletContainer = workspace
castBehavior.CosmeticBulletTemplate = Tool.Bullet:Clone() Tool.Bullet:Destroy()

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

local function OnEquipped(player)
	-- Remove collision:
	for _, v in ipairs(Tool:GetDescendants()) do
		if not v:IsA("BasePart") then
			v.CanCollide = false
		end
	end
end

local function OnUnEquipped(player)
	-- Add collision:
	for _, v in ipairs(Tool:GetDescendants()) do
		if not v:IsA("BasePart") then
			v.CanCollide = true
		end
	end
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
		bulletCaster:Fire(Muzzle.Position, (mousePoint - Muzzle.Position).Unit, Configuration.BulletSpeed.Value, castBehavior)

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
	Equipped = OnEquipped,
	UnEquipped = OnUnEquipped,
	Activated = OnActivated,
	Reload = OnReload
}

local function EventHandler(player, functionName, ...)
	funcMap[functionName](player, ...)
end


RemoteEvent.OnServerEvent:Connect(EventHandler)


-- Fast Cast connections : 

bulletCaster.RayHit:Connect(function(cast, raycastResult : RaycastResult)
	local otherPart = raycastResult.Instance
	
	if otherPart.Name == "Bullet" then return end
	if otherPart:IsDescendantOf(Tool) then return end

	print(otherPart)

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