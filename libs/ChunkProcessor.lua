local chunkProcessor = {}

-- imports

local chunkUtils = require("ChunkUtils")
local constants = require("Constants")

-- constants

local CHUNK_SIZE = constants.CHUNK_SIZE

-- imported functions

local remakeChunk = chunkUtils.remakeChunk
local createChunk = chunkUtils.createChunk
local checkChunkPassability = chunkUtils.checkChunkPassability
local scoreChunk = chunkUtils.scoreChunk
local registerChunkEnemies = chunkUtils.registerChunkEnemies

-- module code

function chunkProcessor.processPendingChunks(natives, regionMap, surface, pendingStack, tick)
    local processQueue = regionMap.processQueue

    local offset = {0, 0}
    local areaBoundingBox = {false, offset}
    local query = {area=areaBoundingBox,
		   force=false}
    
    local vanillaAI = not natives.useCustomAI
    
    local chunkTiles = regionMap.chunkTiles
    
    for i=#pendingStack, 1, -1 do
        local event = pendingStack[i]
        pendingStack[i] = nil

	local topLeft = event.area.left_top
	local x = topLeft.x
	local y = topLeft.y
        local chunk = createChunk(x, y)

	areaBoundingBox[1] = chunk
	offset[1] = x + CHUNK_SIZE
	offset[2] = y + CHUNK_SIZE
	
        local chunkX = chunk.cX
        
        if regionMap[chunkX] == nil then
            regionMap[chunkX] = {}
        end
        regionMap[chunkX][chunk.cY] = chunk
        
        checkChunkPassability(chunkTiles, chunk, surface)
	if vanillaAI then
	    registerChunkEnemies(chunk, surface, query)
	else
	    remakeChunk(regionMap, chunk, surface, natives, tick, query)
	end
	scoreChunk(chunk, surface, natives, query)
        processQueue[#processQueue+1] = chunk
    end
end

return chunkProcessor
