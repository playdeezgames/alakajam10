namespace CSMoS

module Constants =
    let internal InteractDistance = 1.0
    let internal ViewDistance = 10.0
    let internal WorldWidth = 50.0
    let internal WorldHeight = 50.0
    let internal WorldDepth = 50.0
    let internal StarCount = 100
    let internal WormholeCount = 10
    let internal StarRefuelRateRange = (1.0, 5.0)
    let internal StarMaximumFuelRange = (10.0, 50.0)
    let internal MaximumFuel = 100
    let internal StartSong = 
        [
            261, 200
            329, 200
            392, 200
            523, 400
            392, 200
            523, 400
        ]
    let internal LoseSong =
        [
            349, 200 //F
            261, 200 //C
            293, 200 //D
            261, 400 //C
            329, 200 //E
            349, 600 //F
        ]
    let internal IntroSong = 
        [
            261, 100 //C
            293, 100 //D
            329, 100 //E
            349, 100 //F
            392, 100 //G
            440, 100 //A
            494, 100 //B
            523, 100 //C
        ]
    let internal SurveyStarSong = 
        [
            494, 200 //B
            440, 200 //A
            392, 200 //G
            440, 200 //A
            494, 200 //B
            494, 200 //B
            494, 400 //B
        ]

    let internal WormholeSong = 
        [
            261, 100 //C
            392, 100 //G
            293, 100 //D
            494, 100 //B
            329, 100 //E
            349, 100 //F
            329, 100 //E
            329, 100 //E
            392, 100 //G
            440, 100 //A
            329, 100 //E
            494, 100 //B
            349, 100 //F
            523, 100 //C
        ]
    let internal RefuelSong =
        [
            261, 100 //C
            329, 100 //E
            392, 100 //G
            523, 100 //C
            261, 100 //C
            329, 100 //E
            392, 100 //G
            523, 100 //C
        ]
    let internal WinSong =
        [
            261, 200 //C
            261, 200 //C
            261, 200 //C
            392, 800 //G
            392, 200 //G
            392, 200 //G
            440, 400 //A
            392, 200 //G
            349, 200 //F
            392, 400 //G
            261, 800 //C
        ]
    let internal OutroSong = 
        [
            523, 100
            494, 100
            440, 100
            392, 100
            349, 100
            329, 100
            293, 100
            261, 100
        ]
    let internal ErrorSong = 
        [
            130, 250
        ]


