namespace CSMoS

open System

module SetSpeed =
    let private Invalid() : unit =
        Utility.PlayMusic Constants.ErrorSong
        printfn ""
        printfn "Invalid speed - must be numeric and between 0.0 and 1.0!"

    let internal Handle (speedText: string) (entity:Entity) (world:World) : World option =
        match Double.TryParse(speedText) with
        | true, speed when speed>=0.0 && speed<=1.0 ->
            let updatedEntity =
                entity
                |> Entity.SetSpeed speed
            printfn ""
            printfn "Updated speed!"
            world 
            |> World.SetPlayerEntity (updatedEntity |> Some)
            |> Some
        | _ ->
            Invalid()
            world |> Some


