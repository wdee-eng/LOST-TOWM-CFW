Config = {}

-- Food items and their hunger restoration values
Config.FoodItems = {
    -- Basic Food
    ["sandwich"] = 25,
    ["hamburger"] = 35,
    ["tosti"] = 20,
    ["pizza"] = 40,
    ["hotdog"] = 30,
    ["chips"] = 15,
    ["chocolate"] = 10,
    ["apple"] = 15,
    ["banana"] = 15,
    
    -- Special Food
    ["kebab"] = 45,
    ["shawarma"] = 45,
    ["falafel"] = 35,
    ["hummus"] = 25,
    ["tabbouleh"] = 20
}

-- Drink items and their thirst restoration values
Config.DrinkItems = {
    -- Basic Drinks
    ["water"] = 25,
    ["cola"] = 20,
    ["coffee"] = 30,
    ["energy"] = 35,
    ["icetea"] = 25,
    ["sprite"] = 20,
    
    -- Special Drinks
    ["arabic_coffee"] = 40,
    ["mint_tea"] = 35,
    ["lemonade"] = 30,
    ["ayran"] = 25
}

-- Items that reduce stress
Config.StressItems = {
    -- Relaxation Items
    ["joint"] = 15,
    ["cigarette"] = 10,
    ["beer"] = 5,
    ["whiskey"] = 8,
    
    -- Special Items
    ["shisha"] = 20,
    ["hookah"] = 25,
    ["massage_oil"] = 30,
    ["stress_pill"] = 40
}

-- Animation configurations for consuming items
Config.Animations = {
    ["eat"] = {
        dict = "mp_player_inteat@burger",
        anim = "mp_player_int_eat_burger",
        flags = 49,
        duration = 5000
    },
    ["drink"] = {
        dict = "mp_player_intdrink",
        anim = "loop_bottle",
        flags = 49,
        duration = 3000
    },
    ["smoke"] = {
        dict = "amb@world_human_smoking@male@male_a@base",
        anim = "base",
        flags = 49,
        duration = 8000
    },
    ["shisha"] = {
        dict = "anim@heists@humane_labs@finale@keycards",
        anim = "ped_a_enter_loop",
        flags = 49,
        duration = 10000
    }
}

-- Effects configurations
Config.Effects = {
    ["drunk"] = {
        screen = "damage",
        intensity = 1.0,
        duration = 30000,
        movement = 0.5
    },
    ["high"] = {
        screen = "spectator5",
        intensity = 1.5,
        duration = 45000,
        movement = 0.7
    },
    ["stress"] = {
        screen = "damage",
        intensity = 0.5,
        duration = 5000,
        shake = true
    }
}

return Config
