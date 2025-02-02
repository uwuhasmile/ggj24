package game;

import h2d.Particles;
import hscript.Interp;
import hscript.Parser;
import heaps.Sprite;

private typedef EnemyEvent = {
    time : Float,
    cb : Void->Void,
}

private typedef EnemyDestinationPoint = {
    pos : Types.Position,
    speed : Float,
    ?cb : Void->Void,
}

class Enemy extends Entity {
    private var parent : Enemy;

    private var lx(get, set) : Float;
        @:keep inline private function get_lx():Float return x - (parent != null ? parent.x : Const.ENEMY_BASE_X);
        @:keep inline private function set_lx(val: Float):Float return x = (parent != null ? parent.x : Const.ENEMY_BASE_X) + val;
    private var ly(get, set) : Float;
        @:keep inline private function get_ly():Float return y - (parent != null ? parent.y : Const.ENEMY_BASE_Y);
        @:keep inline private function set_ly(val: Float):Float return y = (parent != null ? parent.x : Const.ENEMY_BASE_Y) + val;
    private var rx(get, set) : Float;
        @:keep inline private function get_rx():Float return x - Const.ENEMY_BASE_X;
        @:keep inline private function set_rx(val: Float):Float return x = Const.ENEMY_BASE_X + val;
    private var ry(get, set) : Float;
        @:keep inline private function get_ry():Float return y - Const.ENEMY_BASE_Y;
        @:keep inline private function set_ry(val: Float):Float return y = Const.ENEMY_BASE_Y + val;

    public var paused : Bool;

    private var sprite : Sprite;
    private var healthBar : h2d.Graphics;
    private var damageParticles : Particles;
    private var damageParticlesConfig : Dynamic;
    private var deathParticlesConfig : Dynamic;
    private var damageSound : String;
    private var deathSound : String;
    
    private var events : Array<EnemyEvent>;
    private var time : Float;
    private var player : Player;
    private var itemManager : ItemManager;
    private var dialogueManager : DialogueManager;
    private var moveDestQueue : List<EnemyDestinationPoint>;
    private var children : Array<Enemy>;

    private var preparedParams : Map<String, Any>;

    private var bulletManagers : Map<Int, BulletManager>;

    private var healthbarRadius : Float;

    public var radius : Float;
    private var mask : Int;
    public var layer(default, null) : Int;
    private var maxHealth : Int;
    private var health : Int;
    private var scoreBonus : Int;
    private var items : Int;

    private var grazeCount : Int;

    public var onKilled : Enemy->Void;

    private override function added(s2d: h2d.Scene):Void {
        parent = null;
        sprite = new Sprite();
        s2d.add(sprite, 4);
        healthBar = new h2d.Graphics();
        s2d.add(healthBar, 4);
        healthBar.visible = false;
        time = 0.0;
        events = new Array();
        moveDestQueue = new List();
        bulletManagers = new Map();
        radius = 0.0;
        mask = 0;
        layer = Types.CollisionLayers.Enemy;
        children = new Array();
        grazeCount = 0;
        maxHealth = -1;
        health = -1;
        damageParticles = new Particles(s2d);
        damageParticles.onEnd = damageParticles.removeGroup.bind(damageParticles.getGroup("main"));
        damageSound = null;
        deathSound = null;
        player = scene.getEntity(Player);
        itemManager = scene.getEntity(ItemManager);
        dialogueManager = scene.getEntity(DialogueManager);
        onKilled = null;
    }

    private override function destroyed(s2d: h2d.Scene):Void {
        sprite.remove();
        healthBar.clear();
        healthBar.remove();
        events.resize(0);
        events = null;
        moveDestQueue.clear();
        if (parent != null) {
            parent.children.remove(this);
            parent = null;
        }
        for (m in bulletManagers) {
            if (m.destroyWithParent) m.destroy();
            else {
                switch (m.moveType) {
                    case Stop | Position(_): m.moveType = Fixed();
                    case Fixed(_): { }
                };
                m.parent = null;
            }
        }
        bulletManagers.clear();
        for (c in children) {
            c.onDestroyed = null;
            c.onKilled = null;
            c.parent = null;
            c.destroy();
        }
        children = null;
        grazeCount = 0;
        damageParticles.remove();
    }

