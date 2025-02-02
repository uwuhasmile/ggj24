package game;

import h2d.Text;

class FloatingText extends Text {
    private var time: Float = 0.0;

    public function new(x: Float, y: Float, value: Float):Void {
        super(hxd.Res.fonts.fntFloatingText.toFont());
        if (Main.instance.s2d != null) Main.instance.s2d.add(this, 6);
        this.x = x;
        this.y = y;
        textAlign = Center;
        text = '+${Std.int(value * 100.0) / 100}';
        time = 0.0;
        setScale(0.6);
    }

    public override function sync(ctx: h2d.RenderContext):Void {
        super.sync(ctx);
        if (time > 0.5) {
            remove();
            return;
        }
        time += ctx.elapsedTime;
        y -= 9.0 * ctx.elapsedTime;
    }
}