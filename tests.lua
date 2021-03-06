local tests = {}

local constants = require("libs/Constants")
local mathUtils = require("libs/MathUtils")
local chunkUtils = require("libs/ChunkUtils")
local mapUtils = require("libs/MapUtils")
local baseUtils = require("libs/BaseUtils")
local baseRegisterUtils = require("libs/BaseRegisterUtils")
local tendrilUtils = require("libs/TendrilUtils")

function tests.pheromoneLevels(size) 
    local player = game.player.character
    local playerChunkX = math.floor(player.position.x / 32)
    local playerChunkY = math.floor(player.position.y / 32)
    if not size then
	size = 3
    end
    print("------")
    print(#global.regionMap.processQueue)
    print(playerChunkX .. ", " .. playerChunkY)
    print("--")
    for y=playerChunkY-size, playerChunkY+size do
	for x=playerChunkX-size, playerChunkX+size do
            if (global.regionMap[x] ~= nil) then
                local chunk = global.regionMap[x][y]
                if (chunk ~= nil) then
                    local str = ""
                    for i=1,#chunk do
                        str = str .. " " .. tostring(i) .. "/" .. tostring(chunk[i])
                    end
		    str = str .. " " .. "p/" .. game.surfaces[1].get_pollution(chunk)
		    if (chunk.cX == playerChunkX) and (chunk.cY == playerChunkY) then
			print("=============")
			print(chunk.cX, chunk.cY, str)
			print("=============")
		    else
			print(chunk.cX, chunk.cY, str)
		    end
		    -- print(str)
		    print("----")
                end
            end
        end
	print("------------------")
    end
end

function tests.activeSquads()
    print("--")
    for i=1, #global.natives.squads do
        local squad = global.natives.squads[i]
        if squad.group.valid then
            print(math.floor(squad.group.position.x * 0.03125), math.floor(squad.group.position.y * 0.03125), squad.status, squad.group.state, #squad.group.members)
            print(serpent.dump(squad))
        end
    end
end

function tests.entitiesOnPlayerChunk()
    local playerPosition = game.players[1].position
    local chunkX = math.floor(playerPosition.x * 0.03125) * 32
    local chunkY = math.floor(playerPosition.y * 0.03125) * 32
    local entities = game.surfaces[1].find_entities_filtered({area={{chunkX, chunkY},
								  {chunkX + constants.CHUNK_SIZE, chunkY + constants.CHUNK_SIZE}},
                                                              force="player"})
    for i=1, #entities do
        print(entities[i].name)
    end
    print("--")
end

function tests.findNearestPlayerEnemy()
    local playerPosition = game.players[1].position
    local chunkX = math.floor(playerPosition.x * 0.03125) * 32
    local chunkY = math.floor(playerPosition.y * 0.03125) * 32
    local entity = game.surfaces[1].find_nearest_enemy({position={chunkX, chunkY},
                                                        max_distance=constants.CHUNK_SIZE,
                                                        force = "enemy"})
    if (entity ~= nil) then
        print(entity.name)
    end
    print("--")
end

function tests.getOffsetChunk(x, y)
    local playerPosition = game.players[1].position
    local chunkX = math.floor(playerPosition.x * 0.03125)
    local chunkY = math.floor(playerPosition.y * 0.03125)
    local chunk = mapUtils.getChunkByIndex(global.regionMap, chunkX + x, chunkY + y)
    print(serpent.dump(chunk))
end

function tests.aiStats()
    print(global.natives.points, game.tick, global.natives.state, global.natives.temperament, global.natives.stateTick, global.natives.temperamentTick)
end

function tests.fillableDirtTest()
    local playerPosition = game.players[1].position
    local chunkX = math.floor(playerPosition.x * 0.03125) * 32
    local chunkY = math.floor(playerPosition.y * 0.03125) * 32
    game.surfaces[1].set_tiles({{name="fillableDirt", position={chunkX-1, chunkY-1}},
	    {name="fillableDirt", position={chunkX, chunkY-1}},
	    {name="fillableDirt", position={chunkX-1, chunkY}},
	    {name="fillableDirt", position={chunkX, chunkY}}}, 
	false)
end

function tests.tunnelTest()
    local playerPosition = game.players[1].position
    local chunkX = math.floor(playerPosition.x * 0.03125) * 32
    local chunkY = math.floor(playerPosition.y * 0.03125) * 32
    game.surfaces[1].create_entity({name="tunnel-entrance", position={chunkX, chunkY}})
end

function tests.createEnemy(x)
    local playerPosition = game.players[1].position
    local chunkX = math.floor(playerPosition.x * 0.03125) * 32
    local chunkY = math.floor(playerPosition.y * 0.03125) * 32
    return game.surfaces[1].create_entity({name=x, position={chunkX, chunkY}})
end

function tests.registeredNest(x)
    local entity = tests.createEnemy(x)
    baseRegisterUtils.registerEnemyBaseStructure(global.regionMap,
						 entity,
						 nil)
end

function tests.attackOrigin()
    local enemy = game.surfaces[1].find_nearest_enemy({position={0,0},
                                                       max_distance = 1000})
    if (enemy ~= nil) and enemy.valid then
        print(enemy, enemy.unit_number)
        enemy.set_command({type=defines.command.attack_area,
                           destination={0,0},
                           radius=32})
    end
end

function tests.cheatMode()
    game.players[1].cheat_mode = true
    game.forces.player.research_all_technologies()
end

function tests.gaussianRandomTest()
    local result = {}
    for x=0,100,1 do
    	result[x] = 0
    end
    for _=1,10000 do
	local s = mathUtils.roundToNearest(mathUtils.gaussianRandomRange(50, 25, 0, 100), 1)
	result[s] = result[s] + 1
    end
    for x=0,100,1 do
    	print(x, result[x])
    end
end

function tests.reveal (size)
    game.player.force.chart(game.player.surface,
			    {{x=-size, y=-size}, {x=size, y=size}})
end

function tests.baseStats()
    local natives = global.natives
    print ("cX", "cY", "pX", "pY", "created", "align", "str", "upgradePoints", "#nest", "#worms", "#eggs", "hive")
    for i=1, #natives.bases do
	local base = natives.bases[i]
	local nestCount = 0
	local wormCount = 0
	local eggCount = 0
	local hiveCount = 0
	for _,_ in pairs(base.nests) do
	    nestCount = nestCount + 1
	end
	for _,_ in pairs(base.worms) do
	    wormCount = wormCount + 1
	end
	for _,_ in pairs(base.eggs) do
	    eggCount = eggCount + 1
	end
	for _,_ in pairs(base.hives) do
	    hiveCount = hiveCount + 1
	end
	print(base.x, base.y, base.created, base.alignment, base.strength, base.upgradePoints, nestCount, wormCount, eggCount, hiveCount)
	print(serpent.dump(base.tendrils))
	print("---")
    end
end

function tests.baseTiles()
    local natives = global.natives
    for i=1, #natives.bases do
	local base = natives.bases[i]
	-- local color = "concrete"
	-- if (i % 3 == 0) then
	--     color = "deepwater"
	-- elseif (i % 2 == 0) then
	--     color = "water"
	-- end
	-- for x=1,#base.chunks do
	--     local chunk = base.chunks[x]
	--     chunkUtils.colorChunk(chunk.pX, chunk.pY, color, game.surfaces[1])
	-- end
	chunkUtils.colorChunk(base.x, base.y, "deepwater-green", game.surfaces[1])
    end
end


function tests.clearBases()

    local surface = game.surfaces[1]
    for x=#global.natives.bases,1,-1 do
	local base = global.natives.bases[x]
	for c=1,#base.chunks do
	    local chunk = base.chunks[c]
	    chunkUtils.clearChunkNests(chunk, surface)
	end

	base.chunks = {}

	if (surface.can_place_entity({name="biter-spawner-powered", position={base.cX * 32, base.cY * 32}})) then
	    surface.create_entity({name="biter-spawner-powered", position={base.cX * 32, base.cY * 32}})
	    local slice = math.pi / 12
	    local pos = 0
	    for i=1,24 do
		if (math.random() < 0.8) then
		    local distance = mathUtils.roundToNearest(mathUtils.gaussianRandomRange(45, 5, 37, 60), 1)
		    if (surface.can_place_entity({name="biter-spawner", position={base.cX * 32 + (distance*math.sin(pos)), base.cY * 32 + (distance*math.cos(pos))}})) then
			if (math.random() < 0.3) then
			    surface.create_entity({name="small-worm-turret", position={base.cX * 32 + (distance*math.sin(pos)), base.cY * 32 + (distance*math.cos(pos))}})
			else
			    surface.create_entity({name="biter-spawner", position={base.cX * 32 + (distance*math.sin(pos)), base.cY * 32 + (distance*math.cos(pos))}})
			end
		    end
		end
		pos = pos + slice
	    end
	else
	    table.remove(global.natives.bases, x)	    
	end
    end
end

function tests.colorResourcePoints()
    local chunks = global.regionMap.processQueue
    for i=1,#chunks do
	local chunk = chunks[i]
	local color = "concrete"
	if (chunk[constants.RESOURCE_GENERATOR] ~= 0) and (chunk[constants.NEST_COUNT] ~= 0) then
	    color = "hazard-concrete-left"
	elseif (chunk[constants.RESOURCE_GENERATOR] ~= 0) then
	    color = "deepwater"
	elseif (chunk[constants.NEST_COUNT] ~= 0) then
	    color = "water-green"
	end
	chunkUtils.colorChunk(chunk.x, chunk.y, color, game.surfaces[1])
    end    
end

function tests.mergeBases()
    local natives = global.natives
    baseUtils.mergeBases(natives)
end

function tests.showMovementGrid()
    local chunks = global.regionMap.processQueue
    for i=1,#chunks do
	local chunk = chunks[i]
	local color = "concrete"
	if (chunk[constants.PASSABLE] == constants.CHUNK_ALL_DIRECTIONS) then
	    color = "hazard-concrete-left"
	elseif (chunk[constants.PASSABLE] == constants.CHUNK_NORTH_SOUTH) then
	    color = "deepwater"
	elseif (chunk[constants.PASSABLE] == constants.CHUNK_EAST_WEST) then
	    color = "water-green"
	end
	chunkUtils.colorChunk(chunk.x, chunk.y, color, game.surfaces[1])
    end
end

function tests.stepAdvanceTendrils()
    for _, base in pairs(global.natives.bases) do
	tendrilUtils.advanceTendrils(global.regionMap, base, game.surfaces[1], {nil,nil,nil,nil,nil,nil,nil,nil})
    end
end

return tests