    public function loadScript(path: String, ?params: Map<String, Any>) {
        final file = hxd.Res.load(path).toText();
        final parser = new Parser();
        parser.allowTypes = true;
        final ast = parser.parseString(file);
        final interp = new Interp();
        interp.variables["this"] = this;
        interp.variables["getTime"] = () -> time;
        interp.variables["getLocalX"] = get_lx;
        interp.variables["setLocalX"] = set_lx;
        interp.variables["getLocalY"] = get_ly;
        interp.variables["setLocalY"] = set_ly;
        interp.variables["getRelativeX"] = get_rx;
        interp.variables["setRelativeX"] = set_rx;
        interp.variables["getRelativeY"] = get_ry;
        interp.variables["setRelativeY"] = set_ry;
        interp.variables["getWorldX"] = () -> { return x; };
        interp.variables["setWorldX"] = (val: Float) -> { return x = val; };
        interp.variables["getWorldY"] = () -> { return y; };
        interp.variables["setWorldY"] = (val: Float) ->  { return y = val; };
        interp.variables["getRadius"] = () -> { return radius; };
        interp.variables["setRadius"] = (val: Float) ->  { return radius = val; };
        interp.variables["setMask"] = (val: Int) -> { return mask = val; };
        interp.variables["setLayer"] = (val: Int) -> { return layer = val; };
        interp.variables["player"] = player;
        interp.variables["addEvent"] = addEvent;
        interp.variables["setSprite"] = setSprite;
        interp.variables["playAnimation"] = playAnimation;
        interp.variables["playAnimationOverride"] = playAnimationOverride;
        interp.variables["destroy"] = destroy;
        interp.variables["moveToByTime"] = moveToByTime;
        interp.variables["moveToBySpeed"] = moveToBySpeed;
        interp.variables["enqueueMoveToByTime"] = enqueueMoveToByTime;
        interp.variables["enqueueMoveToBySpeed"] = enqueueMoveToBySpeed;
        interp.variables["nextMove"] = nextMove;
        interp.variables["spawnEnemy"] = spawnEnemy;
        interp.variables["stopMoving"] = stopMoving;
        interp.variables["setPreparedParam"] = setPreparedParam;
        interp.variables["clearPreparedParams"] = clearPreparedParams;
        interp.variables["createBulletManager"] = createBulletManager;
        interp.variables["destroyBulletManager"] = destroyBulletManager;
        interp.variables["freeBulletManager"] = freeBulletManager;
        interp.variables["loadBulletManagerBullets"] = loadBulletManagerBullets;
        interp.variables["setBulletManagerTile"] = setBulletManagerTile;
        interp.variables["setBulletManagerAutoDestroy"] = setBulletManagerAutoDestroy;
        interp.variables["setBulletManagerDestroyWithParent"] = setBulletManagerDestroyWithParent;
        interp.variables["setBulletManagerAimType"] = setBulletManagerAimType;
        interp.variables["setBulletManagerCount"] = setBulletManagerCount;
        interp.variables["setBulletManagerAngle"] = setBulletManagerAngle;
        interp.variables["setBulletManagerSpeed"] = setBulletManagerSpeed;
        interp.variables["setBulletManagerRadius"] = setBulletManagerRadius;
        interp.variables["setBulletManagerHitmask"] = setBulletManagerHitmask;
        interp.variables["setBulletManagerHitRadius"] = setBulletManagerHitRadius;
        interp.variables["setBulletManagerMoveType"] = setBulletManagerMoveType;
        interp.variables["bulletManagerShoot"] = bulletManagerShoot;
        interp.variables["playSound"] = playSound;
        interp.variables["playMusic"] = playMusic;
        interp.variables["stopMusic"] = stopMusic;
        interp.variables["fadeMusic"] = fadeMusic;
        interp.variables["loadBackground"] = loadBackground;
        interp.variables["setCameraPosition"] = setCameraPosition;
        interp.variables["setCameraVelocity"] = setCameraVelocity;
        interp.variables["setBackgroundScroll"] = setBackgroundScroll;
        interp.variables["setBackgroundScrollSpeed"] = setBackgroundScrollSpeed;
        interp.variables["setBackgroundColor"] = setBackgroundColor;
        interp.variables["spawnItem"] = spawnItem;
        interp.variables["startDialogue"] = startDialogue;
        interp.variables["showHealthbar"] = showHealthbar;
        interp.variables["hideHealthbar"] = hideHealthbar;
        interp.variables["loadDamageParticles"] = loadDamageParticles;
        interp.variables["loadDeathParticles"] = loadDeathParticles;
        interp.variables["setDamageSound"] = setDamageSound;
        interp.variables["setDeathSound"] = setDeathSound;
        interp.variables["LocalSpace"] = Types.Position.Local;
        interp.variables["RelativeSpace"] = Types.Position.Relative;
        interp.variables["WorldSpace"] = Types.Position.World;
        interp.variables["EntitySpace"] = Types.Position.Entity;
        interp.variables["MoveTypeStop"] = Types.BulletMoveType.Stop;
        interp.variables["MoveTypeFixed"] = Types.BulletMoveType.Fixed;
        interp.variables["MoveTypePosition"] = Types.BulletMoveType.Position;
        interp.variables["AimEntityFan"] = Types.BulletAim.EntityFan;
        interp.variables["AimFan"] = Types.BulletAim.Fan;
        interp.variables["AimEntityCircle"] = Types.BulletAim.EntityCircle;
        interp.variables["AimCircle"] = Types.BulletAim.Circle;
        interp.variables["AimRandomFan"] = Types.BulletAim.RandomFan;
        interp.variables["AimRandomCircle"] = Types.BulletAim.RandomCircle;
        interp.variables["AimTotallyRandomFan"] = Types.BulletAim.TotallyRandomFan;
        interp.variables["ItemPower"] = Types.Item.Power;
        interp.variables["ItemValue"] = Types.Item.Value;
        interp.variables["ItemJoke"] = Types.Item.Joke;
        interp.variables["Math"] = hxd.Math;
        interp.variables["Std"] = Std;
        if (params != null) for (k => v in params) interp.variables[k] = v;
        interp.execute(ast);
    }

