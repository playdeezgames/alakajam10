namespace CSMoS

open System

module Refuel =
    let private Invalid() : unit =
        Utility.PlayMusic Constants.ErrorSong
        ["Invalid entity number or not near enough to entity!"]
        |> Utility.DisplayMessages

    let private HandleStarInteraction (otherId:Guid) (star:Star) (other:Entity) (entity:Entity) (world: World) : World option =
        //TODO: music
        ["You refueld yer ship!"]
        |> Utility.DisplayMessages
        let available = star.FuelAvailable |> int32
        let updatedStar =
            other
            |> Entity.TransformEntityType (fun _ ->star |> Star.DepleteFuel |> Star)
            |> Some
        let updatedEntity =
            entity
            |> Entity.TransformEntityType (EntityType.GetShip >> Option.get >> Ship.AddFuel available >> Ship)
            |> Some
        world 
        |> World.SetEntity otherId updatedStar
        |> World.SetEntity world.PlayerId updatedEntity
        |> Some

    let private HandleInteraction (otherId:Guid) (other:Entity) (entity:Entity) (world: World) : World option =
        match other.EntityType with
        | Star star when star.Surveyed->
            HandleStarInteraction otherId star other entity world
        | _ ->
            Invalid()
            world |> Some

    let private HandleRefuel (number:int) (entity:Entity) (world: World) : World option =
        match world.EntityNumbers |> Map.tryPick (fun k v -> if v = number then Some k else None) with
        | Some entityId ->
            let other = world.Entities.[entityId]
            let distance = Entity.DistanceBetween entity other
            if distance<=Constants.InteractDistance then
                HandleInteraction entityId other entity world
            else
                Invalid()
                world |> Some
        | _ ->
            Invalid()
            world |> Some


    let internal Handle (numberText:string) (entity:Entity) (world: World) : World option =
        match Int32.TryParse(numberText) with
        | true, number ->
            HandleRefuel number entity world
        | _ ->
            Invalid()
            world |> Some

