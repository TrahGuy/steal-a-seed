--!strict
-- Steal a Seed :: PodGuideUI
--
-- THE POD GUIDE'S STANDS, ON THIS CLIENT (2026-10-09; GameConfig.PodGuide,
-- KB/POD-GUIDE-PLAN.md)
--
-- One stand just inside each biome's arch (PodGuideStand), built here for this
-- player alone -- nothing replicates -- its board lettered (PodGuideView) from
-- what this player has grown: the Almanac, learnt as the Plant Almanac learns
-- it, so a first discovery waits for its own reveal (HatchRoll). Near and far
-- are checked every CheckSeconds, never a frame's work:
--
--   * the carousel's five pods are built within BuildStuds of the camera and
--     freed past FreeStuds (PodMotion idles them: PodShowcase);
--   * the board's pictures are built within PreviewNearStuds and freed past
--     PreviewFarStuds;
--   * the carousel turns within TurnStuds, every other frame, on the server's
--     clock (every player sees it at the same angle); still for reduced motion.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
local StatusText = require(Shared:WaitForChild("StatusText"))
local HatchRoll = require(Shared:WaitForChild("HatchRoll"))
local PodGuideStand = require(Shared:WaitForChild("PodGuideStand"))
local PodGuideView = require(Shared:WaitForChild("PodGuideView"))

local CFG = GameConfig.PodGuide
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- A re-run leaves nothing behind.
local FOLDER = "PodGuideLocal"
local old = Workspace:FindFirstChild(FOLDER)
if old then
	old:Destroy()
end
for _, g in ipairs(playerGui:GetChildren()) do
	if g.Name == PodGuideView.GuiName then
		g:Destroy()
	end
end
local folder = Instance.new("Folder")
folder.Name = FOLDER
folder.Archivable = false
folder.Parent = Workspace

type Entry = {
	biomeId: string,
	frame: CFrame,
	view: PodGuideView.View,
	carousel: PodGuideStand.Carousel?,
	near: boolean,
	turning: boolean,
}
local entries: { Entry } = {}
-- What this player has grown; it only ever grows on the client.
local known: { [string]: boolean } = {}

for _, biome in ipairs(BiomeData.Biomes) do
	local frame = PodGuideStand.frame(biome.Id)
	local model = if frame then PodGuideStand.build(biome.Id, folder) else nil
	local board = model and model:FindFirstChild(PodGuideStand.BOARD)
	if frame and board and board:IsA("BasePart") then
		table.insert(entries, {
			biomeId = biome.Id,
			frame = frame,
			view = PodGuideView.new(board, playerGui, biome.Id),
			carousel = nil,
			near = false,
			turning = false,
		})
	end
end

local function paint()
	for _, e in ipairs(entries) do
		PodGuideView.paint(e.view, known)
	end
end

--==============================================================================
-- WHAT THIS PLAYER HAS GROWN (IndexUI's own rule): a species still waiting to
-- be shown at its hatch is added when its roll ends, never before.
--==============================================================================
local function receive(profile: any)
	if type(profile) ~= "table" or type(profile.Almanac) ~= "table" then
		return
	end
	local waiting = HatchRoll.sealedSpecies(player)
	local changed = false
	for id, value in pairs(profile.Almanac) do
		if value == true and type(id) == "string" and not known[id] then
			local shownAt = waiting[id]
			if shownAt then
				task.delay(math.max(shownAt - Workspace:GetServerTimeNow(), 0) + 0.05, function()
					if not known[id] then
						known[id] = true
						paint()
					end
				end)
			else
				known[id] = true
				changed = true
			end
		end
	end
	if changed then
		paint()
	end
end

local remotes = SeedGame:WaitForChild("Remotes", 20)
if remotes then
	local updated = remotes:WaitForChild(GameConfig.Remotes.ProfileUpdated, 20)
	if updated and updated:IsA("RemoteEvent") then
		updated.OnClientEvent:Connect(receive)
	end
	local ready = remotes:WaitForChild(GameConfig.Remotes.ProfileReady, 20)
	if ready and ready:IsA("RemoteEvent") then
		ready.OnClientEvent:Connect(function(ok: boolean, profile: any)
			if ok then
				receive(profile)
			end
		end)
	end
end

--==============================================================================
-- NEAR AND FAR, AND THE TURN
--==============================================================================
local function freeCarousel(e: Entry)
	local carousel = e.carousel
	if carousel then
		for _, pod in ipairs(carousel.pods) do
			pod:Destroy()
		end
		e.carousel = nil
	end
end

local since, stillSince, frame = math.huge, math.huge, 0
local still = false
RunService.Heartbeat:Connect(function(dt: number)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	since += dt
	if since >= CFG.CheckSeconds then
		since = 0
		local eye = camera.CFrame.Position
		for _, e in ipairs(entries) do
			local d = (e.frame.Position - eye).Magnitude
			if e.carousel == nil and d <= CFG.BuildStuds then
				e.carousel = PodGuideStand.buildPods(e.biomeId, e.frame, folder)
			elseif e.carousel ~= nil and d > CFG.FreeStuds then
				freeCarousel(e)
			end
			local near = if e.near then d <= CFG.PreviewFarStuds else d <= CFG.PreviewNearStuds
			if near ~= e.near then
				e.near = near
				PodGuideView.setPreviews(e.view, near)
			end
			e.turning = d <= CFG.TurnStuds
		end
	end
	stillSince += dt
	if stillSince >= 0.5 then
		stillSince = 0
		still = StatusText.reducedMotion()
	end
	frame += 1
	if still or frame % 2 ~= 0 then
		return
	end
	-- One turn's worth of the clock, kept small (PodGuideStand.podFrames).
	local angle = (Workspace:GetServerTimeNow() / CFG.TurnSeconds) % 1 * 2 * math.pi
	for _, e in ipairs(entries) do
		local carousel = e.carousel
		if carousel and e.turning then
			PodGuideStand.turn(carousel, e.frame, angle)
		end
	end
end)