    private override function update(delta: Float):Void {
        if (isPaused()) return;
        while (events.length > 0 && events[0].time <= time) events.shift().cb();
        if (events.length == 0 && moveDestQueue.isEmpty() && children.length == 0) {
            destroy();
            return;
        }
        if (!moveDestQueue.isEmpty()) {
            final moveDestination = moveDestQueue.first();
            final speed = moveDestination.speed * delta;
            var destX : Float;
            var destY : Float;
            var thisX : Float;
            var thisY : Float;
            switch (moveDestination.pos) {
                case Local(x, y): {
                    destX = x;
                    destY = y;
                    thisX = lx;
                    thisY = ly;
                }
                case Relative(x, y): {
                    destX = x;
                    destY = y;
                    thisX = rx;
                    thisY = ry;
                }
                case World(x, y): {
                    destX = x;
                    destY = y;
                    thisX = this.x;
                    thisY = this.y;
                }
                case Entity(ent, x, y): {
                    destX = ent.x + x;
                    destY = ent.y + y;
                    thisX = this.x;
                    thisY = this.y;
                }
            }
            var hInput = destX - thisX;
            var vInput = destY - thisY;
            var length = hInput * hInput + vInput * vInput;
            if (length > 0.0 && Math.sqrt(length) > speed) {
                length = Math.sqrt(length);
                hInput = hInput / length * speed;
                vInput = vInput / length * speed;
            } else {
                moveDestQueue.pop();
                if (moveDestination.cb != null) moveDestination.cb();
            }
            x += hInput;
            y += vInput;
        }
        time += delta;
    }

