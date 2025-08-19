--                _
--               | |
--   _____      _| | _____  ___ _ __
--  / __\ \ /\ / / |/ / _ \/ _ \ '_ \
--  \__ \\ V  V /|   <  __/  __/ |_) |
--  |___/ \_/\_/ |_|\_\___|\___| .__/
--                             | |
--                             |_|
-- https://github.com/swkeep

local entities = {}
local menu_ids = {}

local money = 120
local huntingSkill = 5
local reputation = 50

local hunting_ped_data = {
    {
        model = 's_f_y_sheriff_01',
        position = 'front',
        index = 1,
        dialogues = {
            -- Hunting Instructor
            {
                name = 'init',
                message = 'Well look what the cat dragged in. You lost, city boy?',
                icon = 'fa-solid fa-comment-dots',
                responses = {
                    {
                        label = 'Learn hunting',
                        description = 'Actually, I was hoping you could teach me to hunt.',
                        next = 'hunting_lessons',
                        requirement = {
                            hint = "at least $100",
                            check = function() return money >= 100 end
                        }
                    },
                    {
                        label = 'Compliment gear',
                        description = 'Just admiring your gear. That\'s a serious setup.',
                        next = "gear_compliment",
                    }
                }
            },
            {
                name = 'hunting_lessons',
                message = 'Teach you? Boy, you couldn\'t track an elephant in a snowstorm.',
                icon = 'fa-solid fa-deer',
                responses = {
                    {
                        label = 'Quick learner',
                        description = 'I\'m a quick study. Give me a chance.',
                        next = "quick_study_response"
                    },
                    {
                        label = 'Prior experience',
                        description = 'I know my way around a rifle already.',
                        action = function()

                        end
                    }
                }
            },
            {
                name = 'quick_study_response',
                message = 'Alright kid, we\'ll start with tracking. See those deer prints? Follow \'em.',
                icon = 'fa-solid fa-paw',
                responses = {
                    {
                        label = 'Start tracking',
                        description = 'Fine, show me how it\'s done.',
                        action = function()
                            print("Player started tracking tutorial")
                            TriggerEvent('hunting:startTutorial', 'tracking')
                        end
                    }
                }
            },
            {
                name = 'gear_compliment',
                message = 'Damn right it is. Custom scope, hand-loaded rounds - the works.',
                icon = 'fa-solid fa-rifle',
                responses = {
                    {
                        label = 'Ask about gear',
                        description = 'Where does someone get gear like this?',
                        next = "gear_sources"
                    }
                }
            },
            {
                name = 'gear_sources',
                message = 'The ammo guy over there sells good stuff. Tell him I sent you.',
                icon = 'fa-solid fa-box-open',
                responses = {
                    {
                        label = 'Thanks',
                        description = 'Appreciate the tip.',
                        action = function()

                        end
                    }
                }
            }
        }
    },
    {
        index = 2,
        model = 's_m_y_ammucity_01',
        position = 'front',
        dialogues = {
            -- Ammo Salesman
            {
                name = 'init',
                message = 'You lookin\' to buy some hunting gear?',
                icon = 'fa-solid fa-gun',
                -- tts_voice = "Brian",
                responses = {
                    {
                        label = 'Browse weapons',
                        description = 'What kind of weapons do you have?',
                        next = "weapon_selection"
                    },
                    {
                        label = 'Special request',
                        description = 'I need something... special.',
                        next = "blackmarket_inquiry",
                        requirement = {
                            type = "gold",
                            hint = "reputation 50+",
                            check = function() return reputation >= 50 end
                        }
                    }
                }
            },
            {
                name = 'weapon_selection',
                message = 'Got hunting rifles $500, shotguns $350, and ammo $50 per box.',
                icon = 'fa-solid fa-gun',
                responses = {
                    {
                        label = 'Buy rifle',
                        description = 'I\'ll take a hunting rifle.',
                        action = function()
                            print("Player bought hunting rifle")
                        end
                    },
                    {
                        label = 'Buy ammo',
                        description = 'Just need some ammo.',
                        next = "ammo_selection"
                    }
                }
            },
            {
                name = 'ammo_selection',
                message = 'Rifle rounds or shotgun shells?',
                icon = 'fa-solid fa-bullseye',
                responses = {
                    {
                        label = 'Rifle ammo',
                        description = 'Give me rifle rounds.',
                        action = function()
                            print("Player bought rifle ammo")
                        end
                    },
                    {
                        label = 'Shotgun shells',
                        description = 'I need shotgun shells.',
                        action = function()
                            print("Player bought shotgun shells")
                        end
                    }
                }
            },
            {
                name = 'blackmarket_inquiry',
                message = '*looks around* I might have some... restricted items. For the right price.',
                icon = 'fa-solid fa-lock',
                responses = {
                    {
                        label = 'Interested',
                        description = 'What exactly are we talking about?',
                        next = "blackmarket_items"
                    },
                    {
                        label = 'Too risky',
                        description = 'Never mind, too hot for me.',
                        action = function()

                        end
                    }
                }
            }
        }
    },
    {
        index = 3,
        model = 'a_m_m_hillbilly_02',
        position = 'front',
        voice = "A_M_M_BEACH_01_WHITE_FULL_01",
        onSeen = {
            animation = {
                dict = "mp_masks@on_foot",
                anim = "tip_hat",
                flags = -1,
                blendIn = 8.0,
                blendOut = -8.0
            },
            voice = {
                speech = "GENERIC_HI",
                params = "SPEECH_PARAMS_FORCE"
            },
            action = function(entity)
                print("Ammu-Nation clerk noticed player")
            end
        },

        onExit = {
            animation = {
                dict = "gestures@f@standing@casual",
                anim = "gesture_bye_soft",
                flags = -1,
                blendIn = 8.0,
                blendOut = -8.0
            },
            voice = {
                speech = "GOODBYE_ACROSS_STREET",
                params = "Speech_Params_Force"
            },
            action = function(entity)
                print("Ammu-Nation clerk said goodbye")
            end
        },
        dialogues = {
            -- Poacher
            {
                name = 'init',
                message = {
                    "You ain't from around here, are ya?",
                    "You best state your business, stranger.",
                    "Howdy there, partner. What brings you out these parts?",
                    "You lookin' fer trouble or just dumb luck?",
                    "This ain't no tourist spot. What you want?"
                },
                icon = 'fa-solid fa-skull',
                responses = {
                    {
                        label = 'Special game',
                        description = 'Heard you know where to find... special game.',
                        next = "poaching_inquiry",
                        requirement = {
                            hint = "hunting skill 20+",
                            check = function() return huntingSkill >= 20 end
                        }
                    },
                    {
                        label = 'Just looking',
                        description = 'Just passing through.',
                        animation = {
                            dict = "gestures@f@standing@casual",
                            anim = "gesture_bye_soft",
                        },
                        voice = {
                            speech = "GOODBYE_ACROSS_STREET",
                            params = "Speech_Params_Force"
                        },
                        action = function()
                            print("My action")
                        end
                    }
                }
            },
            {
                name = 'poaching_inquiry',
                message = 'Them legendary animals? Dangerous business... and illegal.',
                icon = 'fa-solid fa-paw',
                responses = {
                    {
                        label = 'I\'m interested',
                        description = 'Tell me where to find them.',
                        next = "legendary_locations"
                    },
                    {
                        label = 'Changed mind',
                        description = 'On second thought, never mind.',
                        action = function()

                        end
                    }
                }
            },
            {
                name = 'legendary_locations',
                message = 'There\'s a white buck up north ($1000 info), and a golden eagle in the mountains ($1500).',
                icon = 'fa-solid fa-map',
                responses = {
                    {
                        label = 'Buck info',
                        description = 'Tell me about the buck.',
                        action = function()
                            print("Player bought buck location")
                        end
                    },
                    {
                        label = 'Eagle info',
                        description = 'I want the eagle location.',
                        action = function()
                            print("Player bought eagle location")
                        end
                    }
                }
            },
            {
                name = 'blackmarket_items',
                message = 'Suppressors ($2000), armor-piercing rounds ($1000/box), even... special tags.',
                icon = 'fa-solid fa-lock',
                responses = {
                    {
                        label = 'Buy suppressor',
                        description = 'I\'ll take a suppressor.',
                        action = function()
                            print("Player bought suppressor")
                        end
                    },
                    {
                        label = 'AP rounds',
                        description = 'Give me armor-piercing rounds.',
                        action = function()
                            print("Player bought AP rounds")
                        end
                    }
                }
            }
        }
    },
    {
        index = 3,
        model = 'a_m_m_hillbilly_02',
        position = 'middle',
        voice = "A_M_M_BEACH_02_WHITE_FULL_01",
        onSeen = {
            animation = {
                dict = "mp_masks@on_foot",
                anim = "tip_hat",
                flags = -1,
                blendIn = 8.0,
                blendOut = -8.0
            },
            voice = {
                speech = "GENERIC_HI",
                params = "SPEECH_PARAMS_FORCE"
            },
            action = function(entity)
                print("Survivalist noticed player")
            end
        },
        onExit = {
            animation = {
                dict = "gestures@f@standing@casual",
                anim = "gesture_bye_soft",
                flags = -1,
                blendIn = 8.0,
                blendOut = -8.0
            },
            voice = {
                speech = "GOODBYE_ACROSS_STREET",
                params = "Speech_Params_Force"
            },
            action = function(entity)
                print("Survivalist dismissed player")
            end
        },
        dialogues = {
            {
                name = 'init',
                message = {
                    "Stop right there. Safe zone's full. Turn back.",
                    "The dead ain't the only thing that'll kill ya out here.",
                    "You got 10 seconds to state your business."
                },
                icon = 'fa-solid fa-skull',
                responses = {
                    {
                        label = 'Seeking shelter',
                        description = 'I’m clean. Just need supplies. *holds gun menacingly*',
                        next = "prove_worth",
                        animation = {
                            dict = "reaction@intimidation@1h",
                            anim = "intro",
                            flags = 49
                        },
                        voice = { -- Gritty whisper
                            speech = "GENERIC_INSULT_MED",
                            params = "SPEECH_PARAMS_FORCE_NORMAL"
                        },
                        requirement = {
                            hint = "A weapon",
                            check = function()
                                return HasPedGotWeapon(PlayerPedId(), GetHashKey("WEAPON_PISTOL"), false)
                            end,
                            notify = function(result)
                                if result == "success" then
                                    TriggerEvent('QBCore:Notify', 'Survivalist approves.', 'success')
                                else
                                    TriggerEvent('QBCore:Notify', 'Survivalist scoffs at you.', 'error')
                                end
                            end
                        }
                    },
                    {
                        label = 'Trade',
                        description = 'I’ve got things to barter.',
                        next = "barter_offer",
                        requirement = {
                            hint = "Requires food or ammo",
                            check = function() return true end
                        }
                    },
                    {
                        label = 'Threaten',
                        description = 'Step aside, old man.',
                        animation = {
                            dict = "gestures@f@standing@casual",
                            anim = "gesture_damn",
                        },
                        voice = {
                            speech = "GENERIC_INSULT_MED",
                            params = "Speech_Params_Force"
                        },
                        action = function()

                        end
                    }
                }
            },
            {
                name = 'prove_worth',
                message = {
                    "A pistol ain’t enough. Kill 5 roamers near the gas station.",
                    "Fetch me a medkit from the clinic. Watch for biters.",
                    "Clear the road west of here. Bring me a walker’s hand as proof."
                },
                icon = 'fa-solid fa-question',
                responses = {
                    {
                        label = 'Accept task',
                        description = 'Fine. I’ll do it.',
                        action = function()
                        end

                    },
                    {
                        label = 'Refuse',
                        description = 'Forget it. I’ll find another way.',
                        next = "init"
                    }
                }
            },
            {
                name = 'barter_offer',
                message = {
                    "Canned food? I’ll trade for bullets.",
                    "Ammo? I’ll give you a gas can.",
                    "Got medicine? I’ll let you in for 2 pills."
                },
                icon = 'fa-solid fa-handshake',
                responses = {
                    {
                        label = 'Trade food for ammo',
                        description = 'Here’s 3 cans. Give me 9mm.',
                        action = function()
                            TriggerServerEvent('barter:exchange', 'canned_food', 3, 'ammo_9mm', 30)
                        end
                    },
                    {
                        label = 'Trade ammo for fuel',
                        description = 'Take my bullets. I need gas.',
                        action = function()
                            TriggerServerEvent('barter:exchange', 'ammo_9mm', 15, 'fuel_can', 1)
                        end
                    },
                    {
                        label = 'Leave',
                        description = 'Changed my mind.',
                        next = "init"
                    }
                }
            },
            -- Secret dialogue (unlocked after helping)
            {
                name = 'trusted',
                message = {
                    "You’re alright. Safe zone’s east, but keep quiet.",
                    "There’s a stash under the blue truck. Don’t tell nobody.",
                    "Watch for raiders. They’re worse than the dead."
                },
                icon = 'fa-solid fa-shield',
                responses = {
                    {
                        label = 'Thanks',
                        description = 'I owe you one.',
                        action = function()
                            TriggerEvent('survivalist:trusted') -- Unlocks safe zone access
                        end
                    }
                },
                requirement = {
                    hint = "Must complete 2 tasks",
                    check = function()
                        return exports['missions']:completed('survivalist_task', 2)
                    end
                }
            }
        }
    },
    {
        index = 2,
        model = 's_m_m_doctor_01',
        position = 'middle',
        voice = "A_M_M_RURMETH_01_WHITE_MINI_01",
        onSeen = {
            animation = {
                dict = "amb@world_human_clipboard@male@idle_a",
                anim = "idle_c",
                flags = 49,
                blendIn = 8.0,
                blendOut = -8.0
            },
            voice = {
                speech = "GENERIC_HI",
                params = "SPEECH_PARAMS_FORCE_NORMAL"
            },
            action = function(entity)
                print("The doctor eyes you warily.")
            end
        },
        onExit = {
            animation = {
                dict = "gestures@f@standing@casual",
                anim = "gesture_bye_soft",
                flags = -1,
                blendIn = 8.0,
                blendOut = -8.0
            },
            voice = {
                speech = "GENERIC_THANKS",
                params = "Speech_Params_Force_Normal"
            },
            action = function(entity)
                print("The doctor dismisses you.")
            end
        },
        dialogues = {
            {
                name = 'init',
                message = {
                    "The veins... they whisper...",
                    "The blood... it remembers. It *knows* things. Shhh... Shhh... listen...",
                    "The shadows in the corner... they told me your name before you walked in.",
                },
                icon = 'fa-solid fa-book-skull',
                responses = {
                    {
                        label = 'Need medicine',
                        description = 'I’m hurt. Can you help?',
                        next = "medical_help",
                        requirement = {
                            check = function()
                                return GetEntityHealth(PlayerPedId()) < 180 or IsPedInjured(PlayerPedId())
                            end,
                            notify = function(result)
                                if result then
                                    TriggerEvent('QBCore:Notify', 'The doctor sniffs the air. "Ah... pain. I can work with that."', 'primary')
                                else
                                    TriggerEvent('QBCore:Notify', '"You’re too healthy. Come back when you’re dying."', 'error')
                                end
                            end
                        }
                    },
                    {
                        label = 'Buy supplies',
                        description = 'Sell me anything useful.',
                        next = "blackmarket",
                        requirement = {
                            hint = "Requires cash",
                            check = function()
                                return true
                            end,
                            notify = function(result)
                                if result then
                                    TriggerEvent('QBCore:Notify', '"Show me what you’ve got."', 'success')
                                else
                                    TriggerEvent('QBCore:Notify', '"No money? No miracles." *laughs hoarsely*', 'error')
                                end
                            end
                        }
                    },
                    {
                        label = 'Ask about curse',
                        description = 'What’s wrong with your hands? *notices black veins*',
                        next = "curse_dialogue",
                        requirement = {
                            check = function()
                                return true
                            end,
                            notify = function(result)
                                if result then
                                    TriggerEvent('QBCore:Notify', 'The doctor’s eyes darken.', 'primary')
                                else
                                    TriggerEvent('QBCore:Notify', '"Ask again and I’ll use your bones for splints."', 'error')
                                end
                            end
                        }
                    }
                }
            },
            {
                name = 'medical_help',
                message = {
                    "*pulls out a syringe filled with murky liquid* This’ll stop the pain... mostly",
                    "I can stitch you up, but my methods are... unconventional",
                },
                icon = 'fa-solid fa-syringe',
                responses = {
                    {
                        label = 'Back',
                        next = 'init'
                    },
                    {
                        label = 'Accept treatment',
                        description = 'Do what you must.',
                        action = function()
                            TriggerEvent('QBCore:Notify', 'The doctor’s hands glow faintly as he works...', 'warning')
                        end
                    },
                    {
                        label = 'Ask price',
                        description = 'What’s the cost?',
                        next = "treatment_cost"
                    },
                    {
                        label = 'Refuse',
                        description = 'This feels wrong...',
                        voice = {
                            speech = "GENERIC_FRIGHTENED_MED",
                            params = "SPEECH_PARAMS_FORCE"
                        },
                        action = function()
                            TriggerEvent('QBCore:Notify', 'The doctor hisses: "Your funeral."', 'error')
                        end
                    }
                }
            },
            {
                name = 'blackmarket',
                message = {
                    "*opens a crate of suspicious vials* My... special inventory.",
                    "I’ve got painkillers $200, adrenaline $500, and experimental things."
                },
                icon = 'fa-solid fa-prescription-bottle-alt',
                responses = {
                    {
                        label = 'Back',
                        next = 'init'
                    },
                    {
                        label = 'Buy painkillers',
                        description = 'Give me basic meds. ($200)',
                        action = function()

                        end
                    },
                    {
                        label = 'Buy adrenaline',
                        description = 'I need a boost. ($500)',
                        action = function()

                        end
                    },
                    {
                        label = 'Experimental serum',
                        description = 'What’s this "experimental" thing? ($1500)',
                        next = "serum_warning",
                        requirement = {
                            hint = "Requires $1500",
                            check = function()
                                return true
                            end
                        }
                    }
                }
            },
            {
                name = 'curse_dialogue',
                message = {
                    "*clenches black-veined hands* The dead... don’t stay dead around me",
                    "I learned medicine from... something that nvm...",
                    "Every life I save, another ghost follows me *laughs madly*"
                },
                icon = 'fa-solid fa-ghost',
                responses = {
                    {
                        label = 'Back',
                        next = 'init'
                    },
                    {
                        label = 'Can it be lifted?',
                        description = 'There must be a cure...',
                        next = "curse_quest",
                        action = function()
                            TriggerEvent('QBCore:Notify', 'The doctor whispers: "Find the Bone Man in the swamp."', 'success')
                        end
                    },
                    {
                        label = 'Back away slowly',
                        description = 'This is too much.',
                        animation = {
                            dict = "move_m@intimidation@cop@unarmed",
                            anim = "idle",
                            flags = 49
                        },
                        action = function()
                            TriggerEvent('QBCore:Notify', 'The doctor mutters in a language you don’t recognize...', 'error')
                        end
                    }
                }
            }
        }
    },
    {
        index = 1,
        model = 's_m_m_movalien_01',
        position = 'middle',
        voice = "A_M_M_ACULT_01_WHITE_MINI_01", -- Whispery, erratic
        behavior = {
            wanderRadius = 50.0,                -- Paces in a small area
            aggression = 0.9,                   -- 90% chance to follow players
            scenarios = {
                "WORLD_HUMAN_BUM_WASH",         -- Muttering to hands
                "CODE_HUMAN_MEDIC_KNEEL",       -- Crouching ominously
                "WORLD_HUMAN_DRUG_DEALER"       -- Twitchy movements
            }
        },
        onSeen = {
            animation = {
                dict = "anim@mp_player_intcelebrationmale@freakout",
                anim = "freakout",
                flags = 49
            },
            voice = {
                speech = "CHALLENGE_ACCEPTED_BUMPED_INTO",
                params = "SPEECH_PARAMS_FORCE_SHOUTED"
            }
        },
        dialogues = {
            {
                name = 'init',
                message = {
                    "*tap tap tap* Hey... hey... ya lost?",
                },
                icon = 'fa-solid fa-paw',
                responses = {
                    {
                        label = 'What are you?',
                        description = 'Back away slowly...',
                        next = "identity_crisis",
                        requirement = {
                            check = function()
                                return IsPedArmed(PlayerPedId(), 7)
                            end,
                            notify = function(result)
                                if result then
                                    TriggerEvent('QBCore:Notify', '"Ooooh, scary! *giggles* Put it away before I take it..."', 'error')
                                else
                                    TriggerEvent('QBCore:Notify', '"Smart. Real smart. *licks lips*"', 'error')
                                end
                            end
                        }
                    },
                    {
                        label = 'Run',
                        description = 'NOPE.',
                        animation = {
                            dict = "missfbi5ig_22",
                            anim = "hands_up_anxious_scientist"
                        },
                        action = function()
                            TriggerEvent('gnome:chase')
                        end
                    }
                }
            },
        }
    }
}

local function init()
    for i, ped_data in ipairs(hunting_ped_data) do
        local slot = InternalGetTestSlot(ped_data.position, ped_data.index)
        if slot then
            local entity = Util.spawnPed(GetHashKey(ped_data.model), vec3(slot.x, slot.y, slot.z - 0.58))
            SetEntityHeading(entity, slot.w)
            entities[#entities + 1] = entity

            local data = {
                index = ped_data.index,
                entity = entity,
                theme = 'theme-6',
                onSeen = ped_data.onSeen,
                onExit = ped_data.onExit,
                conversations = ped_data.dialogues,
            }

            local instance = exports["interactionMenu"]:dialogue(data)
            menu_ids[#menu_ids + 1] = instance
        end
    end
end

local function cleanup()
    for _, entity in ipairs(entities) do
        DeleteEntity(entity)
    end
    entities = {}

    for _, menu_id in ipairs(menu_ids) do
        exports['interactionMenu']:remove(menu_id.menu_id)
    end
    menu_ids = {}
end

CreateThread(function()
    InternalRegisterTest(init, cleanup, "npc_dialogue", "NPC Dialogue System", "fa-solid fa-comments")
end)
