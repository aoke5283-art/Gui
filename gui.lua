local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

local R = Color3.fromRGB
local M, F, UO = Enum.Material, Enum.Font, UDim2.fromOffset
local CONFIG = { APIKEY = "", MODEL = "gemini-2.5-flash", ICONID = "" }

local player = Players.LocalPlayer

local C = {
	panel  = R(10, 10, 12),
	stroke = R(45, 45, 52),
	chip   = R(22, 22, 27),
	text   = R(235, 235, 240),
	dim    = R(130, 130, 140),
	green  = R(52, 211, 120),
	red    = R(240, 85, 85),
	yellow = R(240, 190, 60),
	blue   = R(37, 70, 235),
	pill   = R(18, 22, 32),
}

local function new(class, props, children)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do o[k] = v end
	for _, c in ipairs(children or {}) do c.Parent = o end
	return o
end

local function gloss(o, k)
	new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(k or 0.55, k or 0.55, k or 0.55))
	}).Parent = o
end

local function corner(r) return new("UICorner", {CornerRadius = UDim.new(0, r)}) end
local function stroke(col, t)
	return new("UIStroke", {Color = col, Thickness = t or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
end

local parentGui = player:WaitForChild("PlayerGui")
local old = parentGui:FindFirstChild("ForgeGUI")
if old then old:Destroy() end

local gui = new("ScreenGui", {
	Name = "ForgeGUI", ResetOnSpawn = false, IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
})
gui.Parent = parentGui

-- PILL
local pill = new("TextButton", {
	Name = "Pill", AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 8), Size = UO(118, 34),
	BackgroundColor3 = C.pill, AutoButtonColor = false, Text = "",
}, { corner(17), stroke(C.stroke) })
pill.Parent = gui
gloss(pill, 0.5)

new("Frame", {
	Position = UO(9, 7), Size = UO(20, 20), BackgroundColor3 = C.text,
}, {
	corner(4),
	new("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "F",
		Font = F.GothamBlack, TextSize = 14, TextColor3 = C.pill
	})
}).Parent = pill

new("TextLabel", {
	Position = UO(36, 0), Size = UDim2.new(1, -42, 1, 0), BackgroundTransparency = 1,
	Text = "ForgeGUI", Font = F.GothamBold, TextSize = 14, TextColor3 = C.text,
	TextXAlignment = Enum.TextXAlignment.Left,
}).Parent = pill

-- PANEL
local panel = new("Frame", {
	Name = "Panel", AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -24), Size = UDim2.new(0, 460, 0, 150),
	BackgroundColor3 = C.panel, Visible = false,
}, {
	corner(18), stroke(C.stroke),
	new("UISizeConstraint", {MaxSize = Vector2.new(520, 400), MinSize = Vector2.new(260, 120)})
})
panel.Parent = gui
gloss(panel, 0.6)

new("Frame", {
	Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0
}, {
	corner(18),
	new("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.86), NumberSequenceKeypoint.new(1, 1)})
	})
}).Parent = panel

local input = new("TextBox", {
	Name = "Input", Position = UO(16, 12), Size = UDim2.new(1, -32, 1, -68),
	BackgroundTransparency = 1, Text = "", PlaceholderText = "What do you want to generate?",
	PlaceholderColor3 = C.dim, TextColor3 = C.text, Font = F.Gotham, TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = true, MultiLine = true, ClearTextOnFocus = false,
})
input.Parent = panel

local row = new("Frame", {
	Position = UDim2.new(0, 12, 1, -50), Size = UDim2.new(1, -24, 0, 38), BackgroundTransparency = 1
})
row.Parent = panel

local helpBtn = new("TextButton", {
	Size = UO(38, 38), BackgroundColor3 = C.chip, Text = "?",
	Font = F.GothamBold, TextSize = 18, TextColor3 = C.text,
}, { corner(12), stroke(C.stroke) })
helpBtn.Parent = row
gloss(helpBtn)

