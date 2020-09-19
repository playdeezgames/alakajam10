namespace CSMoS

open System

module Utility = 
    let random = Random()
    let ReadLine () : string list = Console.ReadLine().ToLower().Split(' ') |> Array.toList

    let ToRadians (degrees:float) : float =
        degrees/180.0*Math.PI

    let GenerateRandomValue (minimum:float, maximum:float) : float =
        random.NextDouble() * (maximum-minimum) + minimum

    let ToDegrees (radians:float) : float =
        radians * 180.0 / Math.PI

    let DisplayMessages (messages:string list) : unit =
        printfn ""
        messages
        |> List.iter (printfn "%s")

    let PlayMusic(notes: (int * int) list) : unit =
        try
            notes
            |> List.iter
                (fun (freq, dur) ->
                    Console.Beep(freq, dur))
        with
        | ex -> ()
