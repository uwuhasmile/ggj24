class Scene {
    @:allow(Main.update)
    private function entered(s2d: h2d.Scene):Void { }
    @:allow(Main.update)
    private function exited(s2d: h2d.Scene):Void { }
    @:allow(Main.onEvent)
    private function event(event: hxd.Event):Void { }

    public function getEntity<T:Entity>(cl: Class<T>, num: Int = 0):T {
        var i : Int = 0;
        for (ent in Main.instance.getEntities())
            if (Std.isOfType(ent, cl)) {
                if (i == num) return cast ent;
                else i++;
            }
        return null;
    }

    public function getAllOfType<T:Entity>(cl: Class<T>):Iterator<T> {
        final list = new List<T>();
        for (ent in Main.instance.getEntities()) if (Std.isOfType(ent, cl)) list.add(cast ent);
        return list.iterator();
    }

    public function spawnEntity<T:Entity>(x: Float, y: Float, cl: Class<T>):T {
        var ent = Type.createInstance(cl, [x, y, this]);
        Main.instance.addEntity(ent);
        return cast ent;
    }
}