package game;

class LevelEnd extends Entity {
    private var cleared : h2d.Text;
    private var press : h2d.Text;
    private var score : LevelScore;
    private var background : h2d.Bitmap;

    public var destroyAfterHide : Bool;

    private var inputEnabled : Bool;

    public var startedShowingCb : Void->Void;
    public var showedCb : Void->Void;
    public var startedHidingCb : Void->Void;
    public var hiddenCb : Void->Void;

    private override function added(_):Void {
        score = new LevelScore();
        score.data.textAlign = score.result.textAlign = Left;
        score.data.textColor = score.result.textColor = 0x494949;
        score.newRecord.x = 90.0;
        score.newRecord.y = -6.0;
        score.newRecord.rotation = hxd.Math.degToRad(25.0);
        score.setShowTween(0.5, 12.0, 70.0, 0.0, null, 40.0, 1.0, 0.5, 20.0, 140.0, 0.0, null, 100.0, 1.0, startedShowing, finishedShowing);
        score.setHideTween(0.5, 12.0, 40.0, 1.0, null, 0.0, 0.0, 0.5, 20.0, 100.0, 1.0, null, 40.0, 0.0, startedHiding, finishedHiding);
        Main.instance.hud.add(score, 4);
        background = new h2d.Bitmap(hxd.Res.backgrounds.bgStageClear.toTile());
        Main.instance.hud.add(background, 3);
        final font = hxd.res.DefaultFont.get();
        cleared = new h2d.Text(font, background);
        cleared.textAlign = Center;
        cleared.x = 160.0;
        cleared.y = 2.0;
        cleared.textColor = 0xFFBC65;
        cleared.setScale(2.0);
        cleared.text = "STAGE CLEAR";
        press = new h2d.Text(font, background);
        press.textAlign = Left;
        press.setScale(0.75);
        press.x = 30.0;
        press.y = 155.0;
        press.text = "Press Enter/Z to continue";
        press.textColor = 0x494949;
        score.visible = false;
        background.visible = false;
        destroyAfterHide = false;
        inputEnabled = false;
        dontDestroy();
    }

    private override function destroyed(_):Void {
        score.remove();
        background.remove();
    }

    private override function render():Void {
        background.alpha = score.result.alpha;
    }

    private override function event(event: hxd.Event):Void {
        if (!inputEnabled || event.kind != EKeyDown) return;
        if (event.keyCode == hxd.Key.Z || event.keyCode == hxd.Key.ENTER) {
            hide();
        }
    }

    public function show():Void {
        AudioManager.instance.stopMusic(1.0);
        final data = Scenario.instance != null ? Scenario.instance.calculateScore() : { raw : 0, graze : 0, deaths : 0, score : 0, total : 0, newRecord : false };
        score.loadData(data);
        score.show();
    }

    public function hide():Void {
        score.hide();
    }

    private function startedShowing():Void {
        inputEnabled = false;
        score.visible = true;
        background.visible = true;
        if (startedShowingCb != null) startedShowingCb();
    }

    private function finishedShowing():Void {
        inputEnabled = true;
        if (showedCb != null) showedCb();
    }

    private function startedHiding():Void {
        inputEnabled = false;
        if (startedHidingCb != null) startedHidingCb();
    }

    private function finishedHiding():Void {
        if (destroyAfterHide) {
            destroy();
            if (hiddenCb != null) showedCb();
            return;
        }
        score.visible = false;
        background.visible = false;
        inputEnabled = false;
        if (hiddenCb != null) showedCb();
    }
}