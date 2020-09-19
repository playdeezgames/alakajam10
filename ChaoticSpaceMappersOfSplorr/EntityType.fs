namespace CSMoS

type EntityType =
    | Ship of Ship
    | Star of Star
    | Wormhole

module EntityType =
    let GetTypeName (entityType:EntityType) : string =
        match entityType with
        | Ship _ -> "ship"
        | Star star ->
            if star.Surveyed then
                "surveyed star"
            else
                "unknown"
        | Wormhole -> "unknown"

    let GetShip (entityType: EntityType) : Ship option =
        match entityType with
        | Ship ship -> ship |> Some
        | _ -> None

    let GetStar (entityType: EntityType) : Star option =
        match entityType with
        | Star star -> star |> Some
        | _ -> None

    let DoMove (entityType: EntityType) : EntityType =
        entityType