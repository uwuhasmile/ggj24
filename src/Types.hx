enum abstract InputActions(Int) from Int to Int {
    final MoveUp;
    final MoveDown;
    final MoveRight;
    final MoveLeft;
    final Focus;
    final Shoot;
}

enum abstract CollisionLayers(Int) from Int to Int {
    final Player = 1;
    final Graze = 2;
    final Bullet = 4;
    final Enemy = 8;
}

@:keep enum Position {
    Local(x : Float, y : Float);
    Relative(x : Float, y : Float);
    World(x : Float, y : Float);
    Entity(ent : Entity, ?x : Float, ?y : Float);
}

enum BulletMoveType {
    Stop;
    Fixed(?rotSpeed : Void->Float);
    Position(pos : Types.Position);
}

enum BulletAim {
    EntityFan(ent : Entity);
    Fan;
    EntityCircle(ent : Entity);
    Circle;
    RandomFan;
    RandomCircle;
    TotallyRandomFan;
}

enum Item {
    Power(v : Float, ?vx : Float);
    Value(v : Int, ?vx : Float);
    Joke;
}