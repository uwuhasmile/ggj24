package game;

import h2d.SpriteBatch;

private class Item extends BatchElement {
    public var radius : Float;
    public var vx : Float;
    public var vy : Float;
    public var type : Types.Item;

    public function new(type: Types.Item):Void {
        this.type = type;
        final tiles = hxd.Res.load("sprites/game/sprItems.png").toTile().split(3);
        t = switch (type) {
            case Power(_): tiles[0];
            case Value(_): tiles[1];
            case Joke: tiles[2];
        }
        super(t);
    }

    public function init(x: Float, y: Float):Void {
        this.x = x;
        this.y = y;
        switch (type) {
            case Power(v, vx): {
                radius = 0.4;
                scale = v / 0.05;
                this.vx = vx ?? 0.0;
                this.vy = -50.0;
            }
            case Value(v, vx): {
                radius = 0.4;
                scale = v / 0.05;
                this.vx = vx ?? 0.0;
                this.vy = -50.0;
            }
            case Joke: {
                radius = 0.25;
                rotation = hxd.Math.random(hxd.Math.PI);
                vx = hxd.Math.cos(rotation) * 25.0;
                vy = hxd.Math.sin(rotation) * 25.0;
            }
        }
        scale = hxd.Math.clamp(scaleX, 0.4, 1.5);
    }
}

class ItemManager extends Entity {
    private var batch : SpriteBatch;
    private var player : Player;

    private override function added(s2d: h2d.Scene):Void {
        batch = new SpriteBatch(null);
        batch.hasRotationScale = true;
        s2d.add(batch, 4);
        player = scene.getEntity(Player);
    }

    public function spawn(type: Types.Item, x: Float, y: Float):Void {
        final item = new Item(type);
        batch.add(item);
        item.init(x, y);
    }

    public function clear():Void {
        batch.clear();
    }

    private override function update(delta: Float):Void {
        for (el in batch.getElements()) {
            if (el.x < Const.PLAYFIELD_PLAYABLE_LEFT - 60.0 || el.x > Const.PLAYFIELD_PLAYABLE_RIGHT + 60.0 ||
                    el.y < Const.PLAYFIELD_PLAYABLE_TOP - 60.0 || el.y > Const.PLAYFIELD_PLAYABLE_BOTTOM + 60.0) {
                el.remove();
                continue;
            }
            final item = cast (el, Item);
            switch (item.type) {
                case Power(_, _) | Value(_, _): item.vy += 150.0 * delta;
                case Joke: { }
            }
            item.x += item.vx * delta;
            item.y += item.vy * delta;
        }
    }

    private override function fixedUpdate(delta: Float):Void {
        if (player == null || player.damagedTime > 0.0 || !player.isAlive()) return;
        for (el in batch.getElements()) {
            final item = cast (el, Item);
            final distance = (player.x - item.x) * (player.x - item.x) + (player.y - item.y) * (player.y - item.y);
            if (distance <= (item.radius + Const.PLAYER_GRAZEBOX_RADIUS) * (item.radius + Const.PLAYER_GRAZEBOX_RADIUS)) {
                switch (item.type) {
                    case Power(v, _): {
                        player.addPower(v);
                        new FloatingText(item.x, item.y, v);
                    }
                    case Value(v, _): {
                        player.addScore(v);
                        new FloatingText(item.x, item.y, v);
                    }
                    case Joke:  {
                        player.addBullet();
                        new FloatingText(item.x, item.y, 1);
                    }
                }
                AudioManager.instance.playSound(3, "sounds/sndPickupItem.wav");
                item.remove();
            }
        }
    }
}