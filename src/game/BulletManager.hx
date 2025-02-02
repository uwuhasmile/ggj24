package game;

import h2d.Tile;
import h2d.SpriteBatch;

private class Bullet extends BatchElement {
    public var speed : Float;
    public var grazeCount : Int;
    public var radius : Float;

    public function new(t: Tile, manager: BulletManager, speed: Float, rotation: Float, radius: Float):Void {
        super(t);
        this.radius = radius;
        this.rotation = rotation;
        this.speed = speed;
        grazeCount = 0;
    }
}

class BulletManager extends Entity {
    @:allow(game.Enemy)
    public var parent(default, null) : Enemy;

    public var destroyWithParent : Bool;
    public var autoDestroy : Bool;

    private var batch : SpriteBatch;
    public var player : Player;

    public var aim : Types.BulletAim;
    public var countA : Int;
    public var countB : Int;
    public var angleA : Float;
    public var angleB : Float;
    public var speedA : Float;
    public var speedB : Float;
    public var radiusA : Float;
    public var radiusB : Float;
    @:keep public var moveType : Types.BulletMoveType;

    private var tiles : Array<Tile>;
    public var bulletType : Int;

    public var hitmask : Int;
    public var hitRadius : Float;

    private override function added(s2d: h2d.Scene) {
        batch = new SpriteBatch(null);
        s2d.add(batch, 3);
        batch.hasRotationScale = true;
        tiles = new Array();
        aim = Types.BulletAim.Fan;
        countA = countB = 1;
        angleA = angleB = 0.0;
        speedA = speedB = 0.0;
        radiusA = radiusB = 0.0;
        moveType = Types.BulletMoveType.Fixed();
        destroyWithParent = false;
        bulletType = -1;
        autoDestroy = true;
    }

    private override function destroyed(s2d: h2d.Scene) {
        batch.clear();
        batch.remove();
        tiles.resize(0);
        tiles = null;
    }

    @:allow(game.BulletManager.Bullet)
    private function bulletRemoved():Void {
        if (parent == null && batch.isEmpty()) destroy();
    }

    private override function update(delta: Float):Void {
        for (e in batch.getElements()) {
            final b : Bullet = cast e;
            if ((parent == null || autoDestroy) &&
                    (b.x < Const.PLAYFIELD_PLAYABLE_LEFT + b.t.dx || b.x > Const.PLAYFIELD_PLAYABLE_RIGHT - b.t.dx ||
                    b.y < Const.PLAYFIELD_PLAYABLE_TOP + b.t.dy || b.y > Const.PLAYFIELD_PLAYABLE_BOTTOM - b.t.dy
                    )) {
                b.remove();
                bulletRemoved();
                continue;
            }
            final speed = b.speed * delta;
            var vx : Float = 0.0;
            var vy : Float = 0.0;
            switch (moveType) {
                case Stop: { }
                case Fixed(rotSpeed): {
                    if (rotSpeed != null) b.rotation += rotSpeed() * delta;
                    vx = Math.cos(b.rotation) * speed;
                    vy = Math.sin(b.rotation) * speed;
                }
                case Position(pos): {
                    var destX : Float;
                    var destY : Float;
                    var thisX : Float;
                    var thisY : Float;
                    switch (pos) {
                        case Local(x, y): {
                            destX = x;
                            destY = y;
                            thisX = b.x - parent.x ?? 0.0;
                            thisY = b.y - parent.y ?? 0.0;
                        }
                        case Relative(x, y): {
                            destX = x;
                            destY = y;
                            thisX = b.x - Const.ENEMY_BASE_X;
                            thisY = b.y - Const.ENEMY_BASE_Y;
                        }
                        case World(x, y): {
                            destX = x;
                            destY = y;
                            thisX = b.x;
                            thisY = b.y;
                        }
                        case Entity(ent, x, y): {
                            destX = ent.x + (x ?? 0.0);
                            destY = ent.y + (y ?? 0.0);
                            thisX = b.x;
                            thisY = b.y;
                        }
                    };
                    vx = destX - thisX;
                    vy = destY - thisY;
                    var length = vx * vx + vy * vy;
                    if (length > 0.0 && hxd.Math.sqrt(length) > speed) {
                        length = hxd.Math.sqrt(length); 
                        vx = vx / length * speed;
                        vy = vy / length * speed;
                        b.rotation = Math.atan2(vy, vx);
                    }
                }
            }
            b.x += vx;
            b.y += vy;
        }
    }

