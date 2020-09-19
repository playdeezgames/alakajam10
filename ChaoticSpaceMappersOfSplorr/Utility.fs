namespace CSMoS

module Utility = 
    open System
    let random = Random()
    let ReadLine () : string list = Console.ReadLine().ToLower().Split(' ') |> Array.toList

    let ToRadians (degrees:float) : float =
        degrees/180.0*Math.PI

    let GenerateRandomValue (minimum:float, maximum:float) : float =
        random.NextDouble() * (maximum-minimum) + minimum

