Network:Subscribe("EasyEnterEnterVehicle", function(args, player)
	player:EnterVehicle(args.vehicle, args.seat)
end)