    private override function fixedUpdate(dt: Float):Void {
        if (isPaused()) return;
        if (player != null && player.isAlive()) {
            final distance = (x - player.x) * (x - player.x) + (y - player.y) * (y - player.y);
            if (mask & Types.CollisionLayers.Player == Types.CollisionLayers.Player &&
                    (distance == 0.0 || hxd.Math.sqrt(distance) <= Const.PLAYER_HITBOX_RADIUS + radius))
                player.applyDamage();
            else if (mask & Types.CollisionLayers.Graze == Types.CollisionLayers.Graze &&
                    distance < (Const.PLAYER_GRAZEBOX_RADIUS + radius) * (Const.PLAYER_GRAZEBOX_RADIUS + radius))
                player.graze(cast this);
            else grazeCount = 0;
        }
    }

    private override function render():Void {
        sprite.x = damageParticles.x = x;
        sprite.y = damageParticles.y = y;
            if (healthBar.visible) {
            healthBar.clear();
            healthBar.beginFill(0x000000, 0.0);
            healthBar.lineStyle(1, 0xFFFFFF, 0.7);
            final amount = -2.0 * hxd.Math.max(health, 0.0) / (maxHealth > 0.0 ? maxHealth : 1.0);
            healthBar.drawPieInner(x, y, healthbarRadius, healthbarRadius, 0.0, amount * hxd.Math.PI);
            healthBar.endFill();
        }
    }

    public function applyDamage(damage: Int):Void {
        if (health <= 0) return;
        health -= damage;
        if (health <= 0) {
            if (deathParticlesConfig != null) {
                final ps = new Particles(Main.instance.s2d);
                ps.x = x;
                ps.y = y;
                ps.load(deathParticlesConfig);
                ps.onEnd = ps.remove;
            }
            if (deathSound != null) AudioManager.instance.playSoundNoChannel(deathSound);
            player.addScore(scoreBonus);
            if (itemManager != null)
                for (_ in 0...items) {
                    final vel = hxd.Math.random(50.0) - 25.0;
                    final x = this.x + hxd.Math.random(3.0) - 1.5;
                    final choice = Std.random(2);
                    if (choice == 0) itemManager.spawn(Power(hxd.Math.random(0.1) + 0.03, vel), x, y);
                    else if (choice == 1) itemManager.spawn(Value((Std.random(10) + 1) * 10, vel), x, y);
                }
            if (onKilled != null) onKilled(this);
            new FloatingText(x, y - 2.0, scoreBonus);
            destroy();
        } else {
            if (damageParticlesConfig != null) damageParticles.load(damageParticlesConfig);
            if (damageSound != null) AudioManager.instance.playSoundNoChannel(damageSound);
        }
    }

    private function addEvent(time: Float, cb: Void->Void):Void {
        if (markedForDeletion || this.time > time) return;
        final event = { time: time, cb: cb };
        var i = 0;
        while (i < events.length && events[i].time < time) i++;
        events.insert(i, event);
    }

    @:keep inline private function setSprite(path: String):Void {
        sprite.load(path);
    }

    @:keep inline private function playAnimation(id: Int, start: Float = 0.0):Void {
        sprite.play(id, start);
    }

    @:keep inline private function playAnimationOverride(id: Int, start: Float = 0.0):Void {
        sprite.playOverride(id, start);
    }

    private function moveToByTime(pos: Types.Position, time: Float, ?cb: Void->Void):Void {
        var destX : Float;
        var destY : Float;
        var thisX : Float;
        var thisY : Float;
        switch (pos) {
            case Local(x, y): {
                destX = x;
                destY = y;
                thisX = lx;
                thisY = ly;
            }
            case Relative(x, y): {
                destX = x;
                destY = y;
                thisX = rx;
                thisY = ry;
            }
            case World(x, y): {
                destX = x;
                destY = y;
                thisX = this.x;
                thisY = this.y;
            }
            case Entity(ent, x, y): {
                destX = ent.x + x;
                destY = ent.y + y;
                thisX = this.x;
                thisY = this.y;
            }
        }
        var distance = (destX - thisX) * (destX - thisX) + (destY - thisY) * (destY - thisY);
        var speed : Float = 0.0;
        if (distance > 0.0) speed = Math.sqrt(distance) / time;
        moveDestQueue.pop();
        moveDestQueue.push({ pos: pos, speed: speed, cb: cb });
    }

