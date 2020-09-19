namespace CSMoS

open System

module SetHeading = 

    let private InvalidTheta() : unit =
        Utility.PlayMusic Constants.ErrorSong
        printfn ""
        printfn "Invalid theta - must be numeric and between -180.0 and 180.0!"

    let private InvalidPhi() : unit =
        Utility.PlayMusic Constants.ErrorSong
        printfn ""
        printfn "Invalid phi - must be numeric and between -90.0 and 90.0!"

    let internal Handle (thetaText:string, phiText:string) (entity:Entity) (world:World) : World option =
        match Double.TryParse(thetaText) with
        | true, theta when theta>=(-180.0) && theta<=180.0->
            match Double.TryParse(phiText) with
            | true, phi when phi>=(-90.0) && phi<=90.0->
                let updatedEntity =
                    entity
                    |> Entity.SetTheta theta
                    |> Entity.SetPhi phi
                printfn ""
                printfn "Updated heading!"
                world 
                |> World.SetPlayerEntity (updatedEntity |> Some)
                |> Some
            | _ ->
                InvalidPhi()
                world |> Some
        | _ ->
            InvalidTheta()
            world |> Some


