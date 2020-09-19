namespace CSMoS

module MainMenu = 
    let private HandleInvalidInput () : unit =
        Utility.PlayMusic Constants.ErrorSong
        printfn ""
        printfn "Please type 'start', 'help' or 'quit'. There aren't any other options here!"

    let private HandleQuit() : unit =
        Utility.PlayMusic Constants.OutroSong
        printfn ""
        printfn "Thank you for playing!"

    let rec internal Run(world:World option) : unit =
        printfn ""
        printfn "Main Menu:"
        printfn "start - start the game"
        printfn "help - how to play"
        printfn "quit - quit the game"
        match Utility.ReadLine() with
        | [ "start" ] ->
            Utility.PlayMusic Constants.StartSong
            Run <| Game.Run (world |> Option.defaultWith World.Create)
        | [ "quit" ] ->
            HandleQuit()
        | _ ->
            HandleInvalidInput()
            Run world