    private function moveToBySpeed(pos: Types.Position, speed: Float, ?cb: Void->Void):Void {
        moveDestQueue.pop();
        moveDestQueue.push({ pos: pos, speed: speed, cb: cb });
    }

    private function enqueueMoveToByTime(pos: Types.Position, time: Float, ?cb: Void->Void):Void {
        var destX : Float;
        var destY : Float;
        var thisX : Float;
        var thisY : Float;
        switch (pos) {
            case Local(x, y): {
                destX = x;
                destY = y;
                thisX = lx;
                thisY = ly;
            }
            case Relative(x, y): {
                destX = x;
                destY = y;
                thisX = rx;
                thisY = ry;
            }
            case World(x, y): {
                destX = x;
                destY = y;
                thisX = this.x;
                thisY = this.y;
            }
            case Entity(ent, x, y): {
                destX = ent.x + x;
                destY = ent.y + y;
                thisX = this.x;
                thisY = this.y;
            }
        }
        var distance = (destX - thisX) * (destX - thisX) + (destY - thisY) * (destY - thisY);
        var speed : Float = 0.0;
        if (distance > 0.0) speed = Math.sqrt(distance) / time;
        moveDestQueue.add({ pos: pos, speed: speed, cb: cb });
    }

    private function enqueueMoveToBySpeed(pos: Types.Position, speed: Float, ?cb: Void->Void):Void {
        moveDestQueue.add({ pos: pos, speed: speed, cb: cb });
    }

    private function nextMove():Void {
        moveDestQueue.pop();
    }

    private function stopMoving():Void {
        moveDestQueue.clear();
    }

    private function spawnEnemy(pos: Types.Position, script: String, health: Int, scoreBonus: Int, items: Int,
                ?destroyedCb: Entity->Void, killedCb: Enemy->Void):Void {
        var newX : Float;
        var newY : Float;
        switch (pos) {
            case Local(x, y): {
                newX = this.x + x;
                newY = this.y + y;
            }
            case Relative(x, y): {
                newX = Const.ENEMY_BASE_X + x;
                newY = Const.ENEMY_BASE_Y + y;
            }
            case World(x, y): {
                newX = x;
                newY = y;
            }
            case Entity(ent, x, y): {
                newX = ent.x + x;
                newY = ent.y + y;
            }
        }
        final enemy = scene.spawnEntity(newX, newY, Enemy);
        enemy.maxHealth = enemy.health = health;
        enemy.scoreBonus = scoreBonus;
        enemy.items = items;
        enemy.parent = this;
        enemy.onDestroyed = destroyedCb;
        enemy.onKilled = killedCb;
        children.push(enemy);
        enemy.loadScript(script, preparedParams);
    }

    private function setPreparedParam(k: String, v: Any):Void {
        if (preparedParams == null) preparedParams = [ k => v ];
        else preparedParams[k] = v;
    }

    private function clearPreparedParams():Void {
        if (preparedParams == null) throw "Prepared params do not exist!";
        preparedParams.clear();
        preparedParams = null;
    }

    private function createBulletManager(idx: Int):Void {
        if (bulletManagers.exists(idx)) bulletManagers[idx].parent = null;
        final mgr = scene.spawnEntity(x, y, BulletManager);
        mgr.parent = this;
        bulletManagers[idx] = mgr;
        mgr.player = player;
    }

    private function destroyBulletManager(idx: Int):Void {
        if (!bulletManagers.exists(idx)) throw 'Bullet manager $idx does not exist!';
        bulletManagers[idx].destroy();
        bulletManagers.remove(idx);
    }

    private function freeBulletManager(idx: Int):Void {
        if (!bulletManagers.exists(idx)) throw 'Bullet manager $idx does not exist!';
        bulletManagers[idx].parent = null;
        bulletManagers.remove(idx);
    }

