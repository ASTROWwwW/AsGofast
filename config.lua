Config = {}

-- PNJ de départ
Config.StartNPC = {
    coords = vector3(150.0, -1030.0, 29.30), -- Coordonnées du PNJ
    heading = 330.0, -- Orientation du PNJ
    model = `s_m_y_dealer_01`, -- Modèle du PNJ
    animationDict = "mp_common", -- Animation
    animationName = "givetake1_a"
}

-- PNJ d'arrivée
Config.EndNPC = {
    coords = vector3(1200.0, -1500.0, 34.67), -- Coordonnées du PNJ
    heading = 180.0, -- Orientation du PNJ
    model = `s_m_y_dealer_01`, -- Modèle du PNJ
    animationDict = "mp_common", -- Animation
    animationName = "givetake1_a"
}

-- Liste des véhicules disponibles pour le spawn
Config.VehicleSpawn = {
    coords = vector3(160.0, -1020.0, 30.0),
    heading = 90.0,
    models = { `burrito3`, `rumpo`, `pony`, `speedo`, `boxville` }
   -- Liste des modèles
}

-- Récompense
Config.Reward = { min = 5000, max = 15000 }
