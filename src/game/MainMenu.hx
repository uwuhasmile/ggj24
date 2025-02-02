package game;

import h2d.Text;
import heaps.Background;

class MainMenu extends Scene {
    private var background : Background;
    private var border : h2d.Bitmap;
    private var logo : h2d.Bitmap;
    private var score : h2d.Text;
    private var press : h2d.Text;
    private var volume : h2d.Text;
    private var timer : Timer;
    private var enabled : Bool;

    private override function entered(s2d: h2d.Scene):Void {
        enabled = true;
        AudioManager.instance.stopAllSounds();
        AudioManager.instance.stopMusic();
        background = new Background(s2d);
        background.load("backgrounds/bgMainMenu.xml");
        border = new h2d.Bitmap(hxd.Res.sprites.hud.sprStorytellerBorders.toTile(), s2d);
        logo = new h2d.Bitmap(hxd.Res.sprites.sprLogo.toTile().center(), s2d);
        logo.x = 160.0;
        logo.y = 40.0;
        final font = hxd.res.DefaultFont.get();
        press = new h2d.Text(font, s2d);
        score = new h2d.Text(font, s2d);
        press.textAlign = score.textAlign = Center;
        press.x = score.x = 160.0;
        press.text = "Enter/Z to start game";
        if (Main.instance.save.firstGame) {
            score.text = "Controls:\nArrows - move\nZ - shoot\nShift - focus";
            score.setScale(0.8);
            score.y = 112.0;
            press.y = 160.0;
        } else {
            score.setScale(1.3);
            score.text = 'Highest score: ${Main.instance.save.bestScore}';
            score.y = 120.0;
            press.y = 145.0;
            press.text += "\nor Esc to reset the save";
        }
        volume = new h2d.Text(font, s2d);
        volume.x = 3.0;
        volume.y = 130.0;
        volume.setScale(0.6);
        volume.text = "S/W to change sound volume\nA/D to change music volume";
        timer = spawnEntity(0.0, 0.0, Timer);
        timer.onTimeout = Main.instance.changeScene.bind(Playfield, [ "stages/stage01.hscript" ]);
    }

    private override function exited(s2d: h2d.Scene):Void {
        background.remove();
        border.remove();
        score.remove();
        logo.remove();
        volume.remove();
        if (press != null) press.remove();
    }

    private override function event(event: hxd.Event):Void {
        if (!enabled || event.kind != EKeyDown) return;
        switch (event.keyCode) {
            case hxd.Key.ENTER | hxd.Key.Z: {
                enabled = false;
                press.remove();
                AudioManager.instance.playSound(15, "sounds/sndPickupItem.wav");
                timer.start(0.6);
            }
            case hxd.Key.ESCAPE: {
                Main.instance.save.bestScore = 0;
                Main.instance.save.firstGame = true;
                hxd.Save.delete("lhSave");
                Main.instance.changeScene(MainMenu);
            }
            case hxd.Key.S: {
                var volume = Std.int(Main.instance.save.soundVolume * 10) / 10 - 0.2;
                if (volume < 0.0) volume = 0.0;
                else if (volume > 1.0) volume = 1.0;
                AudioManager.instance.setSoundVolume(Main.instance.save.soundVolume = volume);
                AudioManager.instance.playSound(15, "sounds/sndPickupItem.wav");
                hxd.Save.save(Main.instance.save, "lhSave");
            }
            case hxd.Key.W: {
                var volume = Std.int(Main.instance.save.soundVolume * 10) / 10 + 0.2;
                if (volume < 0.0) volume = 0.0;
                else if (volume > 1.0) volume = 1.0;
                AudioManager.instance.setSoundVolume(Main.instance.save.soundVolume = volume);
                AudioManager.instance.playSound(15, "sounds/sndPickupItem.wav");
                hxd.Save.save(Main.instance.save, "lhSave");
            }
            case hxd.Key.A: {
                var volume = Std.int(Main.instance.save.musicVolume * 10) / 10 - 0.2;
                if (volume < 0.0) volume = 0.0;
                else if (volume > 1.0) volume = 1.0;
                AudioManager.instance.setMusicVolume(Main.instance.save.musicVolume = volume);
                AudioManager.instance.playMusic("sounds/sndPickupItem.wav", false);
                hxd.Save.save(Main.instance.save, "lhSave");
            }
            case hxd.Key.D: {
                var volume = Std.int(Main.instance.save.musicVolume * 10) / 10 + 0.2;
                if (volume < 0.0) volume = 0.0;
                else if (volume > 1.0) volume = 1.0;
                AudioManager.instance.setMusicVolume(Main.instance.save.musicVolume = volume);
                AudioManager.instance.playMusic("sounds/sndPickupItem.wav", false);
                hxd.Save.save(Main.instance.save, "lhSave");
            }
        }
    }
}