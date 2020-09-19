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
    let internal StartSong = 
        [
            261, 200
            329, 200
            392, 200
            523, 400
            392, 200
            523, 400
        ]
    let internal IntroSong = 
        [
            261, 100
            293, 100
            329, 100
            349, 100
            392, 100
            440, 100
            494, 100
            523, 100
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


