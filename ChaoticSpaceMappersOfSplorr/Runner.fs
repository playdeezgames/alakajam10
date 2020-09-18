namespace CSMoS

module Runner = 
    let internal Run() : unit =
        printfn "Welcome to the Chaotic Space Mappers of SPLORR!!"
        printfn "A production of TheGrumpyGameDev"
        printfn "For Alakajam 10"
        MainMenu.Run None