local MODES = { "Auto", "Build", "City", "Player" }
local mode = "Auto"

local modeBtn = new("TextButton", {
	Position = UO(46, 0), Size = UO(92, 38),
	BackgroundColor3 = C.chip, Text = "",
}, { corner(12), stroke(C.stroke) })
modeBtn.Parent = row
gloss(modeBtn)

local modeLabel = new("TextLabel", {
	Position = UO(12, 0), Size = UO(52, 38), BackgroundTransparency = 1,
	Text = "Auto", Font = F.GothamMedium, TextSize = 12, TextColor3 = C.text,
	TextXAlignment = Enum.TextXAlignment.Left
})
modeLabel.Parent = modeBtn

new("TextLabel", {
	Position = UDim2.new(1, -22, 0, 0), Size = UO(16, 38), BackgroundTransparency = 1,
	Text = "v", Font = F.GothamBold, TextSize = 14, TextColor3 = C.dim
}).Parent = modeBtn

local menu = new("Frame", {
	AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 58, 1, -56),
	Size = UO(92, #MODES * 32 + 8), BackgroundColor3 = C.panel, Visible = false, ZIndex = 5,
}, {
	corner(12), stroke(C.stroke),
	new("UIListLayout", {HorizontalAlignment = Enum.HorizontalAlignment.Center}),
	new("UIPadding", {PaddingTop = UDim.new(0, 4)})
})
menu.Parent = panel

for _, m in ipairs(MODES) do
	local b = new("TextButton", {
		Size = UDim2.new(1, -8, 0, 32), BackgroundTransparency = 1, Text = m,
		Font = F.GothamMedium, TextSize = 12, TextColor3 = C.text, ZIndex = 6
	})
	b.Parent = menu
	b.MouseButton1Click:Connect(function()
		mode = m
		modeLabel.Text = m
		menu.Visible = false
	end)
end
modeBtn.MouseButton1Click:Connect(function() menu.Visible = not menu.Visible end)

local status = new("Frame", {
	Position = UO(146, 0), Size = UO(112, 38), BackgroundColor3 = C.chip
}, { corner(12), stroke(C.stroke) })
status.Parent = row
gloss(status)

local statusIcon = new("Frame", {
	Position = UO(13, 15), Size = UO(8, 8), BackgroundColor3 = C.green, BorderSizePixel = 0
}, { corner(4) })
statusIcon.Parent = status

local statusText = new("TextLabel", {
	Position = UO(28, 0), Size = UDim2.new(1, -32, 1, 0), BackgroundTransparency = 1,
	Text = "Online", Font = F.GothamMedium, TextSize = 11, TextColor3 = C.green,
	TextXAlignment = Enum.TextXAlignment.Left
})
statusText.Parent = status

local statusToken = 0
local function setStatus(text, col, revert)
	statusToken += 1
	local mine = statusToken
	statusText.Text = text
	statusText.TextColor3 = col
	statusIcon.BackgroundColor3 = col
	if revert then
		task.delay(revert, function()
			if mine == statusToken then
				statusText.Text = "Online"
				statusText.TextColor3 = C.green
				statusIcon.BackgroundColor3 = C.green
			end
		end)
	end
end

-- SEND BUTTON
local send = new("TextButton", {
	AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UO(40, 40),
	BackgroundColor3 = Color3.new(1, 1, 1), Text = "", AutoButtonColor = false, ClipsDescendants = true,
}, {
	corner(20),
	new("UIStroke", {Color = R(90, 150, 255), Thickness = 1.5}),
	new("UIGradient", {
		Rotation = 55,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, R(70, 130, 255)),
			ColorSequenceKeypoint.new(0.5, R(20, 40, 150)),
			ColorSequenceKeypoint.new(1, R(0, 0, 0))
		})
	})
})
send.Parent = row

new("Frame", {
	Position = UO(5, 2), Size = UO(30, 17), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0
}, {
	corner(9),
	new("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1)})
	})
}).Parent = send

