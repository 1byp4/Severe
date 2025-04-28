local img = Drawing.new("Image")
img.Url = _G.config.url
img.Color = _G.config.color
img.Visible = _G.config.visible
img.zIndex = _G.config.zindex
img.Position = _G.config.position
img.Size = _G.config.size

local function tween(startcol, tinfo, goalcol, updcb)
	local config = {
		duration = 1,
		delay = 0,
		onstart = nil,
		onupd = nil,
		oncomp = nil
	}

	if tinfo then
		for k, v in pairs(tinfo) do
			config[k] = v
		end
	end

	if #startcol ~= 3 or #goalcol ~= 3 then
		error("colors must be rgb tables")
	end

	local currentcol = {table.unpack(startcol)}
	local start = os.clock() + config.delay
	local completed = false
	local cancelled = false
	local initialized = false

	local function ease(t)
		t = t * 2
		if t < 1 then return 0.5 * t * t end
		t = t - 1
		return -0.5 * (t * (t - 2) - 1)
	end

	local function update()
		if completed or cancelled then return false end

		local current = os.clock()
		if current < start then return true end

		if not initialized then
			initialized = true
			if config.onstart then config.onstart() end
		end

		local elapsed = current - start
		local progress = math.min(elapsed / config.duration, 1)
		local eased = ease(progress)

		for i = 1, 3 do
			currentcol[i] = math.floor(startcol[i] + (goalcol[i] - startcol[i]) * eased)
		end

		updcb(currentcol)

		if config.onupd then
			config.onupd(currentcol, progress, eased)
		end

		if progress >= 1 then
			completed = true
			if config.oncomp then
				config.oncomp(currentcol)
			end
			return false
		end

		return true
	end

	return {
		update = update,
		cancel = function() cancelled = true end,
		iscomp = function() return completed end,
		getprog = function()
			if completed then return 1 end
			if os.clock() < start then return 0 end
			return math.min((os.clock() - start) / config.duration, 1)
		end,
		getcurrentcol = function() return currentcol end
	}
end

local function startcycle()
	local sequence = {
		{255, 0, 0},
		{0, 255, 0},
		{0, 0, 255}
	}

	local currentindex = 1
	local currentcol = {table.unpack(sequence[1])}

	local function nexttween()
		local nextindex = currentindex % #sequence + 1
		local startcol = {table.unpack(sequence[currentindex])}
		local endcol = {table.unpack(sequence[nextindex])}

		currentindex = nextindex

		return tween(
			startcol,
			{
				duration = 2,
				onupd = function(color, progress)
					print(string.format("done: %.1f%%, color: %d, %d, %d", 
						progress * 100, color[1], color[2], color[3]))
				end,
				oncomp = function(color)
					print("transition done:", color[1], color[2], color[3])
				end
			},
			endcol,
			function(color)
				currentcol = color
				img.Color = color
			end
		)
	end
	while true do
		local currenttween = nexttween()
		while not currenttween.iscomp() do
			currenttween.update()
			wait(1/330)
		end
	end
end

startcycle()
