namespace CSMoS

module Move =
    let private UnfueledMove () : unit =
        ["You are out of fuel!"]
        |> Utility.DisplayMessages

    let private FueledMove (world:World) : World option =
        ["You have moved!"]
        |> Utility.DisplayMessages
        world
        |> World.TransformEntity 
            world.PlayerId 
            (fun entity -> 
                entity 
                |> Entity.TransformEntityType 
                    (fun entityType ->
                        match entityType with
                        | Ship ship ->
                            {ship with Fuel = ship.Fuel - 1}
                            |> Ship
                        | _ ->
                            entityType)
                |> Some)
        |> World.UpdateEntities
        |> Some

    let internal Handle (entity:Entity) (world:World) : World option =
        //do we have fuel?
        let ship = 
            entity.EntityType 
            |> EntityType.GetShip 
            |> Option.get
        if ship.Fuel > 0 then
            FueledMove world
        else
            UnfueledMove()
            None



