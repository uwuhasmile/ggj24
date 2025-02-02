package game;

import heaps.Sprite;

class PlayerBullet extends Entity {
    private var sprite : Sprite;

    private var level : Int;

    private override function added(s2d: h2d.Scene):Void {
        sprite = new Sprite();
        s2d.add(sprite, 2);
        sprite.load("sprites/game/sprPlayerBullets.xml");
    }

    private override function destroyed(s2d: h2d.Scene):Void {
        sprite.remove();
    }

    public function setLevel(level: Int):Void {
        this.level = level;
        sprite.play(level);
    }

    private override function update(delta: Float):Void {
        if (x < Const.PLAYFIELD_PLAYABLE_LEFT - 64.0 || x > Const.PLAYFIELD_PLAYABLE_RIGHT + 64.0 ||
                y < Const.PLAYFIELD_PLAYABLE_TOP - 64.0 || y > Const.PLAYFIELD_PLAYABLE_BOTTOM + 64.0) {
            destroy();
            return;
        }
        y -= 150.0 * delta;
    }

    private override function fixedUpdate(delta: Float):Void {
        if (markedForDeletion) return;
        final radius = 6.0 + level;
        for (enemy in scene.getAllOfType(Enemy)) {
            final distance = (enemy.x - x) * (enemy.x - x) + (enemy.y - y) * (enemy.y - y);
            if (distance <= (enemy.radius + radius) * (enemy.radius + radius)) {
                if (enemy.layer & Types.CollisionLayers.Enemy == Types.CollisionLayers.Enemy) enemy.applyDamage(10 * (level + 1));
                AudioManager.instance.playSound(7, "sounds/sndPlayerBulletHit.wav");
                destroy();
            }
        }
    }

    private override function render():Void {
        sprite.x = x;
        sprite.y = y;
    }
}