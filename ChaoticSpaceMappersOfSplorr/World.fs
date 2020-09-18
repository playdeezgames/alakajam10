namespace CSMoS

open System

type World =
    {
        PlayerId : Guid
        Ships : Map<Guid, Ship>
    }

module World = 
    let AddShip (shipId: Guid, ship: Ship) (world:World) : World =
        {world with 
            Ships = 
                world.Ships 
                |> Map.add 
                    shipId 
                    ship}

    let Create() : World =
        let playerId = Guid.NewGuid()
        {
            PlayerId = playerId
            Ships = Map.empty
        }
        |> AddShip (playerId, Ship.Create())

    let GetShip (shipId:Guid) (world:World) : Ship option =
        world.Ships
        |> Map.tryFind shipId

    let GetPlayerShip (world:World) : Ship option =
        GetShip (world.PlayerId) world

