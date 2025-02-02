package heaps;

import h2d.SpriteBatch;
import h2d.Tile;

private class BackgroundLayer extends BatchElement {
	public var hScroll : Float;
	public var vScroll : Float;
	public var hScrollSpeed : Float;
	public var vScrollSpeed : Float;
	public var parallaxScale : Float;
	public var hWrap : Bool;
	public var vWrap : Bool;
	public var followCamera : Bool;

	public function new(t: Tile, h: Float, v: Float, hs: Float, vs: Float, ps: Float, hw: Bool, vw: Bool, fc: Bool) {
		super(t);
		hScroll = h;
		vScroll = v;
		hScrollSpeed = hs;
		vScrollSpeed = vs;
		parallaxScale = ps;
		hWrap = hw;
		vWrap = vw;
		followCamera = fc;
	}
}

private typedef BackgroundColorTween = {
	withTime : Float,
	time : Float,
	startR : Float,
	startG : Float,
	startB : Float,
    startA : Float,
	?r : Float,
	?g : Float,
	?b : Float,
    ?a : Float,
}

private typedef BackgroundScrollTween = {
	withTime : Float,
	time : Float,
	startH : Float,
	startV : Float,
	?h : Float,
	?v : Float,
}

private typedef BackgroundScrollSpeedTween = {
	withTime : Float,
	time : Float,
	startH : Float,
    startV : Float,
	?h : Float,
    ?v : Float,
}

private typedef CameraPosTween = {
	withTime : Float,
	time : Float,
	startX : Float,
    startY : Float,
	?x : Float,
    ?y : Float,
}

private typedef CameraVelTween = {
	withTime : Float,
	time : Float,
	startX : Float,
    startY : Float,
	?x : Float,
    ?y : Float,
}

class Background extends SpriteBatch {
	public var cameraVelocityX(default, null) : Float;
	public var cameraVelocityY(default, null) : Float;
    public var cameraX(default, null) : Float;
    public var cameraY(default, null) : Float;

    private var layers : Map<Int, BackgroundLayer>;
	private var layerColorTweens : Map<Int, BackgroundColorTween>;
	private var layerScrollTweens : Map<Int, BackgroundScrollTween>;
	private var layerScrollSpeedTweens : Map<Int, BackgroundScrollSpeedTween>;
	private var cameraPosTween : CameraPosTween;
	private var cameraVelTween : CameraVelTween;

    public function new(?parent: h2d.Object) {
        super(null, parent);
		layers = new Map();
		layerColorTweens = new Map();
		layerScrollTweens = new Map();
		layerScrollSpeedTweens = new Map();
		cameraVelocityX = 0.0;
		cameraVelocityY = 0.0;
		cameraX = 0.0;
		cameraY = 0.0;
		cameraPosTween = null;
		cameraVelTween = null;
    }

	public function load(path: String):Void {
		final xmlContent = hxd.Res.load(path).toText();
        final xmlTree = Xml.parse(xmlContent).firstElement();
        if (xmlTree.nodeName != "background") throw 'Invalid background $path!';
		if (xmlTree.get("cameraX") != null) cameraX = Std.parseFloat(xmlTree.get("cameraX"));
		if (xmlTree.get("cameraY") != null) cameraX = Std.parseFloat(xmlTree.get("cameraY"));
		if (xmlTree.get("cameraVelocityX") != null) cameraVelocityX = Std.parseFloat(xmlTree.get("cameraVelocityX"));
		if (xmlTree.get("cameraVelocityY") != null) cameraVelocityY = Std.parseFloat(xmlTree.get("cameraVelocityY"));
		for (el in xmlTree.elementsNamed("layer")) {
            if (el.get("idx") == null) throw 'Invalid background $path - no index!';
			final idx = Std.parseInt(el.get("idx"));
			if (el.get("src") == null) throw 'Invalid background $path!';
			layers[idx] = new BackgroundLayer(
				hxd.Res.load(el.get("src")).toTile(),
				Std.parseFloat(el.get("hScroll") ?? "0"),
				Std.parseFloat(el.get("vScroll") ?? "0"),
				Std.parseFloat(el.get("hScrollSpeed") ?? "0"),
				Std.parseFloat(el.get("vScrollSpeed") ?? "0"),
				Std.parseFloat(el.get("parallaxScale") ?? "1"),
				(el.get("hWrap") ?? "true") != "false",
				(el.get("vWrap") ?? "true") != "false",
				(el.get("followCamera") ?? "false") != "false",
			);
			add(layers[idx]);
			layers[idx].x = 0.0;
			layers[idx].y = 0.0;
			layers[idx].r = Std.parseFloat(el.get("r") ?? "1");
			layers[idx].g = Std.parseFloat(el.get("g") ?? "1");
			layers[idx].b = Std.parseFloat(el.get("b") ?? "1");
			layers[idx].a = Std.parseFloat(el.get("a") ?? "1");
        }
	}

