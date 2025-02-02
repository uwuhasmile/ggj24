class Timer extends Entity {
    public var time(default, set) : Float;
        inline private function set_time(val: Float) return time = (val < 0.0 ? 0.0 : val);
    public var loop : Bool;
    public var onTimeout : Void->Void;

    public var active(default, null) : Bool;
    private var currentAmount : Float;

    private override function added(_):Void {
        active = false;
        currentAmount = -1.0;
    }

    private override function update(delta: Float):Void {
        if (!active) return;
        if (currentAmount < 0.0) {
            if (loop) currentAmount = time;
            else active = false;
            onTimeout();
            return;
        }
        currentAmount -= delta;
    }

    public function start(?t : Float):Void {
        if (t != null) time = t;
        active = true;
        currentAmount = time;
    }

    public function stop():Void {
        active = false;
    }
}