if CONFIG.ICONID ~= "" then
	new("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UO(22, 22),
		BackgroundTransparency = 1, Image = "rbxassetid://" .. CONFIG.ICONID
	}).Parent = send
else
	for _, d in ipairs({ { 15, 15, 27 }, { 15, 25, -27 } }) do
		new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UO(d[1] + 6, d[2] + 0), Size = UO(19, 6),
			Rotation = d[3], BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0
		}, { corner(3) }).Parent = send
	end
	new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UO(19, 20), Size = UO(10, 5),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0
	}, { corner(3) }).Parent = send
end

send.MouseButton1Down:Connect(function() send.Size = UO(36, 36) end)
send.MouseButton1Up:Connect(function() send.Size = UO(40, 40) end)

task.spawn(function()
	while true do
		statusIcon.BackgroundTransparency = 0.5
		task.wait(0.8)
		statusIcon.BackgroundTransparency = 0
		task.wait(0.8)
	end
end)

local open = false
local function toggle()
	open = not open
	panel.Visible = open
	menu.Visible = false
end
pill.MouseButton1Click:Connect(toggle)

-- BUILDER
local rng = Random.new()

local COLORS = {
	red = R(220, 40, 40), blue = R(40, 90, 230), green = R(50, 190, 80),
	yellow = R(245, 215, 50), orange = R(245, 140, 30), purple = R(140, 60, 220),
	pink = R(255, 120, 190), white = R(245, 245, 245), black = R(20, 20, 22),
	gray = R(130, 130, 135), brown = R(110, 70, 40),
	cyan = R(40, 210, 230), gold = R(235, 190, 50),
}

local MATERIALS = {
	neon = M.Neon, glass = M.Glass, wood = M.Wood, brick = M.Brick,
	metal = M.Metal, ice = M.Ice, grass = M.Grass, stone = M.Slate,
	concrete = M.Concrete,
}

local SIZEWORDS = { tiny = 0.4, small = 0.6, big = 2, huge = 4 }

local folder
local function getFolder()
	if not folder or not folder.Parent then
		folder = Instance.new("Folder")
		folder.Name = "ForgeGenerated"
		folder.Parent = workspace
	end
	return folder
end

local origin = CFrame.new()
local function setOrigin(distance)
	local ch = player.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if not hrp then
		origin = CFrame.new(0, 0, -distance)
		return false
	end
	local look = hrp.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	flat = flat.Magnitude > 0.01 and flat.Unit or Vector3.new(0, 0, -1)
	local pos = hrp.Position + flat * distance
	pos = Vector3.new(pos.X, hrp.Position.Y - 3, pos.Z)
	origin = CFrame.lookAt(pos, pos + flat)
	return true
end

local function mk(size, lcf, color, material, shape, transparency)
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = origin * lcf
	p.Color = color or C.dim
	p.Material = material or M.SmoothPlastic
	if shape then p.Shape = shape end
	p.Transparency = transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = getFolder()
	return p
end

local V = Vector3.new
local CF = CFrame.new
local B = {}

function B.part(o)
	local s = o.size or V(6, 6, 6)
	mk(s, CF(o.x or 0, s.Y / 2, o.z or 0), o.color or COLORS.red, o.material)
end

function B.sphere(o)
	local d = (o.size and o.size.X) or 6
	mk(V(d, d, d), CF(o.x or 0, d / 2, o.z or 0), o.color or COLORS.blue, o.material, Enum.PartType.Ball)
end

function B.platform(o)
	local s = o.size or V(30, 1, 30)
	mk(V(s.X, math.min(s.Y, 2), s.Z), CF(o.x or 0, 0.5, o.z or 0), o.color or COLORS.gray, o.material or M.Concrete)
end

function B.wall(o)
	local s = o.size or V(30, 14, 2)
	mk(s, CF(o.x or 0, s.Y / 2, o.z or 0), o.color or COLORS.gray, o.material or M.Brick)
end