	public override function clear():Void {
		super.clear();
		cameraVelocityX = 0.0;
		cameraVelocityY = 0.0;
		cameraX = 0.0;
		cameraY = 0.0;
		layers.clear();
		layerColorTweens.clear();
		layerScrollTweens.clear();
		layerScrollSpeedTweens.clear();
		cameraPosTween = null;
		cameraVelTween = null;
	}

	public function setLayerColor(idx: Int, ?r: Float, ?g: Float, ?b: Float, ?a: Float, ?time: Float):Void {
		if (!layers.exists(idx)) return;
		if (time == null || time <= 0.0) {
			if (r != null) layers[idx].r = r;
			if (g != null) layers[idx].g = g;
			if (b != null) layers[idx].b = b;
			if (a != null) layers[idx].a = a;
			return;
		}
		layerColorTweens[idx] = { 
			withTime : time,
			time : 0.0,
			startR : layers[idx].r,
			startG : layers[idx].g,
			startB : layers[idx].b,
			startA : layers[idx].a,
			r : r,
			g : g,
			b : b,
			a : a,
		};
	}

	public function setLayerScroll(idx: Int, ?h: Float, ?v: Float, ?time: Float):Void {
		if (!layers.exists(idx)) return;
		if (time == null || time <= 0.0) {
			if (h != null) layers[idx].hScroll = h;
			if (v != null) layers[idx].vScroll = v;
			return;
		}
		layerScrollTweens[idx] = { 
			withTime : time,
			time : 0.0,
			startH : layers[idx].hScroll,
			startV : layers[idx].vScroll,
			h : h,
			v : v,
		};
	}

	public function setLayerScrollSpeed(idx: Int, ?h: Float, ?v: Float, ?time: Float):Void {
		if (!layers.exists(idx)) return;
		if (time == null || time <= 0.0) {
			if (h != null) layers[idx].hScrollSpeed = h;
			if (v != null) layers[idx].vScrollSpeed = v;
			return;
		}
		layerScrollSpeedTweens[idx] = { 
			withTime : time,
			time : 0.0,
			startH : layers[idx].hScrollSpeed,
			startV : layers[idx].hScrollSpeed,
			h : h,
			v : v,
		};
	}

	public function setCameraPos(?x: Float, ?y: Float, ?time: Float):Void {
		if (time == null || time <= 0.0) {
			if (x != null) cameraX = x;
			if (y != null) cameraY = y;
			return;
		}
		cameraPosTween = { 
			withTime : time,
			time : 0.0,
			startX : cameraX,
			startY : cameraY,
			x : x,
			y : y,
		};
	}

	public function setCameraVel(?x: Float, ?y: Float, ?time: Float):Void {
		if (time == null || time <= 0.0) {
			if (x != null) cameraVelocityX = x;
			if (y != null) cameraVelocityY = y;
			return;
		}
		cameraVelTween = { 
			withTime : time,
			time : 0.0,
			startX : cameraVelocityX,
			startY : cameraVelocityY,
			x : x,
			y : y,
		};
	}

