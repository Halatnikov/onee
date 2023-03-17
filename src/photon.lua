local myActor, myRoom

local client = require("photon.loadbalancing.LoadBalancingClient")
local constants = require("photon.loadbalancing.constants")
local logger = require("photon.common.Logger")
local tableutil = require("photon.common.util.tableutil") 

local photon = client.new("ns.exitgames.com:5058", "8d2e8053-fa0c-41a7-87a1-afa119efbaf7", version)
photon:connectToRegionMaster("US")

function photon_update()
	if frames%3 == 0 then -- tic rate of 20
		photon:service()
	end
end

-- use enums for event numbers
-- search for all package.preload in photon.lua
function photon:onStateChange(state)
	if state == client.State.ConnectedToMaster then
		myActor = photon:myActor()
		myActor:setName("scruffy real")
	end
    if state == client.State.JoinedLobby then
        photon:createRoom("peepee poopoo online") -- for some reason only works after you restart once(???), possibly tick rate related but probably not?
    end
	if state == client.State.Joined then
		myRoom = photon:myRoom()
		--print(tableutil.toStringReq(myRoom))
		print(myActor.name)
    end
end