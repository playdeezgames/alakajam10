namespace CSMoS

open System

module Game = 
    let private HandleInvalid() : unit =
        Utility.PlayMusic Constants.ErrorSong
        printfn ""
        printfn "Maybe try 'help'?"

    let private HandleHelp() : unit =
        printfn ""
        printfn "In Game Help:"
        printfn "abandon - abandon the game and return to the main menu"
        printfn "help - show help (you are here!)"
        printfn "engage - moves yer ship"
        printfn "refuel <number> - attempts to refuel from a given entity <number>"
        printfn "set heading <theta> <phi> - sets the heading of yer ship\n\t<theta> is between -180 and 180\n\t<phi> is between -90 and 90"
        printfn "set speed <speed> - sets the speed of yer ship (<speed> is between 0.0 and 1.0)"
        printfn "survey <number> - attempts to survey a given entity <number>"

    let private ReportViewableEntities (entity:Entity) (world:World) : unit =
        let viewDistance = 10.0
        printfn "Viewable Entities:"
        let starsNearby = 
            world
            |> World.GetNonPlayers
            |> Map.filter
                (fun _ other -> 
                    Entity.DistanceBetween entity other <= viewDistance)
            |> Map.toList
            |> List.map 
                (fun (identifier, e) -> 
                    let distance = Entity.DistanceBetween entity e
                    let bearing = Entity.BearingBetween entity e
                    (identifier, e.EntityType |> EntityType.GetTypeName , distance, bearing))
        match starsNearby with
        | [] ->
            printfn "(nothing)"
        | entries ->
            entries
            |> List.sortBy 
                (fun (_,_,distance,_) -> distance)
            |> List.iter
                (fun (_,typeName, distance, (theta, phi)) -> 
                    printfn "Type: %s Distance: %.2f Bearing: %.2f x %.2f" typeName distance theta phi)

    let private ReportInteractableEntities (entity:Entity) (world:World) : unit =
        let interactDistance = 1.0
        printfn "Interactable Entities:"
        let starsNearby = 
            world
            |> World.GetNonPlayers
            |> Map.filter
                (fun _ other -> 
                    Entity.DistanceBetween entity other <= interactDistance)
            |> Map.toList
            |> List.map 
                (fun (identifier, e) -> 
                    let distance = Entity.DistanceBetween entity e
                    let bearing = Entity.BearingBetween entity e
                    let star = e.EntityType |> EntityType.GetStar
                    (identifier, e.EntityType |> EntityType.GetTypeName , distance, bearing, world.EntityNumbers.[identifier], star))
        match starsNearby with
        | [] ->
            printfn "(nothing)"
        | entries ->
            entries
            |> List.sortBy 
                (fun (_,_,distance,_, _, _) -> distance)
            |> List.iter
                (fun (_,typeName, distance, (theta, phi), number, star) -> 
                    let suffix =
                        match star with
                        | Some s when s.Surveyed->
                            sprintf " (Fuel Available: %.0f/%.0f)" s.FuelAvailable s.FuelMaximum
                        | _ -> 
                            ""
                    printfn "Type: %s Distance: %.2f Bearing: %.2f x %.2f (Entity#: %d)%s" typeName distance theta phi number suffix)


    let private HandleGameOn(entity:Entity) (world:World) : World option = 
        printfn ""
        printfn "Ship Status:"
        printfn "Position: (%f, %f, %f)" entity.X entity.Y entity.Z
        printfn "Heading: (%f, %f)" entity.Theta entity.Phi
        printfn "Speed: (%f)" entity.Speed
        let ship = entity.EntityType |> EntityType.GetShip |> Option.get
        
        printfn "Surveyed Entities: %d/%d" ship.SurveyedEntities.Count Constants.StarCount
        printfn "Fuel: %d/%d" ship.Fuel ship.MaximumFuel
        ReportInteractableEntities entity world
        ReportViewableEntities entity world
        if ship.SurveyedEntities.Count = Constants.StarCount then
            Utility.PlayMusic Constants.WinSong
            ["You won the game!"]
            |> Utility.DisplayMessages
            None
        else
            match Utility.ReadLine() with
            | [ "refuel"; number] ->
                Refuel.Handle number entity world
            | [ "survey" ; number ] ->
                Survey.Handle number entity world
            | [ "engage" ] ->
                Move.Handle entity world
            | [ "set"; "speed"; speed ] ->
                SetSpeed.Handle speed entity world
            | [ "set" ; "heading" ; theta ; phi ]->
                SetHeading.Handle (theta, phi) entity world
            | [ "abandon" ] ->
                None
            | [ "help" ] ->
                HandleHelp()
                world |> Some
            | _ ->
                HandleInvalid()
                world |> Some

    let private HandleGameOver() : World option =
        Utility.PlayMusic Constants.LoseSong
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
        

