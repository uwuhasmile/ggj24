import hxd.Key;

enum ActionInput {
    Pressed(key: Int);
    Released(key: Int);
    Down(key: Int);
}

private typedef InputAction = {
    inputs : Array<ActionInput>,
    result : Bool
}

class InputManager {
    public static var instance(default, null) : InputManager;

    private var actions : Map<Int, InputAction>;

    @:allow(Main.init)
    private function new():Void {
        instance = this;
        actions = new Map();
    }

    public function addAction(id: Int, inputs: Array<ActionInput>):Void {
        if (actions.exists(id)) throw 'Action $id already exists!';
        actions[id] = { inputs: inputs, result: false };
    }

    public function removeAction(id: Int, inputs: Array<ActionInput>):Void {
        if (!actions.exists(id)) throw 'Action $id does not exist!';
        actions.remove(id);
    }

    inline public function getActionResult(id: Int):Bool {
        if (!actions.exists(id)) throw 'Action $id does not exist!';
        return actions[id].result;
    }

    inline public function getActionValue(id: Int):Float {
        if (!actions.exists(id)) throw 'Action $id does not exist!';
        return actions[id].result ? 1.0 : 0.0;
    }

    @:allow(Main.update)
    private function update():Void {
        for (a in actions) {
            a.result = false;
            for (i in a.inputs)
                switch (i) {
                    case Pressed(key): if (Key.isPressed(key)) {
                        a.result = true;
                        break;
                    }
                    case Released(key): if (Key.isReleased(key)) {
                        a.result = true;
                        break;
                    }
                    case Down(key): if (Key.isDown(key)) {
                        a.result = true;
                        break;
                    }
                }
        }
    }

}