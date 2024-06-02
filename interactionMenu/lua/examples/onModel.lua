--                _
--               | |
--   _____      _| | _____  ___ _ __
--  / __\ \ /\ / / |/ / _ \/ _ \ '_ \
--  \__ \\ V  V /|   <  __/  __/ |_) |
--  |___/ \_/\_/ |_|\_\___|\___| .__/
--                             | |
--                             |_|
-- https://github.com/swkeep
if not DEVMODE then return end

CreateThread(function()
    -- spawn two objects of same model
    local coords = vector4(-1996.28, 3161.06, 31.81, 103.8)
    Util.spawnObject(`xm_prop_crates_sam_01a`, coords)

    exports['interactionMenu']:Create {
        type = 'model',
        id = 'Harmony',
        model = `xm_prop_crates_sam_01a`,
        offset = vec3(0, 0, 0.5),
        maxDistance = 2.0,
        indicator = {
            prompt   = 'F',
            keyPress = {
                -- https://docs.fivem.net/docs/game-references/controls/#controls
                padIndex = 0,
                control = 23
            },
        },
        options = {
            {
                label = "Open",
                action = {
                    type = 'sync',
                    func = function(e)
                        Wait(2000)
                        TriggerServerEvent("inventory:server:OpenInventory", "stash", 'CRATE1', {
                            slots = 10,
                            maxweight = 100000
                        })
                    end
                }
            },
            {
                icon = "fas fa-spinner",
                label = "Spinner",
                action = {
                    type = 'sync',
                    func = function(e)
                        Wait(1000)
                        print('HEY')
                    end
                }
            },
            {
                label = "rgb(50,100,50)",
                style = {
                    color = {
                        label = 'rgb(50,255,50)',
                    }
                }
            },
            {
                label = "rgb(250,0,50)",
                style = {
                    color = {
                        label = 'rgb(250,0,50)',
                    }
                }
            },
            {
                icon = "fas fa-spinner",
                label = "rgb(0,0,250)",
                style = {
                    color = {
                        background = 'wheat',
                        label = 'rgb(0,0,250)',
                    }
                },
                action = {
                    type = 'sync',
                    func = function(e)
                        Wait(2000)
                        print('HEY')
                    end
                }
            }
        }
    }

    exports['interactionMenu']:Create {
        type = 'model',
        model = `adder`,
        offset = vec3(0, 0, 0),
        maxDistance = 2.0,
        indicator = {
            prompt   = 'E',
            keyPress = {
                -- https://docs.fivem.net/docs/game-references/controls/#controls
                padIndex = 0,
                control = 38
            },
        },
        options = {
            {
                label = "[Debug] On adder",
                icon = 'fa fa-car',
                action = {
                    type = 'sync',
                    func = function(e)
                        Wait(1000)
                        print('HEY')
                    end
                }
            }
        }
    }

    exports['interactionMenu']:Create {
        type = 'model',
        model = `v_ilev_ph_cellgate`,
        offset = vec3(-0.6, 0, 0),
        maxDistance = 4.0,
        extra = {
            onSeen = function(e)
            end
        },
        indicator = {
            prompt   = 'E',
            keyPress = {
                -- https://docs.fivem.net/docs/game-references/controls/#controls
                padIndex = 0,
                control = 38
            },
        },
        options = {
            {
                label = "Open Door",
                action = {
                    type = 'sync',
                    func = function(entity)
                        Wait(1000)
                        print('HEY')
                    end
                }
            },
        }
    }

    exports['interactionMenu']:Create {
        type = 'model',
        model = `prop_vend_snak_01`,
        offset = vec3(0, 0, 0),
        maxDistance = 2.0,
        extra = {
            job = {
                ['police'] = { 1, 3, 2 }
            },
        },
        indicator = {
            prompt   = 'F',
            keyPress = {
                -- https://docs.fivem.net/docs/game-references/controls/#controls
                padIndex = 0,
                control = 23
            },
        },
        options = {
            {
                label = 'Job Access: Police',
                icon = 'fa fa-handcuffs',
                action = {
                    func = function()

                    end
                }
            }
        }
    }

    local id = exports['interactionMenu']:Create {
        type = 'model',
        model = `prop_vend_snak_01`,
        offset = vec3(0, 0, 0),
        maxDistance = 2.0,
        indicator = {
            prompt   = 'F',
            keyPress = {
                -- https://docs.fivem.net/docs/game-references/controls/#controls
                padIndex = 0,
                control = 23
            },
        },
        options = {
            {
                label = 'First On Model',
                icon = 'fa fa-book',
                action = {
                    func = function(e)
                    end
                }
            }
        }
    }

    exports['interactionMenu']:Create {
        type = 'model',
        model = `prop_vend_snak_01`,
        offset = vec3(0, 0, 0),
        maxDistance = 2.0,
        options = {
            {
                label = 'Second On Model',
                icon = 'fa fa-book',
                action = {
                    func = function(e)
                    end
                },
            }
        }
    }


    coords = vector4(-1999.05, 3178.58, 31.81, 147.54)
    Util.spawnObject(`prop_paper_bag_01`, coords)
    coords = vector4(-1999.05, 3179.58, 31.81, 147.54)
    Util.spawnObject(`prop_paper_bag_01`, coords)
    coords = vector4(-1998.05, 3178.58, 31.81, 147.54)
    Util.spawnObject(`prop_paper_bag_01`, coords)

    exports['interactionMenu']:Create {
        type = 'model',
        model = `prop_paper_bag_01`,
        offset = vec3(0, 0, 0),
        maxDistance = 3.0,
        options = {
            {
                label = 'Second On Model',
                icon = 'fa fa-book',
                action = {
                    func = function(e)
                    end
                },
            }
        }
    }

    -- exports['interactionMenu']:Create {
    --     type = 'model',
    --     model = `prop_paper_bag_01`,
    --     offset = vec3(0, 0, 0),
    --     maxDistance = 3.0,
    --     options = {
    --         {
    --             label = 'Pick',
    --             icon = 'fa fa-book',
    --             action = {
    --                 func = function(e)
    --                 end
    --             },
    --         }
    --     }
    -- }
end)