    private override function fixedUpdate(delta: Float):Void {
        if (player == null || !player.isAlive()) return;
        for (e in batch.getElements()) {
            final b : Bullet = cast e;
            final distance = (b.x - player.x) * (b.x - player.x) + (b.y - player.y) * (b.y - player.y);
            if (hitmask & Types.CollisionLayers.Player == Types.CollisionLayers.Player &&
                    distance < (Const.PLAYER_HITBOX_RADIUS + b.radius) * (Const.PLAYER_HITBOX_RADIUS + b.radius)) {
                player.applyDamage();
                b.remove();
                bulletRemoved();
            } else if (hitmask & Types.CollisionLayers.Graze == Types.CollisionLayers.Graze &&
                    distance <= (Const.PLAYER_GRAZEBOX_RADIUS + b.radius) * (Const.PLAYER_GRAZEBOX_RADIUS + b.radius))
                player.graze(cast b);
            else b.grazeCount = 0;
        }
    }

    public function load(path: String):Void {
        final xmlContent = hxd.Res.load(path).toText();
        final xmlTree = Xml.parse(xmlContent).firstElement();
        if (xmlTree.nodeName != "bullets") throw 'Invalid bullet set $path!';
        final sources = new Array<Tile>();
        for (el in xmlTree.elementsNamed("source")) {
            final value = el.firstChild().nodeValue;
            final originalTile = hxd.Res.load(value).toTile();
            sources.push(originalTile);
        }
        if (sources.length == 0) return;
        for (el in xmlTree.elementsNamed("tile")) {
            var src = Std.parseInt(el.get("src") ?? "0");
            if (src >= sources.length) src = 0;
            final x = Std.parseFloat(el.get("x") ?? "0");
            final y = Std.parseFloat(el.get("y") ?? "0");
            var width = Std.parseFloat(el.get("width") ?? '${sources[src].width}');
            if (width > sources[src].width) width = sources[src].width;
            var height = Std.parseFloat(el.get("height") ?? '${sources[src].height}');
            if (height > sources[src].height) height = sources[src].height;
            final tile = sources[src].sub(x, y, width, height).center();
            tiles.push(tile);
        }
    }