    @:keep inline private function loadBulletManagerBullets(idx: Int, path: String):Void {
        if (!bulletManagers.exists(idx)) throw 'Bullet manager $idx does not exist!';
        bulletManagers[idx].load(path);
    }

    @:keep inline private function setBulletManagerTile(idx: Int, tile: Int):Void {
        if (!bulletManagers.exists(idx)) throw 'Bullet manager $idx does not exist!';
        bulletManagers[idx].bulletType = tile;
    }

    @:keep inline private function setBulletManagerAutoDestroy(idx: Int, ad: Bool):Void {
        if (!bulletManagers.exists(idx)) throw 'Bullet manager $idx does not exist!';
        bulletManagers[idx].autoDestroy = ad;
    }

    @:keep inline private function setBulletManagerDestroyWithParent(idx: Int, dwp: Bool):Void {
        if (!bulletManagers.exists(idx)) throw 'Bullet manager $idx does not exist!';
        bulletManagers[idx].destroyWithParent = dwp;
    }

    @:keep inline private function setBulletManagerAimType(idx: Int, aim: Types.BulletAim):Void {
        if (!bulletManagers.exists(idx)) throw 'Bullet manager $idx does not exist!';
        bulletManagers[idx].aim = aim;
    }

    @:keep inline private function setBulletManagerCount(idx: Int, countA: Int, countB: Int):Void {
        if (!bulletManagers.exists(idx)) throw 'Bullet manager $idx does not exist!';
        bulletManagers[idx].countA = countA;
        bulletManagers[idx].countB = countB;
    }

    @:keep inline private function setBulletManagerAngle(idx: Int, angleA: Float, angleB: Float):Void {
        if (!bulletManagers.exists(idx)) throw 'Bullet manager $idx does not exist!';
        bulletManagers[idx].angleA = angleA;
        bulletManagers[idx].angleB = angleB;
    }

    @:keep inline private function setBulletManagerSpeed(idx: Int, speedA: Float, speedB: Float):Void {
        if (!bulletManagers.exists(idx)) throw 'Bullet manager $idx does not exist!';
        bulletManagers[idx].speedA = speedA;
        bulletManagers[idx].speedB = speedB;
    }

    @:keep inline private function setBulletManagerRadius(idx: Int, radiusA: Float, radiusB: Float):Void {
        if (!bulletManagers.exists(idx)) throw 'Bullet manager $idx does not exist!';
        bulletManagers[idx].radiusA = radiusA;
        bulletManagers[idx].radiusB = radiusB;
    }

    @:keep inline private function setBulletManagerMoveType(idx: Int, moveType: Types.BulletMoveType):Void {
        if (!bulletManagers.exists(idx)) throw 'Bullet manager $idx does not exist!';
        bulletManagers[idx].moveType = moveType;
    }

    @:keep inline private function setBulletManagerHitmask(idx: Int, mask: Int):Void {
        if (!bulletManagers.exists(idx)) throw 'Bullet manager $idx does not exist!';
        bulletManagers[idx].hitmask = mask;
    }

    @:keep inline private function setBulletManagerHitRadius(idx: Int, radius: Float):Void {
        if (!bulletManagers.exists(idx)) throw 'Bullet manager $idx does not exist!';
        bulletManagers[idx].hitRadius = radius;
    }

    @:keep inline private function bulletManagerShoot(idx: Int):Void {
        if (!bulletManagers.exists(idx)) throw 'Bullet manager $idx does not exist!';
        bulletManagers[idx].shoot();
    }

    @:keep inline private function playSound(path: String, volume: Float = 1.0):Void {
        AudioManager.instance.playSoundNoChannel(path, volume);
    }

    @:keep inline private function playMusic(path: String, loop: Bool = true, volume: Float = 1.0):Void {
        AudioManager.instance.playMusic(path, loop, volume);
    }

    @:keep inline private function fadeMusic(to: Float, time: Float):Void {
        AudioManager.instance.fadeMusic(to, time);
    }

