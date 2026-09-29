--!strict
--==============================================================================
-- Steal a Seed :: TrafficLogConfig
--
-- SERVER-ONLY settings for the external new-player traffic feed
-- (TrafficLogService; the owner's and Michael's guide is KB/TRAFFIC_LOG.md).
-- It lives in ServerScriptService, which never replicates, so no client can
-- read it -- unlike GameConfig, which every client downloads.
--
-- IT HOLDS NO ENDPOINT AND NO CREDENTIAL. Both webhook URLs are Roblox
-- experience secrets (Creator Hub -> the experience -> Secrets), read on the
-- server by NAME with HttpService:GetSecret. A Secret never prints: tostring
-- gives "Secret(<name>)", so no log line can show it either.
--
-- Not a *Service: ServerMain does not load it; TrafficLogService reads it.
--==============================================================================

local TrafficLogConfig = {
	-- The owner supplied both endpoints and approved creating their experience
	-- secrets. Studio never sends; live delivery still requires HTTP enabled
	-- and an owner publish (KB/TRAFFIC_LOG.md, "Going live").
	Enabled = true,

	-- Separate experience secrets hold the complete Make webhook URLs. Keep
	-- their values in Creator Hub, never in this repository or a client script.
	JoinSecretName = "PodnappersTrafficJoinWebhook",
	DurationSecretName = "PodnappersTrafficDurationWebhook",

	-- CAMPAIGN TAGS: the only launch-data values ever forwarded. A join whose
	-- launch data (Ads Manager -> Advanced join options) is exactly one of these,
	-- ignoring case and surrounding spaces, is reported with it; every other
	-- join -- no launch data, an unknown value, anything malformed -- is
	-- "unknown". Lowercase letters, digits, "_" and "-", at most 40 characters;
	-- an entry that is not is ignored. Empty until Michael supplies them.
	CampaignTags = {} :: { string },

	-- DELIVERY BOUNDS. Two events per new player; these are ceilings for an
	-- outage, not a budget anybody should meet.
	QueueCapacity = 64, -- events held at once; a full queue drops the newest
	MaxConcurrent = 2, -- requests in flight at once
	MaxAttempts = 5, -- tries per event, the first included
	BackoffSeconds = 2, -- the first retry waits this, doubling each time...
	MaxBackoffSeconds = 60, -- ...never longer than this (a Retry-After too)
	Jitter = 0.2, -- +/- this share of each wait, so retries do not bunch
	PumpSeconds = 0.5, -- how often the sender looks at its queue, only while it has one
	FlushSeconds = 4, -- the best-effort send when the server shuts down
	DiagnosticSeconds = 60, -- at most one warning of each kind per this long
}

return TrafficLogConfig
