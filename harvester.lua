-- Automatic Tree Harvester
-- Original Version by Clueless (http://www.computercraft.info/forums2/index.php?/topic/546-13-autotreefarm-program/)

local shouldOutput = false
local width = 0
local length = 0

local function loadSettings()
	file = io.open( "settings.txt", "r" )

	while true do
		line = file:read()
		if not line then break end

		if line == "true" then
			shouldOutput = true
		else
			shouldOutput = false
		end

		line = file:read()
		if not line then break end

		width = tonumber(line)

		line = file:read()
		if not line then break end

		length = tonumber(line)

		file:close()
		return true
	end

	file:close()
	return false
end

local function createSettings()
	term.clear()
	term.setCursorPos( 1,1 )
	print( "Set the settings." )

	write( "Output Redstone on cycle: " )
	local str = string.lower( read() )
	if str == "1" or str == "yes" or str == "true" then
		shouldOutput = true
	else
		shouldOutput = false
	end

	write( "Rows: " )
	width = tonumber(read())

	write( "Trees: " )
	length = tonumber(read())

	file = io.open("settings.txt", "w")
	if file == nil then
		--error? could be locked
		return
	end

	if shouldOutput then
		file:write( "true" )
		file:write( "\n" )
	else
		file:write( "false" )
		file:write( "\n" )
	end

	file:write( width )
	file:write( "\n" )
	file:write( length )
	file:write( "\n" )

	file:close()

	term.clear()
	term.setCursorPos( 1,1 )
	print( "Ready to cycle" )
end

local function init()
	term.clear()
	term.setCursorPos( 1,1 )
	print( "Logger program starting..." )

	if fs.exists( "settings.txt" ) then
		if not loadSettings() then
			createSettings()
		end

		term.clear()
		term.setCursorPos( 1,1 )
		print( "Ready to cycle" )

	else
		createSettings()
	end

	rednet.open( "right" )
end

local function tryMove( direction )
	if direction == "down" then
		if turtle.detectDown() then
			turtle.digDown()
		end
		while not turtle.down() do
			turtle.digDown()
			sleep(1)
		end
	end

	if direction == "forward" then
		if turtle.detect() then
			turtle.dig()
		end
		while not turtle.forward() do
			turtle.dig()
			sleep(1)
		end
	end

	if direction == "up" then
		if turtle.detectUp() then
			turtle.digUp()
		end
		while not turtle.up() do
			turtle.digUp()
			sleep(1)
		end
	end

end

local function plantTree()
	turtle.select(1)
	l = turtle.getItemCount(1)
	turtle.placeDown()
	t = turtle.getItemCount(1)

	if t == l then --must have not been able to place a sapling
		turtle.select(2)
		tryMove("down")
		if turtle.detectDown() then turtle.digDown() end
		turtle.placeDown()
		turtle.select(1)
		tryMove("up")
		turtle.placeDown()
	end

	turtle.select(9)
end

local function harvestTree()
	steps = 1
	tryMove("forward")

	while turtle.detectUp() do
		tryMove( "up" )
		steps = steps + 1
	end

	while steps > 2 do
		tryMove( "down" )
		steps = steps - 1
	end
	plantTree()
end

local function checkTree()
	if turtle.detect() then
		tryMove( "down" )
		harvestTree()
	else
		tryMove( "forward" )
		if not turtle.detectDown() then
			plantTree()
		end
	end
end

local function harvest()
	turtle.select(1)
	tryMove( "forward" )
	tryMove( "up" )
	checkTree()

	bump = false

	for w=1, width do
		for l=1, length do
			if l~=length then
				tryMove( "forward" )
				tryMove( "forward" )
				checkTree()
			end
		end

		if w~=width then
			if not bump then
				turtle.turnLeft()
				tryMove( "forward" )
				tryMove( "forward" )
			else
				turtle.turnRight()
				tryMove( "forward" )
				tryMove( "forward" )
			end
			checkTree()

			if bump then
				turtle.turnRight()
			else
				turtle.turnLeft()
			end

			bump = not bump
		end
	end

	--Return
	if not bump then
		turtle.turnLeft()
		tryMove( "forward" )
		turtle.turnLeft()
		for i = 1, length do
			tryMove( "forward" )
			tryMove( "forward" )
			if i~=length then
				tryMove( "forward" )
			end
		end
	else
		tryMove( "forward" )
		tryMove( "forward" )
	end
	turtle.turnLeft()

	if width == 1 then
		tryMove( "forward" )
	else
		for i=1, width - 1 do
			tryMove( "forward" )
			tryMove( "forward" )
			tryMove( "forward" )
		end
		if not bump then
			tryMove( "forward" )
		end
	end

	turtle.turnLeft()
	tryMove( "down" )
	turtle.select(9)

	--Drop off and resupply
	if shouldOutput then
		redstone.setOutput("left", true)
		output = true

		while output do

			for i=3, 9 do
				if turtle.getItemSpace( i ) ~= 64 then
					break
				elseif i==9 and turtle.getItemSpace( 9 ) == 64 then
					output = false
				end
			end
			sleep(0.5)
		end

		redstone.setOutput("left", false)
	end

	print( "Ready to cycle" )
end

local function startHarvesting()
	while true do
		event, p1, p2 = os.pullEvent()
		if event == "rednet_message" and p2 == "startLogging" then
			harvest()
		end
		if event == "char" and p1 == "s" then
			createSettings()
		end
		if event == "char" and p1 == "r" then
			print("User override, harvest starting")
			harvest()
		end
	end
end

init()
startHarvesting()
