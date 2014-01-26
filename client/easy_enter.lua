class "EasyEnter"

function EasyEnter:__init()
	--if LocalPlayer:GetSteamId().string ~= "STEAM_0:0:16870054" then return end

	self.key = string.byte("Y")
	self.scrollUp = Action.GuiPdaZoomOut
	self.scrollDown = Action.GuiPDAZoomIn
	self.maxDistance = 10
	self.currentVehicle = nil
	
	-- Create GUI	
	self.listBox = ListBox.Create()
	self.listBox:SetVisible(false)
	self.listBox:SetSize(Vector2(100, 170))
	self.listBox:SetPositionRel(Vector2(0.6, 0.5) - (self.listBox:GetSizeRel() / 2))
	
	self.rowItems = {
		self.listBox:AddItem("V Select V"),
		self.listBox:AddItem("Driver"),
		self.listBox:AddItem("Passenger 1"),
		self.listBox:AddItem("Passenger 2"),
		self.listBox:AddItem("Passenger 3"),
		self.listBox:AddItem("Passenger 4"),
		self.listBox:AddItem("Passenger 5"),
		self.listBox:AddItem("Mounted gun 1"),
		self.listBox:AddItem("Mounted gun 2")
	}
	
	self.rowItems[1]:SetTextColor(Color(255, 0, 0))
	
	self.rowItems[1]:SetDataNumber("seat", -1)
	self.rowItems[2]:SetDataNumber("seat", VehicleSeat.Driver)
	self.rowItems[3]:SetDataNumber("seat", VehicleSeat.Passenger)
	self.rowItems[4]:SetDataNumber("seat", VehicleSeat.Passenger1)
	self.rowItems[5]:SetDataNumber("seat", VehicleSeat.Passenger2)
	self.rowItems[6]:SetDataNumber("seat", VehicleSeat.Passenger3)
	self.rowItems[7]:SetDataNumber("seat", VehicleSeat.Passenger4)
	self.rowItems[8]:SetDataNumber("seat", VehicleSeat.MountedGun1)
	self.rowItems[9]:SetDataNumber("seat", VehicleSeat.MountedGun2)
	self:SetBackgrounds(self.rowItems)
	
	self.selectIndex = 1
	self.listBox:SetSelectRow(self.rowItems[self.selectIndex])
	
	-- Events
	Events:Subscribe("KeyDown", self, self.KeyDown)
	Events:Subscribe("KeyUp", self, self.KeyUp)
	Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
end

function EasyEnter:SetBackgrounds(items)
	for index, item in ipairs(items) do
		item:SetBackgroundOddColor(Color(53, 53, 53))
		item:SetBackgroundEvenColor(Color(53, 53, 53))
	end
end

function EasyEnter:KeyDown(args)
	if self.listBox:GetVisible() or args.key ~= self.key or Game:GetState() ~= GUIState.Game then return true end
	
	local aimTarget = LocalPlayer:GetAimTarget()
	local entity = aimTarget.entity
	if not entity or class_info(aimTarget.entity).name ~= "Vehicle" or Vector3.Distance(aimTarget.entity:GetPosition(), LocalPlayer:GetPosition()) > self.maxDistance then return end
	
	self.currentVehicle = entity
	self.selectIndex = 1
	self.listBox:SetSelectRow(self.rowItems[self.selectIndex])
	self.listBox:SetVisible(true)
end

function EasyEnter:KeyUp(args)
	if not self.listBox:GetVisible() or args.key ~= self.key then return true end
	self.listBox:SetVisible(false)
	
	if self.currentVehicle == nil or not IsValid(self.currentVehicle) then return end
	
	local seatSelected = self.listBox:GetSelectedRow():GetDataNumber("seat")
	if seatSelected == -1 then return end
	
	if seatSelected == VehicleSeat.Driver and self.currentVehicle:GetDriver() ~= nil then return end
	
	Network:Send("EasyEnterEnterVehicle", {vehicle = self.currentVehicle, seat = seatSelected})
end

function EasyEnter:LocalPlayerInput(args)
	if not self.listBox:GetVisible() then return true end
	if args.input ~= self.scrollUp and args.input ~= self.scrollDown then return false end
	
	if args.input ~= self.scrollUp then -- up
		self.selectIndex = self.selectIndex - 1
		if self.selectIndex < 1 then
			self.selectIndex = #self.rowItems
		end
	elseif args.input ~= self.scrollDown then -- Down
		self.selectIndex = self.selectIndex + 1
		if self.selectIndex > #self.rowItems then
			self.selectIndex = 1
		end
	end
	
	self.listBox:SetSelectRow(self.rowItems[self.selectIndex])
end

EasyEnter()