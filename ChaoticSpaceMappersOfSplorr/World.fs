namespace CSMoS

open System

type World =
    {
        PlayerId : Guid
        Entities : Map<Guid, Entity>
    }

module World = 
    let starCount = 100
    let worldHeight = 50.0
    let worldWidth = 50.0
    let worldDepth = 50.0
    let wormholeCount = 10

    let SetEntity (entityId: Guid) (entity: Entity option) (world:World) : World =
        match entity with
        | Some e ->
            {world with 
                Entities = 
                    world.Entities 
                    |> Map.add 
                        entityId 
                        e}
        | _ ->
            {world with
                Entities =
                    world.Entities
                    |> Map.remove entityId}

    let SetPlayerEntity (entity:Entity option) (world:World) : World =
        SetEntity world.PlayerId entity world

    let CreateStars (world:World) : World =
        [1..starCount]
        |> List.map
            (fun _ -> 
                Entity.Create(Star)
                |> Entity.SetX (Utility.GenerateRandomValue (-worldWidth/2.0,worldWidth/2.0))
                |> Entity.SetY (Utility.GenerateRandomValue (-worldHeight/2.0,worldHeight/2.0))
                |> Entity.SetZ (Utility.GenerateRandomValue (-worldDepth/2.0,worldDepth/2.0))
                |> Some)
        |> List.fold
            (fun w star -> 
                w
                |> SetEntity (Guid.NewGuid()) star) world

    let CreateWormholes (world:World) : World =
        [1..wormholeCount]
        |> List.map
            (fun _ -> 
                Entity.Create(Wormhole)
                |> Entity.SetX (Utility.GenerateRandomValue (-worldWidth/2.0,worldWidth/2.0))
                |> Entity.SetY (Utility.GenerateRandomValue (-worldHeight/2.0,worldHeight/2.0))
                |> Entity.SetZ (Utility.GenerateRandomValue (-worldDepth/2.0,worldDepth/2.0))
                |> Entity.SetTheta (Utility.GenerateRandomValue (-180.0,180.0))
                |> Entity.SetPhi (Utility.GenerateRandomValue (-90.0,90.0))
                |> Entity.SetSpeed  (Utility.GenerateRandomValue (0.5,1.5))
                |> Some)
        |> List.fold
            (fun w star -> 
                w
                |> SetEntity (Guid.NewGuid()) star) world

    let Create() : World =
        let playerId = Guid.NewGuid()
        {
            PlayerId = playerId
            Entities = Map.empty
        }
        |> SetEntity playerId (Entity.Create(Ship) |> Some)
        |> CreateStars 
        |> CreateWormholes 

    let GetEntity (shipId:Guid) (world:World) : Entity option =
        world.Entities
        |> Map.tryFind shipId

    let GetPlayerEntity (world:World) : Entity option =
        GetEntity (world.PlayerId) world

    let GetNonPlayers (world:World) : Map<Guid,Entity> =
        world.Entities
        |> Map.filter (fun k _ -> k <> world.PlayerId)

    let DoInteractions (world:World) (entityId:Guid) (entity:Entity) : Entity option * World =
        (entity |> Some, world)

    let UpdateEntities (world:World) : World =
        world.Entities
        |> Map.fold 
            (fun w key entity ->
                Entity.Move (DoInteractions w key) (SetEntity key) entity) world






