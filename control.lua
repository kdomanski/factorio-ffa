require "util"
require "defines"

require "math"
require "string"

local KILL_ALIENS_RANGE = 400
local TELEPORT_DISTANCE = 600.0

local rand_is_initialized = false

function message_all_players(msg)
	for name, player in pairs(game.players) do
		player.print(msg)
	end
end

function get_random_position(radius)
	if false == rand_is_initialized then
                math.randomseed(game.tick)
                rand_is_initialized = true
        end

        local arc = math.random(0.0, math.pi*2)

        local x = math.sin(arc) * TELEPORT_DISTANCE
        local y = math.cos(arc) * TELEPORT_DISTANCE

	return {x,y}
end

function kill_aliens_at_area(surface, position, deltaPos)
	local x = position[1]
	local y = position[2]
	local box = {{x-deltaPos, y-deltaPos}, {x+deltaPos, y+deltaPos}}
	local aliens = surface.find_entities_filtered{area= box, force= "enemy"}
	for index, a in ipairs(aliens) do
		a.destroy()
	end
end

function kill_aliens_at_box(surface, box)
	local aliens = surface.find_entities_filtered{area= box, force= "enemy"}
        for index, a in ipairs(aliens) do
                a.destroy()
        end
end

function kill_aliens_at_chunk(chunk)
	kill_aliens_at_box(chunk.surface, chunk.area)
end

function is_point_within_chunk(point, chunk)
	local x = point.x
	local y = point.y

	local x1 = chunk.area.left_top.x
	local x2 = chunk.area.right_bottom.x

	local y1 = chunk.area.left_top.y
	local y2 = chunk.area.right_bottom.y

	if x1 > x2 then x1, x2 = x2, x1 end
	if y1 > y2 then y1, y2 = y2, y1 end

	if y1 < y and y2 > y and x1 < x and x2 > x then
		return true
	end

	return false
end

function is_a_spawn_chunk(chunk)
	for name, force in pairs(game.forces) do
		local spawn = force.get_spawn_position(chunk.surface)
		if is_point_within_chunk(spawn, chunk) then
			return true
		end
	end
end

function distance_to_chunk(chunk, position)
	local x1 = chunk.area.left_top.x
        local x2 = chunk.area.right_bottom.x

        local y1 = chunk.area.left_top.y
        local y2 = chunk.area.right_bottom.y

	local d1 = math.abs(x1 - position.x)
	local d2 = math.abs(x2 - position.x)
	local d3 = math.abs(y1 - position.y)
	local d4 = math.abs(y2 - position.y)

	local dist1 = math.min(d1, d2)
	local dist2 = math.min(d3, d4)

	return math.sqrt((dist1*dist1) + (dist2*dist2))
end

function teleport_force(faction)
	local pos = get_random_position()
	
	for name, player in ipairs(faction.players) do
		success = player.teleport(pos)
		if false == success then
			return false
		end

		print(" * * * Teleported " .. player.name)
	end

	faction.set_spawn_position(pos, game.get_surface(1))
	kill_aliens_at_area(game.get_surface(1), pos, KILL_ALIENS_RANGE)

	return true
end

function teleport_force_until_success(force)
	local teleport_successful = false

	while false == teleport_successful do
		teleport_successful = teleport_force(force)
	end
end

function chunk_contains_spawn_locations(chunk)
	local locations = {}

	for name, force in pairs(game.forces) do
		if name == "enemy" then goto continue4298 end

		local spawn = force.get_spawn_position(game.get_surface(1))

		if is_point_within_chunk(spawn, chunk) then
			locations[name] = force
		end

		::continue4298::
	end

	return locations
end

script.on_event(defines.events.on_player_created, function(event)
	local thePlayer = game.players[event.player_index]
	local underscoreMatch = thePlayer.name:find("_")
	local name
	if underscoreMatch == nil then
		name = thePlayer.name
	else
		name = thePlayer.name:sub(0, underscoreMatch-1)
	end

	message_all_players("Player '" .. thePlayer.name .. "' is in force '" .. name .. "'.")

	local f = game.forces[name]
	if f == nil then
		f = game.create_force(name)
		thePlayer.force = f
		teleport_force_until_success(f)
	end
end)

script.on_event(defines.events.on_chunk_generated, function(chunk)
	for name, force in pairs(game.forces) do
		if name == "enemy" then goto continue6123 end

		local spawn = force.get_spawn_position(chunk.surface)
		local distance = distance_to_chunk(chunk, spawn)
		if distance < KILL_ALIENS_RANGE then
			kill_aliens_at_chunk(chunk)
			break
                end

		::continue6123::
        end

	local forces = chunk_contains_spawn_locations(chunk)
	for name, force in pairs(forces) do
		if name == "enemy" then break end

		local spawn = force.get_spawn_position(game.get_surface(1))
		local tile = game.get_surface(1).get_tile(spawn.x, spawn.y)

		if tile.collides_with("water-tile") then
			print("Ooops... " .. name .. " landed in water. Randomizing again...")
			teleport_force_until_success(force)
		end
	end
end)
