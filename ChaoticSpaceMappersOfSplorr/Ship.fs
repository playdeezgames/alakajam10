namespace CSMoS

type Ship =
    {
        X: float
        Y: float
        Z: float
        Theta: float
        Phi : float
        Speed: float
    }

module Ship =
    let Create() : Ship =
        {
            X = 0.0
            Y = 0.0
            Z = 0.0
            Theta = 0.0
            Phi = 0.0
            Speed = 0.0
        }

