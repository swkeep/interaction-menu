if not DEVMODE then return end

exports['interactionMenu']:createGlobal {
    type = 'entities',
    offset = vec3(0, 0, 0),
    maxDistance = 1.0,
    options = {
        {
            label = '[Debug] On All Entities',
            icon = 'fa fa-bug',
            action = function(entity)
                print(entity)
            end
        }
    }
}

exports['interactionMenu']:createGlobal {
    type = 'peds',
    offset = vec3(0, 0, 0),
    maxDistance = 1.0,
    options = {
        {
            label = '[Debug] On All Peds',
            icon = 'fa fa-person',
            action = function(entity)
                print(entity)
            end
        }
    }
}

exports['interactionMenu']:createGlobal {
    type = 'vehicles',
    offset = vec3(0, 0, 0),
    maxDistance = 1.0,
    options = {
        {
            label = '[Debug] On All Vehicles',
            icon = 'fa fa-car',
            action = function(entity)
                print(entity)
            end
        }
    }
}

exports['interactionMenu']:createGlobal {
    type = 'bones',
    bone = 'platelight',
    offset = vec3(0, 0, 0),
    maxDistance = 1.0,
    options = {
        {
            label = '[Debug] On All plates',
            icon = 'fa fa-rectangle-ad',
            action = function(entity)
                print('Plate:', GetVehicleNumberPlateText(entity))
            end
        }
    }
}

exports['interactionMenu']:createGlobal {
    type = 'players',
    offset = vec3(0, 0, 0),
    maxDistance = 1.0,
    options = {
        {
            label = '[Debug] On All Players',
            icon = 'fa fa-person',
            action = function(entity)
                print(entity)
            end
        }
    }
}

exports['interactionMenu']:createGlobal {
    type = 'zones',
    options = {
        {
            label = '[Debug] On All Zones',
            icon = 'fa fa-person',
            action = function(data)
                Util.print_table(data)
            end
        }
    }
}
