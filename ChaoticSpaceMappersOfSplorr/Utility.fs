namespace CSMoS

module Utility = 
    open System
    let ReadLine () : string list = Console.ReadLine().ToLower().Split(' ') |> Array.toList

