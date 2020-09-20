namespace CSMoS

open System

module Survey=
    let private Invalid() : unit =
        Utility.PlayMusic Constants.ErrorSong
        ["Invalid entity number or not near enough to entity!"]
        |> Utility.DisplayMessages

    let private HandleInteraction (otherId:Guid) (other:Entity) (entity:Entity) (world: World) : World option =
        match other.EntityType with
        | Star star ->
            Constants.SurveyStarSong
            |> Utility.PlayMusic
            ["Star surveyed!"]
            |> Utility.DisplayMessages
            //set star to surveyed
            let updatedOther =
                other
                |> Entity.TransformEntityType
                    (EntityType.GetStar >> Option.get >> Star.Survey >> Star)
                |> Some
            //add other id to ship survey manifest
            let updatedEntity =
                entity
                |> Entity.TransformEntityType
                    (EntityType.GetShip >> Option.get >> Ship.SurveyEntity otherId >> Ship)
                |> Some
            world
            |> World.SetEntity otherId updatedOther
            |> World.SetEntity world.PlayerId updatedEntity
            |> Some
        | Wormhole ->
            Constants.WormholeSong
            |> Utility.PlayMusic
            [
                "It was not a star, but a wormhole!"
                "What's on the other end?"
            ]
            |> Utility.DisplayMessages
            let updatedEntity =
                entity
                |> Entity.SetX (Utility.GenerateRandomValue (-Constants.WorldWidth/2.0,Constants.WorldWidth/2.0))
                |> Entity.SetY (Utility.GenerateRandomValue (-Constants.WorldHeight/2.0,Constants.WorldHeight/2.0))
                |> Entity.SetZ (Utility.GenerateRandomValue (-Constants.WorldDepth/2.0,Constants.WorldDepth/2.0))
                |> Some
            world
            |> World.SetEntity world.PlayerId updatedEntity
            |> Some
        | _ ->
            ["Not a star!"]
            |> Utility.DisplayMessages
            world |> Some

    let private HandleSurvey (number:int) (entity:Entity) (world: World) : World option =
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
            HandleSurvey number entity world
        | _ ->
            Invalid()
            world |> Some

