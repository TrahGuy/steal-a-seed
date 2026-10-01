--!strict
-- Steal a Seed :: StarbloomTeaser (client)
--
-- Puts the Starbloom end wall's teaser up on this screen, once, on a local
-- anchor in its own folder (Shared/StarbloomTeaser). Nothing to update: the
-- words never change and nothing here moves. Safe to re-run: the old folder
-- goes first.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local StarbloomTeaser = require(Shared:WaitForChild("StarbloomTeaser"))

local FOLDER = StarbloomTeaser.Name .. "Local"
local old = Workspace:FindFirstChild(FOLDER)
if old then
	old:Destroy()
end
local folder = Instance.new("Folder")
folder.Name = FOLDER
folder.Archivable = false
folder.Parent = Workspace

StarbloomTeaser.build(folder)
