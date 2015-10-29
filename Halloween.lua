GM_LOGIN = "gm"
WIDGET_SCORES_IDX = 1
WIDGET_NOTIFICATIONS_IDX = 2

PlayerTypes = {player=1,master=2}

-- Utilities
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- Extended table class
ExtTable = {}
ExtTable.__index = ExtTable

function ExtTable.create(items)
	items = items or {}
	local new_inst = {}
	setmetatable(new_inst, ExtTable)
	new_inst.items = items
	return new_inst
end

function ExtTable:count()
	local count = 0
	
	for _,v in ipairs(self.items) do
		count = count + 1
	end
	
	return count
end

function ExtTable:insert(item)
	table.insert(self.items, item)
end

function ExtTable:remove(pos)
	table.remove(self.items, pos)
end

function ExtTable:find(field, value)
	local i = self:indexOf(field, value)
	
	if i ~= nil then
		return self.items[i]
	else
		return nil
	end
end

function ExtTable:indexOf(field, value)
	for i,v in ipairs(self.items) do
		if v[field] == value then
			return i
		end
	end
	
	return nil
end

function ExtTable:clone()
	return deepcopy(self)
end

-- Game class
Game = {id=0, players={}}

function Game:new (o)
	o = o or {}

	setmetatable(o, self)
	o.players = ExtTable.create({});
	self.__index = self
	return o
end

function Game:addPlayer(player)
	local function goThere(event)
        local place = player.places:find("id", event.id)
        player:clearUI()
        geo.ui.append(player_id, geo.widget.text(
            "En direction de " .. place.text
        ))
		geo.ui.append(player.id, geo.widget.text("{{"..place.image.."}}"))
        geo.ui.append(player.id, geo.widget.compass{
			target = { lat = place.location.lat, lon = place.location.lon };
			radius = 300;
			onInRange = function(event)
				geo.ui.append(player.id, geo.widget.text(
					"A proximité du lieu : "..place.text
				))
			end
		})
		geo.ui.append(player.id, geo.widget.button{
			text = "Lieux";
			onClick = function(event)
				player:showMainScreen()
			end
		})
		player:refreshScores()
    end
	
	self.players:insert(player)
	player.places = self.getPlaces()
	
	for _,v in ipairs(player.places) do
		v.onSelected = goThere
	end
	
	player.game = self
end

function Game.getPlaces(callback)
	local places = ExtTable.create(
		{ -- Liste des lieux
			{
			id = '51';
			image = 'http://drive.google.com/uc?export=view&id=0BwZAY0N3lE7tRUhSV1d4VXJZYXM';
			text = 'Bosquet 1';
			location = { lat = 45.722428, lon = 4.823955 };
			stuff = "blood wine";
			stuff_image = "http://pataguilde.16mb.com/images/blood_wine.jpg";
			onSelected = callback ;
			},
			{
			id = '52';
			image = 'http://drive.google.com/uc?export=view&id=0BwZAY0N3lE7tLXJ0VW1BMkJyLTQ';
			text = 'Bosquet 2';
			location = { lat = 45.722101, lon = 4.823341 };
			stuff = "demon brew";
			stuff_image = "http://pataguilde.16mb.com/images/demon_brew.jpg";
			onSelected = callback;
			},
			{
			id = '53';
			image = 'http://drive.google.com/uc?export=view&id=0BwZAY0N3lE7tenRHcGJLWkVFajQ';
			text = 'Bosquet 3';
			location = { lat = 5.237222, lon = -52.760556 };
			stuff = "spider blood";
			stuff_image = "http://pataguilde.16mb.com/images/spider_blood.jpg";
			onSelected = callback;
			},
			{
			id = '54';
			image = 'http://drive.google.com/uc?export=view&id=0BwZAY0N3lE7tMDA0dXc4MFRIMHc';
			text = 'Bosquet A';
			location = { lat = 45.722619, lon = 4.822654};
			stuff = "zombie virus";
			stuff_image = "http://pataguilde.16mb.com/images/zombie_virus.jpg";
			onSelected = callback;
			},
			{
			id = '100';
			image = 'http://pataguilde.16mb.com/images/graveyard.png';
			text = 'Cimetière';
			location = { lat = 0, lon = 0 };
			stuff = "blood wine";
			stuff_image = "http://pataguilde.16mb.com/images/graveyard.png";
			onSelected = callback ;
			}
		}
	)

	return places
