package game;

class Ending extends Scene {
    private var logo : h2d.Bitmap;
    private var text : h2d.Text;
    private var scoreText : h2d.Text;
    private var press : h2d.Text;
    private var timer : Timer;
    private var enabled : Bool;

    private override function entered(s2d: h2d.Scene):Void {
        enabled = true;
        logo = new h2d.Bitmap(hxd.Res.sprites.sprLogo.toTile().center(), s2d);
        logo.x = 160.0;
        logo.y = 40.0;
        final font = hxd.res.DefaultFont.get();
        text = new h2d.Text(font, s2d);
        scoreText = new h2d.Text(font, s2d);
        press = new h2d.Text(font, s2d);
        text.textAlign = scoreText.textAlign = press.textAlign = Center;
        text.text = "By ARFILISH. Purr :3\nMade in Ukraine.";
        var score = 0;
        if (Scenario.instance != null) {
            score = Scenario.instance.score;
            Scenario.instance.finish();
        }
        scoreText.text = 'Final score: $score';
        text.x = scoreText.x = press.x = 160.0;
        text.y = 75.0;
        scoreText.y = 130.0;
        scoreText.setScale(1.5);
        press.setScale(0.76);
        press.y = 170.0;
        press.text = "Enter/Z/Esc to return to main menu";
        timer = spawnEntity(0.0, 0.0, Timer);
        timer.onTimeout = Main.instance.changeScene.bind(MainMenu, []);
    }

    private override function exited(_) {
        logo.remove();
        text.remove();
        scoreText.remove();
        if (press != null) press.remove();
    }

    private override function event(event: hxd.Event) {
        if (event.kind != EKeyDown) return;
        switch (event.keyCode) {
            case hxd.Key.ESCAPE | hxd.Key.ENTER | hxd.Key.Z: {
                enabled = false;
                press.remove();
                timer.start(0.4);
                AudioManager.instance.playSound(15, "sounds/sndPickupItem.wav");
            }
        }
    }
}