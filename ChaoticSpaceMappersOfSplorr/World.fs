namespace CSMoS

open System

type World =
    {
        PlayerId : Guid
        Entities : Map<Guid, Entity>
        EntityNumbers : Map<Guid,int>
        NextNumber : int
    }

module World = 

    let SetEntity (entityId: Guid) (entity: Entity option) (world:World) : World =
        match entity with
        | Some e ->
            let number = 
                world.EntityNumbers 
                |> Map.tryFind entityId
            let nextNumber = if number.IsNone then world.NextNumber + 1 else world.NextNumber
            let number = number |> Option.defaultValue world.NextNumber
            {world with 
                Entities = 
                    world.Entities 
                    |> Map.add 
                        entityId 
                        e
                NextNumber = nextNumber
                EntityNumbers =
                    world.EntityNumbers
                    |> Map.add
                        entityId
                        number}
        | _ ->
            {world with
                Entities =
                    world.Entities
                    |> Map.remove entityId
                EntityNumbers =
                    world.EntityNumbers
                    |> Map.remove entityId}

    let SetPlayerEntity (entity:Entity option) (world:World) : World =
        SetEntity world.PlayerId entity world

    let CreateStars (world:World) : World =
        [1..Constants.StarCount]
        |> List.map
            (fun _ -> 
                Entity.Create(Star.Create() |> Star)
                |> Entity.SetX (Utility.GenerateRandomValue (-Constants.WorldWidth/2.0,Constants.WorldWidth/2.0))
                |> Entity.SetY (Utility.GenerateRandomValue (-Constants.WorldHeight/2.0,Constants.WorldHeight/2.0))
                |> Entity.SetZ (Utility.GenerateRandomValue (-Constants.WorldDepth/2.0,Constants.WorldDepth/2.0))
                |> Some)
        |> List.fold
            (fun w star -> 
                w
                |> SetEntity (Guid.NewGuid()) star) world

    let CreateWormholes (world:World) : World =
        [1..Constants.WormholeCount]
        |> List.map
            (fun _ -> 
                Entity.Create(Wormhole)
                |> Entity.SetX (Utility.GenerateRandomValue (-Constants.WorldWidth/2.0,Constants.WorldWidth/2.0))
                |> Entity.SetY (Utility.GenerateRandomValue (-Constants.WorldHeight/2.0,Constants.WorldHeight/2.0))
                |> Entity.SetZ (Utility.GenerateRandomValue (-Constants.WorldDepth/2.0,Constants.WorldDepth/2.0))
                |> Some)
        |> List.fold
            (fun w star -> 
                w
                |> SetEntity (Guid.NewGuid()) star) world

    let ScrambleEntityNumbers (world:World) : World =
        let entityIds, entityNumbers = 
            world.EntityNumbers
            |> Map.toList
            |> List.unzip
        let entityNumbers =
            entityNumbers
            |> List.sortBy
                (fun _ -> Utility.random.Next())
        let scrambled =
            List.zip entityIds entityNumbers
            |> Map.ofList
        {world with
            EntityNumbers = scrambled}

    let Create() : World =
        let playerId = Guid.NewGuid()
        {
            PlayerId = playerId
            Entities = Map.empty
            EntityNumbers = Map.empty
            NextNumber = 1
        }
        |> SetEntity playerId (Entity.Create(Ship.Create() |> Ship) |> Entity.SetSpeed 1.0 |> Some)
        |> CreateStars 
        |> CreateWormholes 
        |> ScrambleEntityNumbers

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

    let TransformEntity (entityId:Guid) (tranform:Entity->Entity option) (world:World) : World =
        let tranformedEntity =
            world
            |> GetEntity entityId
            |> Option.bind tranform
        world
        |> SetEntity entityId tranformedEntity





