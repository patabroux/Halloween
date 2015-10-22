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

-- Player class
Player = {}
Player.__index = Player

function Player.create(id, name, places)
	local new_inst = {}
	setmetatable(new_inst, Player)
	new_inst.id = id
	new_inst.name = name
	new_inst.places = places
	new_inst.found = ExtTable.create({});
	new_inst.widgets = {
		scores = nil;
		notifications = nil;
	};

	return new_inst
end

-- Fonction pour vider l'interface graphique du joueur
function Player:clearUI()
	--for _,v in ipairs(self.widgets) do
		--v = nil
	--end
	
	self.widgets.scores = nil
	self.widgets.notifications = nil
	geo.ui.clear(self.id)
end

function Player:showScores()
	local scores = getScoreTable()
	local widget = geo.widget.text(scores)
	local widget_id = self.widgets.scores
	
	if widget_id ~= nil then
		widget_id = geo.ui.replace(self.id, widget_id, widget)
	else
		widget_id = geo.ui.insert(self.id, 1, widget)
	end
	
	self.widgets.scores = widget_id
end

function Player:showNotification(notification)
	local widget = geo.widget.text("**"..notification.."**")
	local widget_id = self.widgets.notifications
	
	if widget_id ~= nil then
		widget_id = geo.ui.replace(self.id, widget_id, widget)
	else
		widget_id = geo.ui.insert(self.id, 2, widget)
	end
	
	self.widgets.notifications = widget_id
end

-- Variables globales
myPlayers = ExtTable.create({}) -- Liste des joueurs actifs

function getPlaces(callback)
	local places = ExtTable.create(
		{ -- Liste des lieux
			{
			id = '51';
			image = 'http://drive.google.com/uc?export=view&id=0BwZAY0N3lE7tRUhSV1d4VXJZYXM';
			text = 'Bosquet 1';
			location = { lat = 45.722428, lon = 4.823955 };
			stuff = "bave de crapaud";
			onSelected = callback ;
			},
			{
			id = '52';
			image = 'http://drive.google.com/uc?export=view&id=0BwZAY0N3lE7tLXJ0VW1BMkJyLTQ';
			text = 'Bosquet 2';
			location = { lat = 45.722101, lon = 4.823341 };
			stuff = "aile de chauve-souris";
			onSelected = callback;
			},
			{
			id = '53';
			image = 'http://drive.google.com/uc?export=view&id=0BwZAY0N3lE7tenRHcGJLWkVFajQ';
			text = 'Bosquet 3';
			location = { lat = 5.237222, lon = -52.760556 };
			stuff = "poudre d'os";
			onSelected = callback;
			},
			{
			id = '54';
			image = 'http://drive.google.com/uc?export=view&id=0BwZAY0N3lE7tMDA0dXc4MFRIMHc';
			text = 'Bosquet A';
			location = { lat = 45.722619, lon = 4.822654};
			stuff = "compote de sangsue";
			onSelected = callback;
			} 
		}
	)

	return places
end

geo.event.join(function(event)
    local player_id = event.player_id
	
	local function goThere(event)
		local player = myPlayers:find("id", player_id)
        local place = player.places:find("id", event.id)
        player:clearUI()
        geo.ui.append(player_id, geo.widget.text(
            "Going to " .. event.id
        ))
        geo.ui.append(player_id, geo.widget.compass{
			target = { lat = place.location.lat, lon = place.location.lon };
			radius = 300;
			onInRange = function(event)
				geo.ui.append(player_id, geo.widget.text(
					"Welcome to Alcatraz"
				))
			end
		})
		geo.ui.append(player_id, geo.widget.button{
			text = "Places";
			onClick = function(event)
				showMainScreen(player_id)
			end
		})
		player:showScores()
    end
	
	local player = Player.create(player_id, "", getPlaces(goThere))
    myPlayers:insert(player)
    geo.feature.gps(player_id, true) -- activate GPS
	showJoinScreen(player_id)
end)

geo.event.qr_scan(function(event)
    local player_id = event.player_id
	local place_id = tostring(event.via_id)
	--local place = myPlaces:find("id", place_id)
	local player = myPlayers:find("id", player_id)
	local place_idx = player.places:indexOf("id", place_id)

	if place_idx ~= nil then
		local place = player.places.items[place_idx]
		player.places:remove(place_idx)
		player.found:insert(place_id)
		player:clearUI()
		geo.ui.append(player_id, geo.widget.text("Félicitations! Vous avez validé un objectif!"))
		geo.game.badge(player_id, event.via_id) -- gives badge to player
		geo.ui.append(player_id, geo.widget.text("<<badge("..event.via_id..")>>")) -- show badge to player
		broadcastScores()
		broadcastNotification(player.name.." a trouvé : "..place.stuff)
	end
	
	if player.places:count() == 0 then
		geo.ui.append(event.player_id, geo.widget.text("Vous avez trouvé tous les lieux!"))
	end
	
	geo.ui.append(event.player_id, geo.widget.button{
        text = "Main screen";
        onClick = function(event)
			showMainScreen(player_id)
		end
    })
end)

-- Affiche l'interface principale
function showMainScreen(player_id)
	local player = myPlayers:find("id", player_id)
	player:clearUI()
	player:showScores()
	
	geo.ui.append(player_id, geo.widget.places{
        places = player.places.items
    })
	
	geo.ui.append(player_id, geo.widget.button{ -- bouton de fermeture du jeu
        text = "Close game";
        onClick = function(event)
            geo.game.close()
        end
    })
	
	geo.ui.append(player_id, geo.widget.text("[[https://youtu.be/IudAgC00RfY|Atmosfear]]"))
end

function getScoreTable()
	local creole = "|=Joueur |=Objets trouvés"	-- entêtes
	
	for _,v in ipairs(myPlayers.items) do
		creole = creole.."\n" -- line break
		creole = creole.."|"..tostring(v.name).."	|"..tostring(v.found:count()) -- score de chaque joueur
	end

	return creole
end

-- function showScores(player_id)
	-- local scores = getScoreTable()
	-- local player = myPlayers:find("id", player_id)
	-- local widget = geo.widget.text(scores)
	-- local widget_id = player.widgets.scores
	
	-- if widget_id ~= nil then
		-- widget_id = geo.ui.replace(player_id, widget_id, widget)
	-- else
		-- widget_id = geo.ui.insert(player_id, 1, geo.widget.text(scores))
	-- end
	
	-- player.widgets.scores = widget_id
-- end

function broadcastScores()
	for _,v in ipairs(myPlayers.items) do
		v:showScores()
	end
end

function broadcastNotification(notification)
	for _,v in ipairs(myPlayers.items) do
		v:showNotification(notification)
	end
end

function showJoinScreen(player_id)
	local player = myPlayers:find("id", player_id)
	geo.ui.append(player_id, geo.widget.text(
			"Entrez votre nom"
	))	
	geo.ui.append(player_id, geo.widget.input{
        text = "Rejoindre";
        onSubmit = function(event)
			player:clearUI()
			player.name = event.value
			broadcastScores()
			broadcastNotification(player.name.." a rejoint la partie.")
            geo.ui.append(player_id, geo.widget.text(
                "Bienvenue, " .. event.value
            ))
			geo.ui.append(player_id, geo.widget.button{
				text = "Commencer à jouer";
				onClick = function(event)
					showMainScreen(player_id)
				end
			})
        end
    })
end