    @:keep inline private function stopMusic(fadeOutTime: Float = 0.0):Void {
        AudioManager.instance.stopMusic(fadeOutTime);
    }

    @:keep inline private function loadBackground(path: String):Void {
        if (!Std.isOfType(scene, Playfield) || cast (scene, Playfield).background == null) throw 'There is no background on this scene!';
        cast (scene, Playfield).background.load(path);
    }

    @:keep inline private function setCameraPosition(?x: Float, ?y: Float, ?time: Float):Void {
        if (!Std.isOfType(scene, Playfield) || cast (scene, Playfield).background == null) throw 'There is no background on this scene!';
        cast (scene, Playfield).background.setCameraPos(x, y, time);
    }

    @:keep inline private function setCameraVelocity(?x: Float, ?y: Float, ?time: Float):Void {
        if (!Std.isOfType(scene, Playfield) || cast (scene, Playfield).background == null) throw 'There is no background on this scene!';
        cast (scene, Playfield).background.setCameraVel(x, y, time);
    }

    @:keep inline private function setBackgroundScroll(idx: Int, ?h: Float, ?v: Float, ?time: Float):Void {
        if (!Std.isOfType(scene, Playfield) || cast (scene, Playfield).background == null) throw 'There is no background on this scene!';
        cast (scene, Playfield).background.setLayerScroll(idx, h, v, time);
    }

    @:keep inline private function setBackgroundScrollSpeed(idx: Int, ?h: Float, ?v: Float, ?time: Float):Void {
        if (!Std.isOfType(scene, Playfield) || cast (scene, Playfield).background == null) throw 'There is no background on this scene!';
        cast (scene, Playfield).background.setLayerScrollSpeed(idx, h, v, time);
    }

    @:keep inline private function setBackgroundColor(idx: Int, ?r: Float, ?g: Float, ?b: Float, ?a: Float, ?time: Float):Void {
        if (!Std.isOfType(scene, Playfield) || cast (scene, Playfield).background == null) throw 'There is no background on this scene!';
        cast (scene, Playfield).background.setLayerColor(idx, r, g, b, a, time);
    }

    private function spawnItem(type: Types.Item, at: Types.Position):Void {
        if (itemManager == null) throw 'There is no item manager on this scene!';
        var realX : Float;
        var realY : Float;
        switch (at) {
            case Local(x, y): {
                realX = x + (parent != null ? parent.x : Const.ENEMY_BASE_X);
                realY = y + (parent != null ? parent.y : Const.ENEMY_BASE_Y);
            }
            case Relative(x, y): {
                realX = x + Const.ENEMY_BASE_X;
                realY = y + Const.ENEMY_BASE_Y;
            }
            case World(x, y): {
                realX = x;
                realY = y;
            }
            case Entity(ent, x, y): {
                realX = ent.x + x;
                realY = ent.y + y;
            }
        }
        itemManager.spawn(type, realX, realY);
    }

    private function startDialogue(path: String, ?startedCb: Void->Void, ?endedCb: Void->Void, ?hiddenCb: Void->Void):Void {
        if (dialogueManager == null) throw 'There is no dialogue manager on this scene!';
        dialogueManager.start(path, startedCb, endedCb, hiddenCb);
    }

    private function showHealthbar(radius: Float):Void {
        healthbarRadius = radius;
        healthBar.visible = true;
    }

    private function loadDamageParticles(path: String):Void {
        damageParticlesConfig = haxe.Json.parse(hxd.Res.load(path).toText());
    }

    private function loadDeathParticles(path: String):Void {
        deathParticlesConfig = haxe.Json.parse(hxd.Res.load(path).toText());
    }

    private function hideHealthbar():Void {
        healthBar.clear();
        healthBar.visible = false;
    }

    @:keep inline private function setDamageSound(path: String) {
        damageSound = path;
    }

    @:keep inline private function setDeathSound(path: String) {
        deathSound = path;
    }

    inline private function isPaused():Bool {
        if (parent != null) return paused || parent.isPaused();
        return paused;
    }
}