	public override function sync(ctx: h2d.RenderContext):Void {
		for (idx => l in layers) {
			if (layerScrollTweens.exists(idx)) {
				final t = hxd.Math.clamp(layerScrollTweens[idx].time / layerScrollTweens[idx].withTime);
				if (layerScrollTweens[idx].h != null) l.hScroll = hxd.Math.lerp(layerScrollTweens[idx].startH, layerScrollTweens[idx].h, t);
				if (layerScrollTweens[idx].v != null) l.vScroll = hxd.Math.lerp(layerScrollTweens[idx].startV, layerScrollTweens[idx].v, t);
				if (t == 1.0) layerScrollTweens.remove(idx);
				else layerScrollTweens[idx].time += ctx.elapsedTime;
			}
			if (layerScrollSpeedTweens.exists(idx)) {
				final t = hxd.Math.clamp(layerScrollSpeedTweens[idx].time / layerScrollSpeedTweens[idx].withTime);
				if (layerScrollSpeedTweens[idx].h != null) l.hScroll = hxd.Math.lerp(layerScrollSpeedTweens[idx].startH, layerScrollSpeedTweens[idx].h, t);
				if (layerScrollSpeedTweens[idx].v != null) l.vScroll = hxd.Math.lerp(layerScrollSpeedTweens[idx].startV, layerScrollSpeedTweens[idx].v, t);
				if (t == 1.0) layerScrollSpeedTweens.remove(idx);
				else layerScrollTweens[idx].time += ctx.elapsedTime;
			}
			l.hScroll += l.hScrollSpeed * ctx.elapsedTime;
			l.vScroll += l.vScrollSpeed * ctx.elapsedTime;
		}
		if (cameraPosTween != null) {
			final t = hxd.Math.clamp(cameraPosTween.time / cameraPosTween.withTime);
			if (cameraPosTween.x != null) cameraX = hxd.Math.lerp(cameraPosTween.startX, cameraPosTween.x, t);
			if (cameraPosTween.y != null) cameraY = hxd.Math.lerp(cameraPosTween.startY, cameraPosTween.y, t);
			if (t == 1.0) cameraPosTween = null;
			else cameraPosTween.time += ctx.elapsedTime;
		}
		if (cameraVelTween != null) {
			final t = hxd.Math.clamp(cameraVelTween.time / cameraVelTween.withTime);
			if (cameraVelTween.x != null) cameraVelocityX = hxd.Math.lerp(cameraVelTween.startX, cameraVelTween.x, t);
			if (cameraVelTween.y != null) cameraVelocityY = hxd.Math.lerp(cameraVelTween.startY, cameraVelTween.y, t);
			if (t == 1.0) cameraVelTween = null;
			else cameraVelTween.time += ctx.elapsedTime;
		}
		cameraX += cameraVelocityX * ctx.elapsedTime;
		cameraY += cameraVelocityY * ctx.elapsedTime;
		super.sync(ctx);
	}

    private override function draw(ctx: h2d.RenderContext):Void {
		for (idx => l in layers) {
			if (layerColorTweens.exists(idx)) {
				final t = hxd.Math.clamp(layerColorTweens[idx].time / layerColorTweens[idx].withTime);
				if (layerColorTweens[idx].r != null) l.r = hxd.Math.lerp(layerColorTweens[idx].startR, layerColorTweens[idx].r, t);
				if (layerColorTweens[idx].g != null) l.g = hxd.Math.lerp(layerColorTweens[idx].startG, layerColorTweens[idx].g, t);
				if (layerColorTweens[idx].b != null) l.b = hxd.Math.lerp(layerColorTweens[idx].startB, layerColorTweens[idx].b, t);
				if (layerColorTweens[idx].a != null) l.a = hxd.Math.lerp(layerColorTweens[idx].startA, layerColorTweens[idx].a, t);
				if (t == 1.0) layerColorTweens.remove(idx);
				else layerColorTweens[idx].time += ctx.elapsedTime;
			}
			final cameraX = l.followCamera ? 0.0 : this.cameraX;
			final cameraY = l.followCamera ? 0.0 : this.cameraY;
			l.t.setPosition(l.hWrap ? (-l.hScroll + cameraX) * l.parallaxScale : 0.0, l.vWrap ? (-l.vScroll + cameraY) * l.parallaxScale : 0.0);
			if (!l.hWrap) l.t.dx = (l.hScroll - cameraX) * l.parallaxScale;
			if (!l.vWrap) l.t.dy = (l.vScroll - cameraY) * l.parallaxScale;
			final szX = (l.hWrap ? ctx.scene.width : l.t.width);
			final szY = (l.vWrap ? ctx.scene.height : l.t.height);
			l.t.setSize(szX, szY);
			l.t.scaleToSize(szX, szY);
			tileWrap = l.hWrap || l.vWrap; 
		}
		super.draw(ctx);
	}
}