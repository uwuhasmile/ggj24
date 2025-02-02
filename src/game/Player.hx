package game;

import h2d.Particles;
import h3d.Vector4;
import h2d.Bitmap;
import heaps.Sprite;

enum abstract PlayerAnimation(Int) from Int to Int {
    final Forward = 0;
    final Left = 1;
    final Right = 2;
    final Focus = 3;
}

class Player extends Entity {
    public var velX : Float;
    public var velY : Float;

    private var sprite : Sprite;
    private var hud : HUD;
    private var grazeParticles : Particles;
    private var grazeParticleSettings : Dynamic;
    private var hitboxSprite : Bitmap;
    
    private var invincibility : Float;
    

    private var focusing : Bool;

    public var damagedTime(default, null) : Float;
    public var timeBeforeDeath(default, null) : Float;

    private var shootTimers : List<{ time : Float }>;

    public var score(default, null) : Int;
    public var lives(default, null) : Int;
    public var availableBullets(default, null) : Int;
    public var bulletLevel(default, null) : Int;
    public var power(default, null) : Float;
    public var grazePoints(default, null) : Int;
    
    public var canShoot : Bool;
    private var inputShouldBeEnabled : Bool;
    private var inputEnabled : Bool;

    #if debug
    private var invincible : Bool;
    #end

    private override function added(s2d: h2d.Scene):Void {
        sprite = new Sprite();
        s2d.add(sprite, 3);
        sprite.load("sprites/game/sprPlayer.xml");
        sprite.addShader(new shaders.Blink(0, 0.17, Vector4.fromColor(0x00000000), 1.0));
        hitboxSprite = new Bitmap(hxd.Res.sprites.game.sprPlayerHitbox.toTile().center(), s2d);
        grazeParticles = new Particles(s2d);
        grazeParticles.onEnd = grazeParticles.removeGroup.bind(grazeParticles.getGroup("main"));
        grazeParticleSettings = haxe.Json.parse(hxd.Res.particles.ptcPlayerGraze_json.entry.getText());
        velX = 0.0;
        velY = 0.0;
        focusing = false;
        availableBullets = 6;
        bulletLevel = 0;
        power = 0.0;
        hud = new HUD();
        Main.instance.hud.add(hud, 0);
        damagedTime = 0.0;
        timeBeforeDeath = -1.0;
        canShoot = false;
        shootTimers = new List();
    }

    private override function destroyed(s2d: h2d.Scene) {
        sprite.remove();
        sprite = null;
        hitboxSprite.remove();
        hitboxSprite = null;
        grazeParticles.remove();
        grazeParticles = null;
        hud.remove();
        shootTimers.clear();
        shootTimers = null;
    }

    private override function preUpdate() {
        final input = InputManager.instance;
        if (!inputEnabled || timeBeforeDeath > 0.0) {
            velX = 0.0;
            velY = 0.0;
            return;
        }
        if (canShoot && input.getActionResult(Types.InputActions.Shoot)) shoot();
        focusing = input.getActionResult(Types.InputActions.Focus);
        final hInput = input.getActionValue(Types.InputActions.MoveRight) - input.getActionValue(Types.InputActions.MoveLeft);
        final vInput = input.getActionValue(Types.InputActions.MoveDown) - input.getActionValue(Types.InputActions.MoveUp);
        var length = (hInput * hInput + vInput * vInput);
        if (length > 0.0) { 
            length = Math.sqrt(length);
            velX = hInput / length * (focusing ? Const.PLAYER_FOCUS_MOVEMENT_SPEED : Const.PLAYER_DEFAULT_MOVEMENT_SPEED);
            velY = vInput / length * (focusing ? Const.PLAYER_FOCUS_MOVEMENT_SPEED : Const.PLAYER_DEFAULT_MOVEMENT_SPEED);
        } else velX = velY = 0.0;
    }

    private override function update(delta: Float) {
        if (!inputEnabled)
            if (inputShouldBeEnabled) {
                inputEnabled = true;
                inputShouldBeEnabled = false;
            }
        if (shootTimers.first() != null) {
            if (shootTimers.first().time <= 0.0) {
                shootBullet(x, y - 16.0, bulletLevel);
                shootTimers.pop();
            } else shootTimers.first().time -= delta;
        }
        if (timeBeforeDeath > 0.0) {
            timeBeforeDeath = hxd.Math.max(timeBeforeDeath - delta, 0.0);
            return;
        } else if (timeBeforeDeath == 0.0) {
            destroy();
            return;
        }
        if (damagedTime > 0.0) {
            grazePoints = 0;
            damagedTime -= delta;
        } else if (damagedTime < 0.0) damagedTime = 0.0;
        if (invincibility > 0.0) invincibility = hxd.Math.max(invincibility - delta, 0.0);
        x += velX * delta;
        x = hxd.Math.clamp(x, Const.PLAYFIELD_PLAYABLE_LEFT + 16.0, Const.PLAYFIELD_PLAYABLE_RIGHT - 16.0);
        y += velY * delta;
        y = hxd.Math.clamp(y, Const.PLAYFIELD_PLAYABLE_TOP + 16.0, Const.PLAYFIELD_PLAYABLE_BOTTOM - 16.0);
    }

    private override function render():Void {
        sprite.getShader(shaders.Blink).enabled = (invincibility > 0.0 ? 1 : 0);
        if (focusing) sprite.play(PlayerAnimation.Focus);
        else sprite.play(velX < 0.0 ? PlayerAnimation.Left : (velX > 0.0 ? PlayerAnimation.Right : PlayerAnimation.Forward));
        hitboxSprite.visible = focusing;
        sprite.x = hitboxSprite.x = grazeParticles.x = x;
        sprite.y = hitboxSprite.y = grazeParticles.y = y;
    }

