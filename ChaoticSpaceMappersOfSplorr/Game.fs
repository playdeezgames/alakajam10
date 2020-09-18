namespace CSMoS

module Game = 
    let private HandleInvalid() : unit =
        printfn ""
        printfn "Maybe try 'help'?"

    let private HandleHelp() : unit =
        printfn ""
        printfn "In Game Help:"
        printfn "abandon - abandon the game and return to the main menu"
        printfn "help - show help (you are here!)"

    let private HandleGameOn(ship:Ship) (world:World) : World option = 
        printfn ""
        printfn "Ship Status:"
        printfn "Position: (%f, %f, %f)" ship.X ship.Y ship.Z
        printfn "Heading: (%f, %f)" ship.Theta ship.Phi
        printfn "Speed: (%f)" ship.Speed
        match Utility.ReadLine() with
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
        match world |> World.GetPlayerShip with
        | Some ship ->
            match HandleGameOn ship world with
            | Some next ->
                Run next
            | None ->
                HandleGameOver()
        | None ->
            HandleGameOver()    
        