function B.tower(o)
	local s = o.size or V(14, 70, 14)
	local x, z = o.x or 0, o.z or 0
	mk(s, CF(x, s.Y / 2, z), o.color or COLORS.gray, o.material or M.Concrete)
end

function B.house(o)
	local k = o.scale or 1
	local x, z = o.x or 0, o.z or 0
	local wall = o.color or R(235, 220, 190)
	mk(V(20, 12, 16) * k, CF(x, 6 * k, z), wall, o.material or M.Brick)
	mk(V(22, 2, 18) * k, CF(x, 13 * k, z), R(130, 50, 40), M.Slate)
	mk(V(4, 8, 0.6) * k, CF(x, 4 * k, z + 8.2 * k), R(90, 55, 30), M.Wood)
end

function B.tree(o)
	local k = o.scale or 1
	local x, z = o.x or 0, o.z or 0
	mk(V(14 * k, 3 * k, 3 * k), CF(x, 7 * k, z) * CFrame.Angles(0, 0, math.pi / 2), R(105, 70, 40), M.Wood, Enum.PartType.Cylinder)
	local leaf = o.color or R(50, 150, 60)
	mk(V(13, 13, 13) * k, CF(x, 17 * k, z), leaf, M.Grass, Enum.PartType.Ball)
end

function B.lamp(o)
	local x, z = o.x or 0, o.z or 0
	mk(V(1, 16, 1), CF(x, 8, z), COLORS.black, M.Metal)
	mk(V(4, 1, 1), CF(x + 1.5, 16, z), COLORS.black, M.Metal)
	mk(V(2.4, 1, 2.4), CF(x + 3, 15.6, z), R(255, 240, 180), M.Neon)
end

function B.car(o)
	local x, z = o.x or 0, o.z or 0
	local col = o.color or Color3.fromHSV(rng:NextNumber(), 0.7, 0.9)
	local rot = CFrame.Angles(0, o.rot or 0, 0)
	mk(V(6, 2, 12), CF(x, 2, z) * rot, col, M.SmoothPlastic)
	mk(V(5, 1.8, 6), CF(x, 3.9, z) * rot, R(150, 200, 230), M.Glass, nil, 0.25)
end

