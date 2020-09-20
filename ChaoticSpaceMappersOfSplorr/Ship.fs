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
            Fuel = Constants.MaximumFuel
            MaximumFuel = Constants.MaximumFuel
            SurveyedEntities = Set.empty
        }

    let SurveyEntity (entityId: Guid) (ship:Ship) : Ship =
        {ship with
            SurveyedEntities = ship.SurveyedEntities |> Set.add entityId}

    let AddFuel (fuel:int) (ship:Ship) : Ship =
        {ship with
            Fuel = min (ship.Fuel + fuel) ship.MaximumFuel}

