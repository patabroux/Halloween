myPlayers = {} -- Liste des joueurs actifs

geo.event.join(function(event)
    local player_id = event.player_id
    table.insert(myPlayers, player_id)
    myPlayers[player_id] = {
      id = player_id;
      found = {};
    } -- liste des objets trouvés
    geo.feature.gps(player_id, true) -- activate GPS
    
    local function goThere(event) 
        local place = myPlaces.find(event.id)
        geo.ui.clear(player_id)
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
    end 
    
    myPlaces = { -- Liste des lieux
      {
        id = '51';
        image = 'http://drive.google.com/uc?export=view&id=0BwZAY0N3lE7tRUhSV1d4VXJZYXM';
        text = 'Bosquet 1';
        location = { lat = 45.722428, lon = 4.823955 };
        onSelected = goThere ;
      },
      {
        id = '52';
        image = 'http://drive.google.com/uc?export=view&id=0BwZAY0N3lE7tLXJ0VW1BMkJyLTQ';
        text = 'Bosquet 2';
        location = { lat = 45.722101, lon = 4.823341 };
        onSelected = goThere;
      },
      {
        id = '53';
        image = 'http://drive.google.com/uc?export=view&id=0BwZAY0N3lE7tenRHcGJLWkVFajQ';
        text = 'Bosquet 3';
        location = { lat = 5.237222, lon = -52.760556 };
        onSelected = goThere;
      },
      {
        id = '54';
        image = 'http://drive.google.com/uc?export=view&id=0BwZAY0N3lE7tMDA0dXc4MFRIMHc';
        text = 'Bosquet 4';
        location = { lat = 45.722619, lon = 4.822654};
        onSelected = goThere;
      } 
    }
    
    myPlaces.find = function(id)
      for _,v in pairs(myPlaces) do
        if v.id == id then
          return v
        end
      end
      
      return nil
    end

   geo.ui.append(player_id, geo.widget.places{
        places = myPlaces
    })
end)

geo.event.qr_scan(function(event)
    local player_id = event.player_id
	local place = myPlaces:find(event.via_id)
	
	if place ~= nil then
		table.insert(myPlayers[player_id].found, event.via_id)
		geo.ui.clear()
		geo.ui.append(player_id, geo.widget.text("Félicitations! Vous avez validé un objectif!"))
		geo.game.badge(player_id, event.via_id) -- gives badge to player
		geo.ui.append(player_id, geo.widget.text("<<badge("..event.via_id..")>>")) -- show badge to player
	end
	
    table.insert(myPlayers[player_id].found, event.via_id)
    geo.ui.clear(player_id)
    geo.game.badge(player_id, event.via_id) -- gives badge to player
    geo.ui.append(player_id, geo.widget.text("<<badge("..event.via_id..")>>")) -- show badge to player
end)



