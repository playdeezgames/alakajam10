namespace CSMoS

open System

module Game = 
    let private HandleInvalid() : unit =
        printfn ""
        printfn "Maybe try 'help'?"

    let private HandleHelp() : unit =
        printfn ""
        printfn "In Game Help:"
        printfn "abandon - abandon the game and return to the main menu"
        printfn "help - show help (you are here!)"
        printfn "engage - moves yer ship"
        printfn "set heading <theta> <phi> - sets the heading of yer ship\n\t<theta> is between -180 and 180\n\t<phi> is between -90 and 90"
        printfn "set speed <speed> - sets the speed of yer ship (<speed> is between 0.0 and 1.0)"

    let private HandleSetHeadingInvalidTheta() : unit =
        printfn ""
        printfn "Invalid theta - must be numeric and between -180.0 and 180.0!"

    let private HandleSetHeadingInvalidPhi() : unit =
        printfn ""
        printfn "Invalid phi - must be numeric and between -90.0 and 90.0!"

    let private HandleSetHeading (thetaText:string, phiText:string) (entity:Entity) (world:World) : World option =
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
                HandleSetHeadingInvalidPhi()
                world |> Some
        | _ ->
            HandleSetHeadingInvalidTheta()
            world |> Some

    let private HandleSetSpeedInvalid() : unit =
        printfn ""
        printfn "Invalid speed - must be numeric and between 0.0 and 1.0!"
    
    let private HandleSetSpeed (speedText: string) (entity:Entity) (world:World) : World option =
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
            HandleSetSpeedInvalid()
            world |> Some

    let HandleMove (entity:Entity) (world:World) : World option =
        printfn ""
        printfn "You have moved!"
        world
        |> World.UpdateEntities
        |> Some

    let private ReportNearbyEntities (entity:Entity) (world:World) : unit =
        let viewDistance = 10.0
        printfn "Nearby Entities:"
        let starsNearby = 
            world
            |> World.GetNonPlayers
            |> Map.filter
                (fun _ other -> 
                    Entity.DistanceBetween entity other <= viewDistance)
            |> Map.toList
            |> List.map 
                (fun (key, e) -> 
                    (key, e.EntityType.ToString() ,(e.X - entity.X, e.Y-entity.Y, e.Z-entity.Z)))
        match starsNearby with
        | [] ->
            printfn "(nothing)"
        | entries ->
            entries
            |> List.iter
                (fun (_,typeName,(dx,dy,dz)) -> 
                    printfn "Type: %s dX: %f, dY: %f, dZ: %f" typeName dx dy dz)

    let private HandleGameOn(entity:Entity) (world:World) : World option = 
        printfn ""
        printfn "Ship Status:"
        printfn "Position: (%f, %f, %f)" entity.X entity.Y entity.Z
        printfn "Heading: (%f, %f)" entity.Theta entity.Phi
        printfn "Speed: (%f)" entity.Speed
        ReportNearbyEntities entity world
        match Utility.ReadLine() with
        | [ "engage" ] ->
            HandleMove entity world
        | [ "set"; "speed"; speed ] ->
            HandleSetSpeed speed entity world
        | [ "set" ; "heading" ; theta ; phi ]->
            HandleSetHeading (theta, phi) entity world
        | [ "abandon" ] ->
            None
        | [ "help" ] ->
            HandleHelp()
            world |> Some
        | _ ->
            HandleInvalid()
            world |> Some

    let private HandleGameOver() : World option =
        printfn ""
        printfn "Game over!"
        None

    let rec internal Run (world: World) : World option =
        match world |> World.GetPlayerEntity with
        | Some entity ->
            match HandleGameOn entity world with
            | Some next ->
                Run next
            | None ->
                HandleGameOver()
        | None ->
            HandleGameOver()    
        

