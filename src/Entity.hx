abstract class Entity {
    public var x : Float;
    public var y : Float;

    @:allow(Main.update, Main.changeScene)
    public var scene(default, null) : Scene;

    public var markedForDeletion(default, null) : Bool;

    public var onDestroyed : Entity->Void;

    @:allow(Scene.spawnEntity)
    private final function new(x: Float, y: Float, scene: Scene):Void {
        this.x = x;
        this.y = y;
        this.scene = scene;
        markedForDeletion = false;
    }

    public function dontDestroy():Void {
        if (Main.instance.dontDestroy.contains(this)) return;
        Main.instance.dontDestroy.push(this);
    }

    public final function destroy():Void {
        markedForDeletion = true;
    }

    @:allow(Main.addEntity)
    private function added(s2d: h2d.Scene):Void { };
    @:allow(Main.update)
    private function destroyed(s2d: h2d.Scene):Void { };
    @:allow(Main.update)
    private function sceneReloaded():Void { }

    @:allow(Main.update)
    private function preUpdate():Void { };
    @:allow(Main.update)
    private function update(delta: Float):Void { };
    @:allow(Main.update)
    private function fixedUpdate(delta: Float):Void { };
    @:allow(Main.onEvent)
    private function event(event: hxd.Event):Void { };
    @:allow(Main.update)
    private function render():Void { };
}