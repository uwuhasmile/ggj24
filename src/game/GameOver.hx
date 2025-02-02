package game;

import heaps.Background;

class GameOver extends Scene {
    private var background : Background;
    private var gameOver : h2d.Text;
    private var press : h2d.Text;
    private var score : LevelScore;
    private var enabled : Bool;

    private override function entered(s2d: h2d.Scene):Void {
        enabled = false;
        AudioManager.instance.stopAllSounds();
        AudioManager.instance.stopMusic();
        background = new Background(s2d);
        background.load("backgrounds/bgGameOver.xml");
        final font = hxd.res.DefaultFont.get();
        gameOver = new h2d.Text(font, Main.instance.hud);
        gameOver.textAlign = Center;
        gameOver.x = 160.0;
        gameOver.y = 2.0;
        gameOver.textColor = 0xFFBC65;
        gameOver.setScale(2.0);
        gameOver.text = "GAME OVER";
        press = new h2d.Text(font, Main.instance.hud);
        press.textAlign = Center;
        press.setScale(0.75);
        press.x = 160.0;
        press.y = 150.0;
        press.text = "Press R to retry\nor Esc/Enter/Z to return to menu";
        score = new LevelScore(Main.instance.hud);
        score.data.textAlign = score.result.textAlign = Left;
        score.newRecord.x = 77.0;
        score.newRecord.y = -4.0;
        score.newRecord.rotation = hxd.Math.degToRad(25.0);
        score.setShowTween(0.2, -120.0, 40.0, 1.0, 12.0, null, null, 0.3, -120.0, 100.0, 1.0, 20.0, null, null, null, () -> enabled = true);
        final data = Scenario.instance != null ? Scenario.instance.calculateScore() : { raw : 0, graze : 0, deaths : 0, score : 0, total : 0, newRecord : false };
        score.loadData(data);
        score.show();
    }

    private override function exited(s2d: h2d.Scene):Void {
        background.remove();
        background = null;
        score.remove();
        gameOver.remove();
        if (press != null) press.remove();
    }

    private override function event(event: hxd.Event):Void {
        if (!enabled || event.kind != EKeyDown) return;
        switch (event.keyCode) {
            case hxd.Key.R: {
                enabled = false;
                press.remove();
                score.setHideTween(2.0, null, null, null, null, null, 0.0, 0.3, null, null, null, null, null, 0.0, null, Main.instance.changeScene.bind(Playfield, null));
                score.hide();
                AudioManager.instance.playSound(15, "sounds/sndPickupItem.wav");
            }
            case hxd.Key.ESCAPE | hxd.Key.ENTER | hxd.Key.Z: {
                enabled = false;
                press.remove();
                score.setHideTween(2.0, null, null, null, null, null, 0.0, 0.3, null, null, null, null, null, 0.0, null, Main.instance.changeScene.bind(MainMenu, null));
                score.hide();
                if (Scenario.instance != null) {
                    Scenario.instance.updateScore();
                    Scenario.instance.finish();
                }
                AudioManager.instance.playSound(15, "sounds/sndPickupItem.wav");
            }
        }
    }
}