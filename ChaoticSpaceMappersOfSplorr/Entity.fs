namespace CSMoS

open System

type Entity =
    {
        EntityType : EntityType
        X: float
        Y: float
        Z: float
        Theta: float
        Phi : float
        Speed: float
    }

module Entity =
    let Create(entityType:EntityType) : Entity =
        {
            EntityType = entityType
            X = 0.0
            Y = 0.0
            Z = 0.0
            Theta = 0.0
            Phi = 0.0
            Speed = 0.0
        }

    let SetTheta (theta:float) (entity:Entity) : Entity =
        {entity with 
            Theta = theta}

    let SetPhi (phi:float) (entity:Entity) : Entity =
        {entity with 
            Phi = phi}

    let SetSpeed (speed:float) (entity:Entity) : Entity =
        {entity with
            Speed = speed}

    let SetX (x:float) (entity:Entity) : Entity =
        {entity with
            X = x}

    let SetY (y:float) (entity:Entity) : Entity =
        {entity with
            Y = y}

    let SetZ (z:float) (entity:Entity) : Entity =
        {entity with
            Z = z}

    let Move (interactor: Entity -> Entity option * 'T) (updator: Entity option -> 'T -> 'T) (entity:Entity) : 'T =
        let deltaX = entity.Speed * cos(entity.Theta|> Utility.ToRadians) * cos(entity.Phi|> Utility.ToRadians)
        let deltaY = entity.Speed * sin(entity.Theta|> Utility.ToRadians) * cos(entity.Phi|> Utility.ToRadians)
        let deltaZ = entity.Speed * sin(entity.Phi|> Utility.ToRadians)
        entity
        |> SetX (entity.X + deltaX)
        |> SetY (entity.Y + deltaY)
        |> SetZ (entity.Z + deltaZ)
        |> interactor
        ||> updator

    let DistanceBetween (first:Entity) (second:Entity) : float =
        let deltaX = first.X - second.X
        let deltaY = first.Y - second.Y
        let deltaZ = first.Z - second.Z 
        sqrt(deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ)


