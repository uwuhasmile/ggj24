package game;

class Scenario extends Entity {
    public static var instance : Scenario;

    public var currentLevelData : { score : Int, graze : Int, deaths : Int };
    public var score(default, null) : Int;
    private var levels : List<String>;

    private override function added(s2d: h2d.Scene):Void {
        if (instance != null) {
            destroy();
            return;
        }
        instance = this;
        levels = new List();
        dontDestroy();
    }

    public function finish():Void {
        if (score > Main.instance.save.bestScore) Main.instance.save.bestScore = score;
        Main.instance.save.firstGame = false;
        hxd.Save.save(Main.instance.save, "lhSave");
        destroy();
    }

    private override function destroyed(s2d: h2d.Scene):Void {
        if (instance != this) return;
        instance = null;
        levels.clear();
        levels = null;
    }

    inline public function getCurrentScript():String
        return levels != null ? levels.first() : null;

    public function calculateScore():{ raw : Int, graze : Int, deaths : Int, score : Int, total : Int, newRecord : Bool } {
        if (currentLevelData == null) return { raw : 0, graze : 0, deaths : 0, score : 0, total : 0, newRecord : false };
        final raw = currentLevelData.score;
        final graze = currentLevelData.graze;
        final deaths = currentLevelData.deaths;
        var newScore = raw + Std.int(raw * 0.05) * graze - Std.int(raw * 0.1) * deaths;
        var total = score + newScore;
        var newRecord = total > Main.instance.save.bestScore;
        return { raw : raw, graze : graze, deaths : deaths, score : newScore, total : total, newRecord : newRecord };
    }

    public function updateScore():Void {
        score = calculateScore().total;
    }

    inline public function addLevel(level: String):Void {
        levels.add(level);
    }

    inline public function next():String {
        score = calculateScore().total;
        levels.pop();
        return levels.first();
    }
}