end

function Game:getScoreTable()
	local creole = "|=Joueur |=Objets trouvés"	-- entêtes
	
	for _,v in ipairs(self.players.items) do
		if v:getType() == PlayerTypes.player then
			creole = creole.."\n" -- line break
			creole = creole.."|"..tostring(v.name).."	|"..tostring(v.found:count()) -- score de chaque joueur
		end
	end

	return creole
end

function Game:broadcastScores()
	for _,v in ipairs(self.players.items) do
		v:refreshScores()
	end
end

function Game:broadcastNotification(notification)
	for _,v in ipairs(self.players.items) do
		v:showNotification(notification)
	end
end

function Game:broadcastPositions()
	for _,v in ipairs(self.players.items) do
		if v:getType() == PlayerTypes.master then
			v:refreshScores()
		end
	end
end

-- function goToFinalPlace(player_id)
	-- local player = myPlayers:find("id", player_id)
	-- player.places = getFinalPlace()
-- end

function Game:getPlayerPositions()
	local positions = ExtTable.create()
	
	for _,v in ipairs(self.players.items) do
		if v:getType() == PlayerTypes.player then
			local pos = {}
			pos.id = tostring(v.id)
			pos.text = v.name.." ("..tostring(v.found:count())..")"
			pos.location = {}
			pos.location.lat = v.position.lat
			pos.location.lon = v.position.lon
			pos.image = "http://pataguilde.16mb.com/images/icon_user_48.png"
			positions:insert(pos)
		end
	end
	
	return positions
end

-- Player class
Player = {id=0, name="", places={}}

function Player:new (o)
	o = o or {}

	setmetatable(o, self)
	o.found = ExtTable.create({});
	o.widgets = {
		scores = nil;
		notifications = nil;
		positions = nil;
	};
	o.position = {lat = 0, lon=0}
	self.__index = self
	return o
end

-- Fonction pour vider l'interface graphique du joueur
function Player.getType()
	return PlayerTypes.player
end

function Player:clearUI()
	--for _,v in ipairs(self.widgets) do
		--v = nil
	--end
	
	self.widgets.scores = nil
	self.widgets.notifications = nil
	self.widgets.positions = nil
	geo.ui.clear(self.id)
end

function Player:refreshScores(players)
	local scores = self.game:getScoreTable()
	local widget = geo.widget.text(scores)
	local widget_id = self.widgets.scores
	
	if widget_id ~= nil then
		widget_id = geo.ui.replace(self.id, widget_id, widget)
	else
		widget_id = geo.ui.insert(self.id, WIDGET_SCORES_IDX, widget)
	end
	
	self.widgets.scores = widget_id
end

function Player:showNotification(notification)
	local widget = geo.widget.text("**"..notification.."**")
	local widget_id = self.widgets.notifications
	
	if widget_id ~= nil then
		widget_id = geo.ui.replace(self.id, widget_id, widget)
	else
		widget_id = geo.ui.insert(self.id, WIDGET_NOTIFICATIONS_IDX, widget)
	end
	
	self.widgets.notifications = widget_id
end

-- Affiche l'interface principale
function Player:showMainScreen(players)
	self:clearUI()
	self:refreshScores(players)

	geo.ui.append(self.id, geo.widget.places{
		places = self.places.items
	})
end

function Player:getInventory()
	local inventory = ""

	for _,v in ipairs(self.found.items) do
		if inventory ~= "" then
			inventory = inventory.."\n"
		end
		
		inventory = inventory.."* "..v.stuff
	end
	
	return geo.widget.text(inventory)
end

-- Game Master class
GameMaster = Player:new{}

GameMaster.getType = function()
	return PlayerTypes.master
end

function GameMaster:refreshPositions()
	local positions = self.game:getPlayerPositions()
	
	for _,v in ipairs(positions.items) do
		local player = self.game.players:find("id", tonumber(v.id))
		v.onSelected = self:showPlayer
	end
	
	local widget = geo.widget.places{places = positions.items}
	local widget_id = self.widgets.positions
	
	if widget_id ~= nil then
		widget_id = geo.ui.replace(self.id, widget_id, widget)
	else
		widget_id = geo.ui.insert(self.id, WIDGET_SCORES_IDX, widget)
	end
	
	self.widgets.positions = widget_id
