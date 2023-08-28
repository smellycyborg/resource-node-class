local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Signal)

local DEFAULT_POINTS = 100
local DEFAULT_SCALE = 100

local resource = {}
local resourcePrototype = {}
local resourcePrivate = {}

local function _logarithmicFunction(level)
	local maxResult = 2^64 - 1  -- Maximum value for a 64-bit integer in Lua
	local basePoints = DEFAULT_POINTS      -- Starting points value
	local initialScaleFactor = DEFAULT_SCALE
	local scaleFactorIncrement = 2000  -- Adjust this to control how quickly the increase changes

	local scaleFactor = initialScaleFactor + (scaleFactorIncrement * (level - 1)) 
	local result = basePoints + scaleFactor * math.log(level)
	
	return math.floor(result, maxResult)  -- Cap the result at maxResult
end

function resource.new(player: Player, model: Model, level: number)
	local self = {}
	local private = {}
	
	local resourcesFolder = player:FindFirstChild("ResourceNodes")
	if not resourcesFolder then
		resourcesFolder = Instance.new("Folder", player)
		resourcesFolder.Name = "ResourceNodes"
	end
	
	self.noMorePoints = Signal.new()
	self.pointsChanged = Signal.new()
	
	private.gatherers = {}
	private.owner = player
	private.model = model
	private.points = Instance.new("IntValue", resourcesFolder)
	
	local points = private.points
	
	points.Value = _logarithmicFunction(level)
	points.Name = "Points"
	
	points:GetPropertyChangedSignal("Value"):Connect(function()
		local newPoints = private.points.Value
		
		if newPoints <= 0 then
			self.noMorePoints:Fire(player)
			
			return
		end
		
		self.pointsChanged:Fire(player, newPoints)
	end)
	
	resourcePrivate[self] = private
	
	return setmetatable(self, resourcePrototype)
end

function resourcePrototype:spawnModel(position)
	local private = resourcePrivate[self]
	
	private.model.CFrame = CFrame.new(position)
  private.model.Parent = workspace
end

function resourcePrototype:subtractPoints(amount)
	local private = resourcePrivate[self]
	
	private.points.Value-=amount
end

function resourcePrototype:addGatherer(gatherer)
	local private = resourcePrivate[self]
	
	table.insert(private.gatherers, gatherer)
end

function resourcePrototype:removeGatherer(gatherer)
	local private = resourcePrivate[self]
	
	table.remove(private.gatherers, table.find(private.gatherers, gatherer))
end

function resourcePrototype:getGatherers()
	return resourcePrivate[self].gatherers
end

function resourcePrototype:destroy()
	local private = resourcePrivate[self]
	
	private.model:Destroy()
	private.points:Destroy()
	
	self.noMorePoints:Destroy()
	self.pointsChanged:Destroy()
	self = nil
end

resourcePrototype.__index = resourcePrototype
resourcePrototype.__metatable = "This metatable is locked."
resourcePrototype.__newindex = function(_, _, _)
	error("This metatable is locked.")
end

return resource
