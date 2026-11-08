# ⚡ Luau Systems & Gameplay Engineering Showcase

> **Developer Verification**  
> **Discord:** `canesberg`  
> **Roblox Profile:** [Roblox Account](https://www.roblox.com/users/10954384872/profile)  
> **Primary Discipline:** Advanced Luau Gameplay, Procedural Kinematics & Modular Architecture

---

## 🛠 Architectural Overview

This repository and its companion showcase place demonstrate practical implementations of core engineering principles in Roblox Studio, built strictly without third-party frameworks to highlight raw language mastery:

1. **Procedural Kinematics & Spring Physics (`SpringUtility`):**
   - Second-order dynamic damping models simulating mass, tension, and velocity decay.
   - Real-time procedural floating, rotation matrices, and elastic disruption impulses.

2. **Trajectory Mathematics (`BezierCurve`):**
   - High-performance quadratic and cubic Bézier interpolation for smooth, deterministic projectile paths.
   - Client-side rendering with server reconciliation and dynamic impact bursts.

3. **Spatial Wave Dynamics (`RadialPulseSystem`):**
   - Distance-attenuated grid ripple propagation.
   - Dynamic sine-wave vertical offset and color transitions using TweenService.

4. **Object-Oriented Programming (OOP):**
   - Metatable-driven state management with static type safety (`--!strict`).
   - Clean lifecycle teardown (`:Destroy()`) to prevent memory leaks across game sessions.

---

## 💻 Core Engine Implementation (`ShowcaseCore.luau`)

```luau
--!strict
-- Discord: canesberg | UserID: 10954384872
-- Architecture: Systems & Kinematics Showcase Core Engine

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local ShowcaseEngine = {}
ShowcaseEngine.__index = ShowcaseEngine

--------------------------------------------------------------------------------
-- 1. MATHEMATICAL SPRING UTILITY (Damped Harmonic Oscillator)
--------------------------------------------------------------------------------

export type Spring = {
	Target: Vector3,
	Position: Vector3,
	Velocity: Vector3,
	Mass: number,
	Force: number,
	Damping: number,
	Speed: number,
	Update: (self: Spring, dt: number) -> Vector3,
	Impulse: (self: Spring, force: Vector3) -> (),
	Reset: (self: Spring, pos: Vector3) -> ()
}

local SpringUtility = {}
SpringUtility.__index = SpringUtility

function SpringUtility.new(initialPosition: Vector3, mass: number?, force: number?, damping: number?, speed: number?): Spring
	local self = setmetatable({}, SpringUtility)
	self.Position = initialPosition
	self.Target = initialPosition
	self.Velocity = Vector3.zero
	self.Mass = mass or 1
	self.Force = force or 40
	self.Damping = damping or 4
	self.Speed = speed or 1
	return (self :: any) :: Spring
end

function SpringUtility:Update(dt: number): Vector3
	local scaledDelta = math.min(dt, 0.05) * self.Speed
	local displacement = self.Position - self.Target
	local springForce = -self.Force * displacement
	local dampingForce = -self.Damping * self.Velocity
	local acceleration = (springForce + dampingForce) / self.Mass

	self.Velocity = self.Velocity + (acceleration * scaledDelta)
	self.Position = self.Position + (self.Velocity * scaledDelta)
	return self.Position
end

function SpringUtility:Impulse(force: Vector3)
	self.Velocity = self.Velocity + force
end

function SpringUtility:Reset(pos: Vector3)
	self.Position = pos
	self.Target = pos
	self.Velocity = Vector3.zero
end

--------------------------------------------------------------------------------
-- 2. POLYNOMIAL TRAJECTORIES (Bézier Curves)
--------------------------------------------------------------------------------

local BezierCurve = {}

function BezierCurve.Quadratic(p0: Vector3, p1: Vector3, p2: Vector3, t: number): Vector3
	local l1 = p0:Lerp(p1, t)
	local l2 = p1:Lerp(p2, t)
	return l1:Lerp(l2, t)
end

function BezierCurve.Cubic(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: number): Vector3
	local q0 = BezierCurve.Quadratic(p0, p1, p2, t)
	local q1 = BezierCurve.Quadratic(p1, p2, p3, t)
	return q0:Lerp(q1, t)
end

--------------------------------------------------------------------------------
-- 3. KINEMATIC ARTIFACT SYSTEM (OOP Class)
--------------------------------------------------------------------------------

export type KinematicArtifact = {
	BasePart: BasePart,
	AnchorCFrame: CFrame,
	PhysicsSpring: Spring,
	RotationSpeed: number,
	HoverAmplitude: number,
	HoverFrequency: number,
	Elapsed: number,
	Connection: RBXScriptConnection?,
	Destroy: (self: KinematicArtifact) -> ()
}

local KinematicArtifact = {}
KinematicArtifact.__index = KinematicArtifact

function KinematicArtifact.new(part: BasePart, hoverAmp: number?, hoverFreq: number?): KinematicArtifact
	local self = setmetatable({}, KinematicArtifact)
	self.BasePart = part
	self.AnchorCFrame = part.CFrame
	self.PhysicsSpring = SpringUtility.new(part.Position, 1, 45, 5, 1)
	self.RotationSpeed = 45
	self.HoverAmplitude = hoverAmp or 1.5
	self.HoverFrequency = hoverFreq or 1.8
	self.Elapsed = 0

	self:_Initialize()
	return (self :: any) :: KinematicArtifact
end

function KinematicArtifact:_Initialize()
	self.BasePart.Anchored = true
	self.BasePart.CanCollide = false

	self.Connection = RunService.Heartbeat:Connect(function(dt: number)
		self.Elapsed += dt
		
		local bobOffset = math.sin(self.Elapsed * self.HoverFrequency) * self.HoverAmplitude
		local rawTarget = self.AnchorCFrame.Position + Vector3.new(0, bobOffset, 0)
		self.PhysicsSpring.Target = rawTarget
		
		local resolvedPosition = self.PhysicsSpring:Update(dt)
		local rotationCFrame = CFrame.Angles(0, math.rad(self.Elapsed * self.RotationSpeed), math.sin(self.Elapsed) * 0.1)

		self.BasePart.CFrame = CFrame.new(resolvedPosition) * rotationCFrame
	end)
end

function KinematicArtifact:ApplyDisruption(forceVector: Vector3)
	self.PhysicsSpring:Impulse(forceVector)
end

function KinematicArtifact:Destroy()
	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end
end

--------------------------------------------------------------------------------
-- 4. SPATIAL ORB EMISSION & PATH RESOLUTION
--------------------------------------------------------------------------------

local ProjectileEmitter = {}
ProjectileEmitter.__index = ProjectileEmitter

function ProjectileEmitter.LaunchEnergyOrb(origin: Vector3, destination: Vector3, apexHeight: number, duration: number, color: Color3)
	local orb = Instance.new("Part")
	orb.Size = Vector3.new(1.2, 1.2, 1.2)
	orb.Shape = Enum.PartType.Ball
	orb.Material = Enum.Material.Neon
	orb.Color = color
	orb.CanCollide = false
	orb.Anchored = true
	orb.Parent = workspace

	local midPoint = origin:Lerp(destination, 0.5)
	local controlPoint = midPoint + Vector3.new(0, apexHeight, 0)

	local elapsed = 0
	local connection: RBXScriptConnection
	
	connection = RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt
		local alpha = math.clamp(elapsed / duration, 0, 1)
		local currentPos = BezierCurve.Quadratic(origin, controlPoint, destination, alpha)
		orb.CFrame = CFrame.new(currentPos)

		if alpha >= 1 then
			connection:Disconnect()
			ProjectileEmitter._CreateImpactBurst(destination, color)
			orb:Destroy()
		end
	end)
end

function ProjectileEmitter._CreateImpactBurst(position: Vector3, color: Color3)
	local shockwave = Instance.new("Part")
	shockwave.Shape = Enum.PartType.Cylinder
	shockwave.Size = Vector3.new(0.2, 1, 1)
	shockwave.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	shockwave.Material = Enum.Material.Neon
	shockwave.Color = color
	shockwave.CanCollide = false
	shockwave.Anchored = true
	shockwave.Parent = workspace

	local tweenInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(shockwave, tweenInfo, {
		Size = Vector3.new(0.1, 14, 14),
		Transparency = 1
	})

	tween.Completed:Connect(function()
		shockwave:Destroy()
	end)
	tween:Play()
end

--------------------------------------------------------------------------------
-- 5. SHOCKWAVE DISINTEGRATION / RADIAL PULSE ENGINE
--------------------------------------------------------------------------------

local RadialPulseSystem = {}

function RadialPulseSystem.TriggerGridRipple(center: Vector3, maxRadius: number, affectedFolder: Folder)
	task.spawn(function()
		for _, part in ipairs(affectedFolder:GetChildren()) do
			if part:IsA("BasePart") then
				local distance = (part.Position - center).Magnitude
				if distance <= maxRadius then
					local delayTime = (distance / maxRadius) * 0.6
					task.delay(delayTime, function()
						local originalPosition = part.Position
						local liftGoal = originalPosition + Vector3.new(0, 3, 0)
						
						local upTween = TweenService:Create(part, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
							Position = liftGoal,
							Color = Color3.fromRGB(0, 255, 200)
						})
						local downTween = TweenService:Create(part, TweenInfo.new(0.35, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
							Position = originalPosition,
							Color = Color3.fromRGB(40, 40, 45)
						})
						
						upTween.Completed:Connect(function()
							downTween:Play()
						end)
						upTween:Play()
					end)
				end
			end
		end
	end)
end

--------------------------------------------------------------------------------
-- 6. PUBLIC BOOTSTRAP INITIALIZATION
--------------------------------------------------------------------------------

function ShowcaseEngine.Init()
	print("[ShowcaseEngine] Systems operational.")

	local crystalPart = workspace:FindFirstChild("ShowcaseCrystal")
	if crystalPart and crystalPart:IsA("BasePart") then
		local artifactInstance = KinematicArtifact.new(crystalPart, 2.0, 2.2)
		crystalPart.Touched:Connect(function(hit)
			local humanoid = hit.Parent:FindFirstChildWhichIsA("Humanoid")
			if humanoid then
				artifactInstance:ApplyDisruption(Vector3.new(math.random(-15, 15), 25, math.random(-15, 15)))
			end
		end)
	end

	local launcherPad = workspace:FindFirstChild("LauncherPad")
	local targetPad = workspace:FindFirstChild("TargetPad")
	if launcherPad and targetPad and launcherPad:IsA("BasePart") and targetPad:IsA("BasePart") then
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Launch Dynamic Curve Projectile"
		prompt.ObjectText = "Bézier Cannon"
		prompt.HoldDuration = 0.25
		prompt.MaxActivationDistance = 12
		prompt.Parent = launcherPad

		prompt.Triggered:Connect(function(player: Player)
			local randomColor = Color3.fromRGB(math.random(50, 255), math.random(50, 255), 255)
			local launchOrigin = launcherPad.Position + Vector3.new(0, 2, 0)
			local targetDestination = targetPad.Position + Vector3.new(0, 1, 0)
			ProjectileEmitter.LaunchEnergyOrb(launchOrigin, targetDestination, 24, 0.85, randomColor)
		end)
	end

	local gridFolder = workspace:FindFirstChild("InteractiveGrid")
	local shockwaveButton = workspace:FindFirstChild("ShockwaveButton")
	if gridFolder and shockwaveButton and shockwaveButton:IsA("BasePart") then
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Deploy Wave Shockwave"
		prompt.ObjectText = "Seismic Console"
		prompt.Parent = shockwaveButton

		prompt.Triggered:Connect(function()
			RadialPulseSystem.TriggerGridRipple(shockwaveButton.Position, 45, gridFolder :: Folder)
		end)
	end
end

return ShowcaseEngine