end

function GameMaster:showMainScreen(players)
	self:clearUI()
	self:refreshPositions(players)
end

function GameMaster:showPlayer(player)
	local inventory = ""
	
	self:clearUI()
	geo.ui.append(self.id, geo.widget.text(
		player.name
	))
	geo.ui.append(self.id, geo.widget.compass{
		target = { lat = player.position.lat, lon = player.position.lon };
		radius = 300;
		onInRange = function(event)
		end
	})
	geo.ui.append(self.id, player:getInventory())
	geo.ui.append(self.id, geo.widget.button{
		text = "Retour";
		onClick = function(event)
			self:showMainScreen()
		end
	})
end

function GameMaster:refreshScores()
	self:refreshPositions()
end

-- Variables globales
myGame = Game:new({id=GAME_ID}) -- Contexte du jeu

-- function getFinalPlace(callback)
	-- local places = ExtTable.create(
		-- { -- Liste des lieux
			-- {
			-- id = '100';
			-- image = 'http://drive.google.com/uc?export=view&id=0BwZAY0N3lE7tRUhSV1d4VXJZYXM';
			-- text = 'Bosquet 1';
			-- location = { lat = 45.722428, lon = 4.823955 };
			-- stuff = "blood wine";
			-- stuff_image = "http://pataguilde.16mb.com/images/graveyard.png";
			-- onSelected = callback ;
			-- }
		-- }
	-- )

	-- return places
-- end

geo.event.join(function(event)
    local player_id = event.player_id	
	local player = Player:new({id=player_id, name=""})
    myGame:addPlayer(player)
    geo.feature.gps(player_id, true) -- activate GPS
	geo.ui.append(player_id, geo.widget.text(
			"Entrez votre nom"
	))	
	geo.ui.append(player_id, geo.widget.input{
        text = "Rejoindre";
        onSubmit = function(event)
			if event.value == GM_LOGIN then
				local gm = GameMaster:new({id=player_id, name=event.value})
				myGame:addPlayer(gm) -- Ajout d'un GM
				gm:showMainScreen()
			else
				local player = Player:new({id=player_id, name=event.value})
				myGame:addPlayer(player)
				myGame.broadcastScores()
				myGame.broadcastNotification(player.name.." a rejoint la partie.")
				geo.ui.append(player_id, geo.widget.text(
					"Bienvenue, " .. event.value
				))
				geo.ui.append(player_id, geo.widget.button{
					text = "Commencer à jouer";
					onClick = function(event)
						player:showMainScreen()
					end
				})			
			end
        end
    })
end)

geo.event.qr_scan(function(event)
    local player_id = event.player_id
	local place_id = tostring(event.via_id)
	--local place = myPlaces:find("id", place_id)
	local player = myGame.players:find("id", player_id)
	local place_idx = player.places:indexOf("id", place_id)

	if place_idx ~= nil then
		local place = player.places:remove(place_idx)
		player.found:insert(place)
		player:clearUI()
		geo.ui.append(player_id, geo.widget.text("Félicitations! Vous avez validé un objectif!"))
		--geo.game.badge(player_id, event.via_id) -- gives badge to player
		--geo.ui.append(player_id, geo.widget.text("<<badge("..event.via_id..")>>")) -- show badge to player
		geo.ui.append(player_id, geo.widget.text("{{"..place.stuff_image.."}}"))
		myGame:broadcastScores()
		myGame:broadcastNotification(player.name.." a trouvé : "..place.stuff)
	end
	
	if player.places:count() == 0 then
		geo.ui.append(event.player_id, geo.widget.text("Vous avez trouvé tous les lieux!"))
	end
	
	geo.ui.append(event.player_id, geo.widget.button{
        text = "Main screen";
        onClick = function(event)
			player:showMainScreen()
		end
    })
end)

geo.event.location(function(event)
	local player = myGame.players:find("id", event.player_id)
	--geo.ui.append(event.player_id, geo.widget.text("Nouvelle position : "..event.pos.lat..","..event.pos.lon))
	player.position.lat = event.pos.lat
	player.position.lon = event.pos.lon
	myGame:broadcastPositions()
end)
-- global functions