    public function shoot():Void {
        if (tiles.length == 0 || bulletType < 0 || bulletType >= tiles.length) return;
        switch (aim) {
            case EntityFan(ent): {
                final stepT = 1.0 / countB;
                final baseAngle = MathUtils.angleBetween(parent.x, parent.y, ent.x, ent.y) - Math.PI + angleA
                    - angleB * Math.ffloor(countA * 0.5) - angleB * (countA % 2 - 1) * 0.5;
                for (i in 0...countA)
                    for (j in 0...countB) {
                        final speed = hxd.Math.lerp(speedA, speedB, stepT * j);
                        final rotation = baseAngle + angleB * i;
                        final radius = hxd.Math.lerp(radiusA, radiusB, stepT * j);
                        final bullet = new Bullet(tiles[bulletType], this, speed, rotation, hitRadius);
                        final xOff = radius * Math.cos(rotation);
                        final yOff = radius * Math.sin(rotation);
                        batch.add(bullet);
                        bullet.x = (parent.x ?? 0.0) + xOff;
                        bullet.y = (parent.y ?? 0.0) + yOff;
                    }
            }
            case Fan: {
                final stepT = 1.0 / countB;
                final baseAngle = angleA - angleB * Math.ffloor(countA * 0.5) - angleB * (countA % 2 - 1) * 0.5;
                for (i in 0...countA)
                    for (j in 0...countB) {
                        final speed = hxd.Math.lerp(speedA, speedB, stepT * j);
                        final rotation = baseAngle + angleB * i;
                        final radius = hxd.Math.lerp(radiusA, radiusB, stepT * j);
                        final bullet = new Bullet(tiles[bulletType], this, speed, rotation, hitRadius);
                        final xOff = radius * Math.cos(rotation);
                        final yOff = radius * Math.sin(rotation);
                        batch.add(bullet);
                        bullet.x = (parent.x ?? 0.0) + xOff;
                        bullet.y = (parent.y ?? 0.0) + yOff;
                    }
            }
            case EntityCircle(ent): {
                final angleStep = 2.0 * hxd.Math.PI / countA;
                final stepT = 1.0 / countB;
                final baseAngle = MathUtils.angleBetween(parent.x, parent.y, ent.x, ent.y) - Math.PI + angleA
                    - angleB * Math.ffloor(countA * 0.5) - angleB * (countA % 2 - 1) * 0.5;
                for (i in 0...countA)
                    for (j in 0...countB) {
                        final speed = hxd.Math.lerp(speedA, speedB, stepT * j);
                        final rotation = baseAngle + angleStep * i + angleB * j;
                        final radius = hxd.Math.lerp(radiusA, radiusB, stepT * j);
                        final bullet = new Bullet(tiles[bulletType], this, speed, rotation, hitRadius);
                        final xOff = radius * Math.cos(rotation);
                        final yOff = radius * Math.sin(rotation);
                        batch.add(bullet);
                        bullet.scale = 1.0;
                        bullet.x = (parent.x ?? 0.0) + xOff;
                        bullet.y = (parent.y ?? 0.0) + yOff;
                    }
            }
            case Circle: {
                final angleStep = 2.0 * hxd.Math.PI / countA;
                final stepT = 1.0 / countB;
                for (i in 0...countA)
                    for (j in 0...countB) {
                        final speed = hxd.Math.lerp(speedA, speedB, stepT * j);
                        final rotation = (angleStep + angleA) * i + angleB * j;
                        final radius = hxd.Math.lerp(radiusA, radiusB, stepT * j);
                        final bullet = new Bullet(tiles[bulletType], this, speed, rotation, hitRadius);
                        final xOff = radius * Math.cos(rotation);
                        final yOff = radius * Math.sin(rotation);
                        batch.add(bullet);
                        bullet.scale = 1.0;
                        bullet.x = (parent.x ?? 0.0) + xOff;
                        bullet.y = (parent.y ?? 0.0) + yOff;
                    }
            }
            case RandomFan: {
                final stepT = 1.0 / countB;
                for (i in 0...countA)
                    for (j in 0...countB) {
                        final speed = hxd.Math.lerp(speedA, speedB, stepT * j);
                        final rotation = angleA + (hxd.Math.random(angleB * 2.0) - angleB) * i;
                        final radius = hxd.Math.lerp(radiusA, radiusB, stepT * j);
                        final bullet = new Bullet(tiles[bulletType], this, speed, rotation, hitRadius);
                        final xOff = radius * Math.cos(rotation);
                        final yOff = radius * Math.sin(rotation);
                        batch.add(bullet);
                        bullet.scale = 1.0;
                        bullet.x = (parent.x ?? 0.0) + xOff;
                        bullet.y = (parent.y ?? 0.0) + yOff;
                    }
            }
            case RandomCircle: {
                final angleStep = 2.0 * hxd.Math.PI / countA;
                final stepT = 1.0 / countB;
                for (i in 0...countA)
                    for (j in 0...countB) {
                        final speed = (hxd.Math.random(speedB - speedA) + speedA);
                        final rotation = (angleStep + angleA) * i + angleB * j;
                        final radius = hxd.Math.lerp(radiusA, radiusB, stepT * j);
                        final bullet = new Bullet(tiles[bulletType], this, speed, rotation, hitRadius);
                        final xOff = radius * Math.cos(rotation);
                        final yOff = radius * Math.sin(rotation);
                        batch.add(bullet);
                        bullet.scale = 1.0;
                        bullet.x = (parent.x ?? 0.0) + xOff;
                        bullet.y = (parent.y ?? 0.0) + yOff;
                    }
            }
            case TotallyRandomFan: {
                final stepT = 1.0 / countB;
                for (i in 0...countA)
                    for (j in 0...countB) {
                        final speed = (hxd.Math.random(speedB - speedA) + speedA);
                        final rotation = angleA + (hxd.Math.random(angleB * 2.0) - angleB) * i;
                        final radius = hxd.Math.lerp(radiusA, radiusB, stepT * j);
                        final bullet = new Bullet(tiles[bulletType], this, speed, rotation, hitRadius);
                        final xOff = radius * Math.cos(rotation);
                        final yOff = radius * Math.sin(rotation);
                        batch.add(bullet);
                        bullet.scale = 1.0;
                        bullet.x = (parent.x ?? 0.0) + xOff;
                        bullet.y = (parent.y ?? 0.0) + yOff;
                    }
            }
        }
    }
}