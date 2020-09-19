namespace CSMoS

open System

type Ship =
    {
        Fuel: int
        MaximumFuel: int
        SurveyedEntities: Set<Guid>
    }

module Ship =
    let Create () =
        {
            Fuel = 100
            MaximumFuel = 100
            SurveyedEntities = Set.empty
        }

    let SurveyEntity (entityId: Guid) (ship:Ship) : Ship =
        {ship with
            SurveyedEntities = ship.SurveyedEntities |> Set.add entityId}