    public function disableInput():Void {
        inputEnabled = false;
    }

    public function enableInput():Void {
        inputShouldBeEnabled = true;
    }

    public function levelStarted():Void {
        invincibility = 2.0;
        x = Const.PLAYER_START_X;
        y = Const.PLAYER_START_Y;
        score = 0;
        lives = Const.PLAYER_START_HP;
        grazePoints = 0;
        enableInput();
        canShoot = true;
        hud.update(this);
    }

    private function shoot():Void {
        if (!canShoot || availableBullets <= 0 || !shootTimers.isEmpty()) return;
        final level = Std.int(power);
        switch (level) {
            case 0: shootBullet(x, y - 16.0, bulletLevel);
            case 1: for (i in 0...2) shootTimers.add({ time: 0.14 * (i > 0 ? 1 : 0) });
            case 2: for (i in 0...3) shootTimers.add({ time: 0.12 * (i > 0 ? 1 : 0) });
            case 3: {
                for (i in 0...3) shootTimers.add({ time: 0.09 * (i > 0 ? 1 : 0) });
                shootBullet(x - 20.0, y - 6.0, 0);
                shootBullet(x + 20.0, y - 6.0, 0);
            }
            case 4: {
                for (i in 0...4) shootTimers.add({ time: 0.09 * (i > 0 ? 1 : 0) });
                shootBullet(x - 20.0, y - 6.0, 0);
                shootBullet(x + 20.0, y - 6.0, 0);
            }
            case 5: {
                for (i in 0...3) shootTimers.add({ time: 0.08 * (i > 0 ? 1 : 0) });
                shootBullet(x - 20.0, y - 6.0, 0);
                shootBullet(x + 20.0, y - 6.0, 0);
                shootBullet(x - 20.0, y - 9.0, bulletLevel > 0 ? 1 : 0);
                shootBullet(x + 20.0, y - 9.0, bulletLevel > 0 ? 1 : 0);
            }
        }
        availableBullets--;
        if (availableBullets <= 0) bulletLevel = 0;
        hud.update(this);
    }

    private function shootBullet(x: Float, y: Float, level: Int):Void {
        AudioManager.instance.playSound(4, "sounds/sndPlayerShoot.wav");
        final bullet = scene.spawnEntity(x, y, PlayerBullet);
        bullet.setLevel(level);
    }

    public function addPower(power: Float):Void {
        if (this.power >= 5.0) return;
        final intPower = Std.int(this.power);
        this.power = hxd.Math.min(this.power + power, 5.0);
        if (Std.int(this.power) > intPower) {
            if (hud != null) hud.powerLevelUp();
            AudioManager.instance.playSound(15, "sounds/sndLevelUp.wav");
        }
        hud.update(this);
    }

    public function addBullet():Void {
        availableBullets++;
        if (bulletLevel < 3 && availableBullets == 8 * (bulletLevel + 1) * 2) {
            availableBullets = Std.int(availableBullets / 2);
            bulletLevel++;
            if (hud != null) hud.bulletLevelUp();
            AudioManager.instance.playSound(15, "sounds/sndLevelUp.wav");
        }
        hud.update(this);
    }

    public function addScore(score: Int):Void {
        this.score += score;
        hud.update(this);
    }

    public function graze(by: { grazeCount : Int }):Void {
        if (damagedTime > 0.0 || timeBeforeDeath >= 0.0) return;
        if (by.grazeCount < 1) {
            by.grazeCount++;
            grazeParticles.load(grazeParticleSettings);
            if (!AudioManager.instance.isPlaying(1)) AudioManager.instance.playSound(1, "sounds/sndPlayerGraze.wav");
            grazePoints++;
            hud.update(this);
        }
    }

    public function applyDamage():Void {
        #if debug
        if (invincible) return;
        #end
        if (invincibility > 0.0 || timeBeforeDeath >= 0.0) return;
        AudioManager.instance.playSound(0, "sounds/sndPlayerDamage.wav");
        lives--;
        final oldX = x;
        final oldY = y;
        x = Const.PLAYER_START_X;
        y = Const.PLAYER_START_Y;
        if (lives > 0) {
            invincibility = 2.0;
            damagedTime = 0.08;
            grazePoints = 0;
        } else {
            sprite.visible = false;
            timeBeforeDeath = 0.3;
        }
        final im = scene.getEntity(ItemManager);
        if (im != null) {
            for (i in -2...3) {
                if (power > 0.0) im.spawn(Power(power * 0.2, i * 15.0), oldX + i * 6.0, oldY);
                if (score > 10) im.spawn(Value(Std.int(score / 10), i * 9.0), oldX + i * 9.0, oldY - 4.0);
            }
        }
        power = 0.0;
        score = Std.int(score / 2);
        hud.update(this);
    }

    #if debug
    private override function event(event: hxd.Event):Void {
        if (event.kind == EKeyDown) {
            switch (event.keyCode) {
                case hxd.Key.I: {
                    invincible = !invincible;
                    AudioManager.instance.playSoundNoChannel("sounds/sndTriangle02.wav");
                }
                case hxd.Key.QWERTY_EQUALS: Main.timeMultiplier += 1.0;
                case hxd.Key.QWERTY_MINUS: Main.timeMultiplier -= 1.0;
            }
            
        }
    }
    #end

    @:keep inline public function isAlive():Bool {
        return !markedForDeletion && timeBeforeDeath < 0.0 && lives > 0;
    }
}