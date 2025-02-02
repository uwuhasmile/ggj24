package game;

import h2d.Bitmap;
import heaps.Sprite;
import heaps.Background;

private typedef DialogueUnit = {
    text : String,
    ?you : Bool,
    ?emotion : Int,
    ?event : Int,
}

class DialogueManager extends Entity {
    private var autoHide : Bool;
    private var charName : String;
    private var units : List<DialogueUnit>;
    private var layers : h2d.Layers;
    private var background : Background;
    private var sprite : Sprite;
    private var borders : h2d.Bitmap;
    private var text : h2d.Text;
    private var name : h2d.Text;
    private var inputEnabled : Bool;

    private var delta : Float;

    private var tweenTime : Float;
    private var state : Int;

    public var eventCb : Int->Void;

    public var startedCb : Void->Void;
    public var endedCb : Void->Void;
    public var hiddenCb : Void->Void;

    private var customEndedCb : Void->Void;
    private var customHiddenCb : Void->Void;

    private override function added(_):Void {
        layers = new h2d.Layers();
        units = new List();
        Main.instance.hud.add(layers, 1);
        background = new Background(layers);
        sprite = new Sprite(layers);
        sprite.y = 180.0;
        borders = new Bitmap(hxd.Res.sprites.hud.sprStorytellerBorders.toTile(), layers);
        final font = hxd.res.DefaultFont.get();
        text = new h2d.Text(font, layers);
        text.maxWidth = 300.0;
        text.x = 4.0;
        text.y = 128.0;
        text.textAlign = Center;
        name = new h2d.Text(font, layers);
        name.textAlign = Left;
        name.y = 112.0;
        name.x = 4.0;
        layers.visible = false;
        state = 0;
        inputEnabled = false;
        startedCb = endedCb = hiddenCb = null;
        customEndedCb = customHiddenCb = null;
    }

    private override function destroyed(_):Void {
        clear();
        layers.remove();
    }

    private override function update(delta: Float):Void {
        this.delta = delta;
    }

    private override function event(event: hxd.Event):Void {
        if (!inputEnabled || state != 2 || event.kind != EKeyDown) return;
        if (event.keyCode == hxd.Key.ENTER || event.keyCode == hxd.Key.Z) next();
    }

    private override function render():Void {
        switch (state) {
            case 0: return;
            case 1: {
                final t = hxd.Math.clamp(tweenTime / 0.2);
                layers.alpha = hxd.Math.lerp(0.0, 1.0, t);
                sprite.x = hxd.Math.lerp(240.0, 160.0, t);
                if (t == 1.0) makeShown();
                else tweenTime += delta;
            }
            case 2: {
                text.setScale(hxd.Math.valueMove(text.scaleX, 1.0, 2.0 * delta));
                text.alpha = hxd.Math.valueMove(text.alpha, 1.0, 4.0 * delta);
                final spriteY = (units != null && units.first() != null) ? ((units.first().you != null && units.first().you) ? 185.0 : 180.0) : 180.0;
                sprite.y = hxd.Math.lerp(sprite.y, spriteY, 12.0 * delta);
                final spriteA = (units != null && units.first() != null) ? ((units.first().you != null && units.first().you) ? 0.7 : 1.0) : 1.0;
                sprite.alpha = hxd.Math.valueMove(sprite.alpha, spriteA, 4.0 * delta);
            }
            case 3: {
                final t = hxd.Math.clamp(tweenTime / 0.2);
                layers.alpha = hxd.Math.lerp(1.0, 0.0, t);
                sprite.x = hxd.Math.lerp(160.0, 80.0, t);
                if (t == 1.0) makeHidden();
                else tweenTime += delta;
            }
        }
    }

    public function start(path: String, ?startedCb: Void->Void, ?endedCb: Void->Void, ?hiddenCb: Void->Void):Void {
        load(path);
        customEndedCb = endedCb;
        customHiddenCb = hiddenCb;
        layers.visible = true;
        state = 1;
        tweenTime = 0.0;
        if (this.startedCb != null) this.startedCb();
        if (startedCb != null) startedCb();
    }

    public function makeShown():Void {
        inputEnabled = true;
        state = 2;
        layers.alpha = 1.0;
        sprite.x = 160.0;
        tweenTime = 0.0;
        layers.visible = true;
        use(units.first());
    }

    public function makeHidden():Void {
        clear();
        if (hiddenCb != null) hiddenCb();
        if (customHiddenCb != null) {
            customHiddenCb();
            customHiddenCb = null;
        }
    }

    public function clear():Void {
        text.text = "";
        name.text = "";
        state = 0;
        layers.alpha = 0.0;
        sprite.clear();
        background.clear();
        tweenTime = 0.0;
        layers.visible = false;
        customEndedCb = null;
        customHiddenCb = null;
    }

    private function load(path: String):Void {
        final xmlContent = hxd.Res.load(path).toText();
        final xmlTree = Xml.parse(xmlContent).firstElement();
        if (xmlTree.nodeName != "dialogue") throw 'Invalid dialogue $path!';
        autoHide = xmlTree.get("autoHide") != null ? xmlTree.get("autoHide") != "false" : true;
        if (xmlTree.get("bg") != null) background.load(xmlTree.get("bg"));
        for (el in xmlTree.elementsNamed("character")) {
            if (el.get("src") == null) throw 'Invalid dialogue $path!';
            charName = el.firstChild().nodeValue ?? "";
            sprite.load(el.get("src"));
            break;
        }
        for (el in xmlTree.elementsNamed("phrase")) {
            units.add({
                text : el.firstChild().nodeValue,
                you : el.get("you") != null ? el.get("you") != "false" : null,
                emotion : el.get("emotion") != null ? Std.parseInt(el.get("emotion")) : null,
                event : el.get("event") != null ? Std.parseInt(el.get("event")) : null,
            });
        }
    }

    private function next():Void {
        if (state != 2) return;
        units.pop();
        if (units.first() == null) end();
        else use(units.first());
    }

    public function end():Void {
        inputEnabled = false;
        units.clear();
        if (autoHide) hide();
        if (endedCb != null) endedCb();
        if (customEndedCb != null) {
            customEndedCb();
            customEndedCb = null;
        }
    }

    public function hide():Void {
        state = 3;
    }

    private function use(unit: DialogueUnit):Void {
        text.text = unit.text;
        text.setScale(0.9);
        text.alpha = 0.8;
        if (unit.you != null) name.text = unit.you ? "Deu" : charName;
        if (unit.emotion != null) sprite.playOverride(unit.emotion);
        if (eventCb != null && unit.event != null) eventCb(unit.event);
    }
}