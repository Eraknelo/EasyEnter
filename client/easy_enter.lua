-- Easier LocalPlayer:GetAimTarget() function
function LocalPlayer:EasyTarget(maxDistance)
	if maxDistance == nil then maxDistance = 100 end

	local target = {staticObject = nil, vehicle = nil}

	local entity = self:GetAimTarget().entity
	if entity and Vector3.Distance(entity:GetPosition(), self:GetPosition()) <= maxDistance then
		if class_info(entity).name == "Vehicle" then
			target.vehicle = entity
		elseif class_info(entity).name == "StaticObject" then
			target.staticObject = entity
		end
	end
	
	return target
end

class "EasyEnter"

function EasyEnter:__init()
	--if LocalPlayer:GetSteamId().string ~= "STEAM_0:0:16870054" then return end
	
	self.scrollIgnore = {
		[Action.NextWeapon] = true,
		[Action.PrevWeapon] = true
	}

	self.enterVehicleKey = Action.EnterVehicle
	self.scrollUp = Action.GuiPDAZoomIn
	self.scrollDown = Action.GuiPdaZoomOut
	self.gamepadScrollUp = Action.GuiUp
	self.gamepadScrollDown = Action.GuiDown
	self.maxDistance = 10
	self.currentVehicle = nil
	
	self.targetUpdateTimer = Timer()
	self.targetUpdateTimeout = 100
	self.inputTimeoutTimer = Timer()
	self.inputTimeout = 200
	self.lastPressTimer = Timer()
	self.lastPressTimeout = 50
	
	-- Create GUI
	self.listBox = ListBox.Create()
	self.listBox:SetVisible(false)
	self.listBox:SetSize(Vector2(100, 160))
	self.listBox:SetPositionRel(Vector2(0.6, 0.5) - (self.listBox:GetSizeRel() / 2))
	
	self.rowItems = {
		self.listBox:AddItem("Driver"),
		self.listBox:AddItem("Passenger 1"),
		self.listBox:AddItem("Passenger 2"),
		self.listBox:AddItem("Passenger 3"),
		self.listBox:AddItem("Passenger 4"),
		self.listBox:AddItem("Passenger 5"),
		self.listBox:AddItem("Mounted gun 1"),
		self.listBox:AddItem("Mounted gun 2")
	}
	
	self.rowItems[1]:SetDataNumber("seat", VehicleSeat.Driver)
	self.rowItems[2]:SetDataNumber("seat", VehicleSeat.Passenger)
	self.rowItems[3]:SetDataNumber("seat", VehicleSeat.Passenger1)
	self.rowItems[4]:SetDataNumber("seat", VehicleSeat.Passenger2)
	self.rowItems[5]:SetDataNumber("seat", VehicleSeat.Passenger3)
	self.rowItems[6]:SetDataNumber("seat", VehicleSeat.Passenger4)
	self.rowItems[7]:SetDataNumber("seat", VehicleSeat.MountedGun1)
	self.rowItems[8]:SetDataNumber("seat", VehicleSeat.MountedGun2)
	self:SetBackgrounds(self.rowItems)
	
	self.selectIndex = 1
	self.listBox:SetSelectRow(self.rowItems[self.selectIndex])
	
	-- Events
	Events:Subscribe("PreTick", self, self.PreTick)
	Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
end

function EasyEnter:SetBackgrounds(items)
	for index, item in ipairs(items) do
		item:SetBackgroundOddColor(Color(53, 53, 53))
		item:SetBackgroundEvenColor(Color(53, 53, 53))
	end
end

function EasyEnter:PreTick()
	if not self.listBox:GetVisible() or self.targetUpdateTimer:GetMilliseconds() < self.targetUpdateTimeout  then return end
	self.targetUpdateTimer:Restart()
	
	-- Check if player no longer looking at vehicle, or vehicle too far away
	local targetVehicle = LocalPlayer:EasyTarget(self.maxDistance).vehicle
	if not IsValid(self.currentVehicle) or targetVehicle ~= self.currentVehicle then
		self.currentVehicle = nil
		self.listBox:SetVisible(false)
	end
	
	-- Released enter vehicle key, but menu is currently open
	if self.lastPressTimer:GetMilliseconds() > self.lastPressTimeout then
		-- Hide window
		self.listBox:SetVisible(false)
		
		-- Vehicle no longer valid
		if not IsValid(self.currentVehicle) then return end
		
		-- Get selected seat
		local seatSelected = self.listBox:GetSelectedRow():GetDataNumber("seat")
		
		-- Already a driver in the vehicle
		if seatSelected == VehicleSeat.Driver and self.currentVehicle:GetDriver() ~= nil then return end
		
		-- Network enter vehicle event
		Network:Send("EasyEnterEnterVehicle", {vehicle = self.currentVehicle, seat = seatSelected})
	end
end

function EasyEnter:LocalPlayerInput(args)
	-- Check if enter vehicle button is pressed
	if args.input == Action.UseItem and not self.listBox:GetVisible() then
		local targetVehicle = LocalPlayer:EasyTarget(self.maxDistance).vehicle
		if targetVehicle == nil then return end -- Not looking at a vehicle
		
		self.lastPressTimer:Restart()
		
		-- Set current vehicle, select driver and show window
		self.currentVehicle = targetVehicle
		self.selectIndex = 1
		self.listBox:SetSelectRow(self.rowItems[self.selectIndex])
		self.listBox:SetVisible(true)
		
		-- Handle key press
		return false
	end
	
	local escapeKey = false
	
	-- Menu visible, check for scroll events
	if self.listBox:GetVisible() then
		if Game:GetSetting(GameSetting.GamepadInUse) == 1 and self.inputTimeoutTimer:GetMilliseconds() >= self.inputTimeout then
			if args.input == self.gamepadScrollUp then self:Scroll(true) self.inputTimeoutTimer:Restart() escapeKey = true
			elseif args.input == self.gamepadScrollDown then self:Scroll(false) self.inputTimeoutTimer:Restart() escapeKey = true end
		else
			if args.input == self.scrollUp then self:Scroll(true) escapeKey = true
			elseif args.input == self.scrollDown then self:Scroll(false) escapeKey = true end
		end
		if not escapeKey and self.scrollIgnore[args.input] then escapeKey = true end
	end
	
	-- Reset last press timer, and ignore use key
	if args.input == Action.UseItem and self.listBox:GetVisible() then self.lastPressTimer:Restart() escapeKey = true end
	
	if escapeKey then return false end
end

function EasyEnter:Scroll(up)
	if up then -- up
		self.selectIndex = self.selectIndex - 1
		if self.selectIndex < 1 then
			self.selectIndex = #self.rowItems
		end
	else -- Down
		self.selectIndex = self.selectIndex + 1
		if self.selectIndex > #self.rowItems then
			self.selectIndex = 1
		end
	end
	
	self.listBox:SetSelectRow(self.rowItems[self.selectIndex])
end

EasyEnter()