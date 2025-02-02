package game;

import hxd.res.DefaultFont;
import h2d.Object;
import h2d.HtmlText;
import h2d.Font;

class HUD extends Object {
    private var font : Font;

    private var score : HtmlText;
    private var lives : HtmlText;
    private var power : HtmlText;
    private var graze : HtmlText;
    private var bullets : HtmlText;

    private var powerLevelUpText : HUDFloatingText;
    private var bulletLevelUpText : HUDFloatingText;

    public function new(?p: h2d.Object):Void {
        super(p);
        new h2d.Bitmap(hxd.Res.sprites.hud.sprHud.toTile(), this);
        font = DefaultFont.get();
        score = new HtmlText(font, this);
        lives = new HtmlText(font, this);
        power = new HtmlText(font, this);
        graze = new HtmlText(font, this);
        bullets = new HtmlText(font, this);
        score.textAlign = lives.textAlign = graze.textAlign = bullets.textAlign = h2d.Text.Align.Left;
        score.x = lives.x = power.x = graze.x = bullets.x = 220.0;
        score.y = 10.0;
        lives.y = 30.0;
        power.y = 50.0;
        final lifeTile = hxd.Res.sprites.hud.sprIconLife.toTile();
        lifeTile.dy = 2.0;
        lives.loadImage = (_) -> { return lifeTile; }
        graze.y = 70.0;
        bullets.y = 110.0;
    }

    public function update(p: Player):Void {
        score.text = 'SCORE: <font color="#fffacf">${p.score}</font>';
        var text = 'LIVES: ';
        for (_ in 0...p.lives) text += '<img src="sprites/hud/sprIconLife.png" />';
        lives.text = text;
        graze.text = 'GRAZE: ${p.grazePoints}';
        final bulletTiles = hxd.Res.sprites.game.sprPlayerBullets_png.toTile().grid(16, 0.0, 3.0);
        bullets.loadImage = (_) -> { return bulletTiles[0][p.bulletLevel]; }
        bullets.text = '<img src="_" />: ${p.availableBullets}';
        power.text = 'POWER: ${Std.int(p.power * 100) / 100}';
    }

    public function powerLevelUp():Void {
        if (powerLevelUpText != null) powerLevelUpText.remove();
        powerLevelUpText = new HUDFloatingText(103.0, 30.0, "POWER LEVEL UP!", this);
    }

    public function bulletLevelUp():Void {
        if (bulletLevelUpText != null) powerLevelUpText.remove();
        bulletLevelUpText = new HUDFloatingText(103.0, 50.0, "BULLET LEVEL UP!", this);
    }
}