local function buildCity(n)
	n = math.clamp(n, 2, 14)
	local BLOCK, ROAD = 56, 22
	local pitch = BLOCK + ROAD
	local extent = n * pitch
	setOrigin(extent / 2 + 40)
	mk(V(extent + ROAD, 1, extent + ROAD), CF(0, -0.5, 0), R(45, 46, 50), M.Asphalt)
	local half = (n - 1) / 2
	local palette = { R(120, 128, 140), R(90, 100, 120), R(160, 110, 90), R(70, 75, 90), R(110, 140, 170) }
	local neons = { R(80, 230, 255), R(255, 220, 120), R(255, 120, 200) }
	for i = 0, n - 1 do
		for j = 0, n - 1 do
			local cx = (i - half) * pitch
			local cz = (j - half) * pitch
			mk(V(BLOCK, 1.2, BLOCK), CF(cx, 0.1, cz), R(170, 170, 172), M.Concrete)
			local dist = math.sqrt((i - half) ^ 2 + (j - half) ^ 2) / math.max(half, 1)
			local maxH = 150 - dist * 100
			local nb = rng:NextInteger(1, 3)
			for b = 1, nb do
				local w = rng:NextInteger(14, nb == 1 and 36 or 22)
				local d = rng:NextInteger(14, nb == 1 and 36 or 22)
				local h = rng:NextInteger(24, math.max(30, math.floor(maxH)))
				local ox = nb == 1 and 0 or ((b - 2) * 18 + rng:NextInteger(-3, 3))
				local oz = nb == 1 and 0 or rng:NextInteger(-12, 12)
				local bx, bz = cx + ox, cz + oz
				local col = palette[rng:NextInteger(1, #palette)]
				mk(V(w, h, d), CF(bx, h / 2 + 0.7, bz), col, M.Concrete)
				mk(V(w + 1, 1.5, d + 1), CF(bx, h + 1.5, bz), R(40, 42, 48), M.Metal)
				local neon = neons[rng:NextInteger(1, #neons)]
				local bands = math.min(7, math.floor(h / 9))
				for k = 1, bands do
					local y = k * (h / (bands + 1)) + 0.7
					mk(V(w * 0.8, 2.2, 0.4), CF(bx, y, bz + d / 2 + 0.1), neon, M.Neon)
					mk(V(w * 0.8, 2.2, 0.4), CF(bx, y, bz - d / 2 - 0.1), neon, M.Neon)
				end
			end
			B.lamp({ x = cx + BLOCK / 2 - 2, z = cz + BLOCK / 2 - 2 })
		end
		task.wait()
	end
end

local function humanoid()
	local ch = player.Character
	return ch and ch:FindFirstChildOfClass("Humanoid")
end

local HELP = [[Try: city, big city, house, tower, tree, car, lamp, platform, wall, sphere, red part, neon blue sphere, 5 trees, 20x1x20 platform, speed 80, jump 120, night, day, fog, clear]]

local OBJECTS = {
	{ "city", "city" },
	{ "sphere", "sphere" }, { "ball", "sphere" },
	{ "platform", "platform" }, { "floor", "platform" },
	{ "wall", "wall" },
	{ "tower", "tower" },
	{ "house", "house" },
	{ "tree", "tree" }, { "lamp", "lamp" },
	{ "car", "car" }, { "part", "part" }, { "block", "part" }, { "cube", "part" },
}

local function run(text)
	local s = text:lower()
	if mode == "City" and not s:find("city") then s = "city " .. s end
	local num = tonumber(s:match("(%-?%d+%.?%d*)"))

	if s:find("^help") or s == "?" then
		print(HELP)
		return "Help in Output", C.yellow
	end
	if s:find("clear") or s:find("delete all") or s:find("remove all") then
		if folder then folder:Destroy(); folder = nil end
		return "Cleared", C.green
	end
	if s:find("night") then Lighting.ClockTime = 0; return "Night", C.green end
	if s:find("day") then Lighting.ClockTime = 14; return "Day", C.green end
	if s:find("fog") then
		Lighting.FogEnd = 250
		Lighting.FogColor = R(160, 170, 185)
		return "Fog", C.green
	end

	local hum = humanoid()
	if s:find("speed") and num then
		if hum then hum.WalkSpeed = num end
		return "Speed " .. num, C.green
	end
	if s:find("jump") and num then
		if hum then hum.UseJumpPower = true; hum.JumpPower = num end
		return "Jump " .. num, C.green
	end
	if s:find("gravity") and num then
		workspace.Gravity = num
		return "Gravity " .. num, C.green
	end

	local kind, label
	for _, pair in ipairs(OBJECTS) do
		if s:find(pair[1], 1, true) then kind = pair[2]; break end
	end
	if mode == "Build" and not kind then kind = "part" end
	if not kind then
		kind = "part"
		label = text:sub(1, 40)
	end

	if kind == "city" then
		local n = 6
		local explicit = s:match("(%d+)")
		if explicit then n = tonumber(explicit)
		elseif s:find("huge") then n = 14
		elseif s:find("big") then n = 10
		elseif s:find("small") then n = 3 end
		buildCity(n)
		return "City built", C.green
	end

	local color, material
	for name, c in pairs(COLORS) do if s:find(name, 1, true) then color = c; break end end
	for name, m in pairs(MATERIALS) do if s:find(name, 1, true) then material = m; break end end
	if material == M.Neon and not color then color = COLORS.cyan end

	local scale = 1
	for w, k in pairs(SIZEWORDS) do if s:find(w, 1, true) then scale = k; break end end

	local size
	local a, b2, c3 = s:match("(%d+%.?%d*)%s*x%s*(%d+%.?%d*)%s*x%s*(%d+%.?%d*)")
	if a then
		size = V(tonumber(a), tonumber(b2), tonumber(c3))
	else
		local a2, b3 = s:match("(%d+%.?%d*)%s*x%s*(%d+%.?%d*)")
		if a2 then
			local x, z = tonumber(a2), tonumber(b3)
			size = (kind == "platform") and V(x, 1, z) or V(x, 6, z)
		end
	end

	local count = 1
	if not size and num and num >= 1 and num <= 30 and not s:match("%d+%s*x") then
		count = math.floor(num)
	end

	setOrigin(20 + 14 * scale)
	local spacing = (kind == "house" and 28 or kind == "tree" and 16 or 14) * math.max(scale, 1)

	for i = 1, count do
		local o = { color = color, material = material, scale = scale, x = (i - (count + 1) / 2) * spacing, z = 0 }
		if size then o.size = size
		elseif kind == "part" then o.size = V(6, 6, 6) * scale
		elseif kind == "sphere" then o.size = V(6, 6, 6) * scale
		elseif kind == "platform" then o.size = V(30, 1, 30) * scale
		elseif kind == "wall" then o.size = V(30, 14, 2) * scale
		elseif kind == "tower" then o.size = V(14, 70, 14) * scale end
		local fn = B[kind]
		if fn then fn(o) end
	end

	if label then
		local kids = getFolder():GetChildren()
		local p = kids[#kids]
		if p then
			local bb = new("BillboardGui", {Size = UO(200, 40), ExtentsOffset = Vector3.new(0, 3, 0), Adornee = p, AlwaysOnTop = true})
			new("TextLabel", {
				Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = label,
				Font = F.GothamBold, TextSize = 16, TextColor3 = C.text, TextStrokeTransparency = 0.5
			}).Parent = bb
			bb.Parent = p
		end
	end
	return "Built " .. kind, C.green
end

-- ONLINE (AI) MODE
local function online(p)
	local body = HttpService:JSONEncode({
		systemInstruction = { parts = {{ text = "Return only raw Roblox Luau code, no markdown. Build the request in front of the local player." }} },
		contents = {{ role = "user", parts = {{ text = p }} }}
	})
	local url = "https://generativelanguage.googleapis.com/v1beta/models/" .. CONFIG.MODEL .. ":generateContent"
	local h = { ["Content-Type"] = "application/json", ["x-goog-api-key"] = CONFIG.APIKEY }
	local r = (syn and syn.request) or (http and http.request) or httprequest or request
	local raw
	if r then
		raw = r({ Url = url, Method = "POST", Headers = h, Body = body }).Body
	else
		local ok, res = pcall(function()
			return HttpService:RequestAsync({ Url = url, Method = "POST", Headers = h, Body = body }).Body
		end)
		if not ok then error("web requests blocked: " .. tostring(res)) end
		raw = res
	end
	local code = (HttpService:JSONDecode(raw).candidates[1].content.parts[1].text
		:gsub("^%s*```%w*%s*\n", "")
		:gsub("\n%s*```%s*$", ""))
	loadstring(code)()
end

local busy = false
local function generate()
	if busy then return end
	local text = input.Text
	if text:gsub("%s", "") == "" then return end
	busy = true
	setStatus("Working...", C.yellow)
	task.spawn(function()
		if CONFIG.APIKEY ~= "" then
			local o, e = pcall(online, text)
			if o then
				setStatus("Online", C.green, 2.5)
				input.Text = ""
				busy = false
				return
			end
			warn("[ForgeGUI] AI unavailable, using offline builder. Reason: " .. tostring(e))
		end
		local ok, msg, col = pcall(run, text)
		if ok then
			setStatus(msg, col, 2.5)
			if col ~= C.red then input.Text = "" end
		else
			warn("[ForgeGUI] " .. tostring(msg))
			setStatus("Error", C.red, 2.5)
		end
		busy = false
	end)
end

send.MouseButton1Click:Connect(generate)
helpBtn.MouseButton1Click:Connect(
