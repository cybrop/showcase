--!strict
-- Discord: canesberg | Roblox: cybropmc

local DeveloperProfile = {
	Name = "canesberg",
	RobloxUser = "cybropmc",
	Role = "Scripter / Gameplay Programmer",
	PrimaryLanguages = {"Luau", "HTML", "CSS", "JavaScript"},
	Status = "Available for Hire"
}

DeveloperProfile.__index = DeveloperProfile

function DeveloperProfile.PrintSummary()
	print("========================================")
	print(string.format("Developer: %s (@%s)", DeveloperProfile.Name, DeveloperProfile.RobloxUser))
	print(string.format("Role: %s", DeveloperProfile.Role))
	print(string.format("Status: %s", DeveloperProfile.Status))
	print("Languages: " .. table.concat(DeveloperProfile.PrimaryLanguages, ", "))
	print("========================================")
end

DeveloperProfile.PrintSummary()

return DeveloperProfile
