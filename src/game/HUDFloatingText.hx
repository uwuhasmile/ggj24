package game;

import h2d.Text;

class HUDFloatingText extends Text {
    private var time: Float = 0.0;

    public function new(x: Float, y: Float, text: String, ?p: h2d.Object):Void {
        super(hxd.res.DefaultFont.get(), p);
        this.x = x;
        this.y = y;
        textAlign = Center;
        this.text = text;
        time = 0.0;
        setScale(1.4);
    }

    public override function sync(ctx: h2d.RenderContext):Void {
        super.sync(ctx);
        if (time > 1.0) {
            remove();
            return;
        }
        time += ctx.elapsedTime;
        y -= 9.0 * ctx.elapsedTime;
    }
}