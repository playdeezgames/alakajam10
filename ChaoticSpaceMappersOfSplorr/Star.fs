namespace CSMoS

type Star =
    {
        Surveyed : bool
        FuelAvailable: float
        FuelRate: float
        FuelMaximum: float
    }

module Star=
    let Create () : Star =
        let fuelMaximum = Utility.GenerateRandomValue Constants.StarMaximumFuelRange
        { 
            Surveyed = false
            FuelAvailable = Utility.GenerateRandomValue(0.0, fuelMaximum)
            FuelRate = Utility.GenerateRandomValue Constants.StarRefuelRateRange
            FuelMaximum = fuelMaximum
        }

    let Survey (star:Star) : Star =
        {star with
            Surveyed = true}

    let GenerateFuel (star:Star) : Star =
        let nextAvailable = star.FuelAvailable + star.FuelRate
        {star with
            FuelAvailable = min nextAvailable star.FuelMaximum}

    let DepleteFuel (star:Star) : Star =
        {star with FuelAvailable = 0.0}

