open CSMoS

open System

[<EntryPoint>]
let main _ =
    Constants.IntroSong
    |> Utility.PlayMusic
    Console.Title <- "Chaotic Space Mappers of SPLORR!!"
    Runner.Run()
    0
