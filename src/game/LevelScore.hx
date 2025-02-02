package game;

import h2d.Text;
import h2d.HtmlText;
import h2d.Object;

private typedef ScoreTween = {
    time : Float,
    dataTime : Float,
    dataStartX : Float,
    dataStartY : Float,
    dataStartA : Float,
    ?dataX : Float,
    ?dataY : Float,
    ?dataA : Float,
    resultTime : Float,
    resultStartX : Float,
    resultStartY : Float,
    resultStartA : Float,
    ?resultX : Float,
    ?resultY : Float,
    ?resultA : Float,
    ?startCb : Void->Void,
    ?endCb : Void->Void,
}

class LevelScore extends Object {
    public var data(default, null) : HtmlText;
    public var result(default, null) : HtmlText;
    public var newRecord(default, null) : Text;

    private var tween : ScoreTween;
    private var showTween : ScoreTween;
    private var hideTween : ScoreTween;

    public function new(?p: Object):Void {
        super(p);
        tween = null;
        final font = hxd.res.DefaultFont.get();
        data = new HtmlText(font, this);
        result = new HtmlText(font, this);
        newRecord = new Text(font, result);
        newRecord.text = "NEW RECORD!";
        newRecord.setScale(1.3);
        newRecord.textColor = 0xFFF8BC;
    }

    public function loadData(data: { raw : Int, graze : Int, deaths : Int, score : Int, total : Int, newRecord : Bool }) {
        this.data.text = '
            Raw score: <font color="#ffe27a">${data.raw}</font><br/>
            Graze: <font color="#ffe27a">${data.graze}</font><br/>
            Deaths: <font color="#ffc4c4">${data.deaths}</font><br/>
        ';
        result.text = '
            Score: <font color="#ffe27a">${data.score}</font><br/>
            Total: <font color="#ffe27a">${data.total}</font><br/>
        ';
        newRecord.visible = data.newRecord;
    }

    public function setShowTween(?dataTime: Float, ?dataStartX: Float, ?dataStartY: Float, ?dataStartA: Float, ?dataX: Float, ?dataY: Float, ?dataA: Float,
            ?resultTime: Float, ?resultStartX: Float, ?resultStartY: Float, ?resultStartA: Float, ?resultX: Float, ?resultY: Float, ?resultA: Float,
            ?startCb : Void->Void, ?endCb : Void->Void) {
        showTween = {
            time : 0.0,
            dataTime : dataTime,
            dataStartX : dataStartX ?? data.x,
            dataStartY : dataStartY ?? data.y,
            dataStartA : dataStartA ?? data.alpha,
            dataX : dataX,
            dataY : dataY,
            dataA : dataA,
            resultTime: resultTime,
            resultStartX : resultStartX ?? result.x,
            resultStartY : resultStartY ?? result.y,
            resultStartA : resultStartA ?? result.alpha,
            resultX : resultX,
            resultY : resultY,
            resultA : resultA,
            startCb : startCb,
            endCb : endCb,
        }
    }

    public function setHideTween(?dataTime: Float, ?dataStartX: Float, ?dataStartY: Float, ?dataStartA: Float, ?dataX: Float, ?dataY: Float, ?dataA: Float,
            ?resultTime: Float, ?resultStartX: Float, ?resultStartY: Float, ?resultStartA: Float, ?resultX: Float, ?resultY: Float, ?resultA: Float,
            ?startCb : Void->Void, ?endCb : Void->Void) {
        hideTween = {
            time : 0.0,
            dataTime : dataTime,
            dataStartX : dataStartX ?? data.x,
            dataStartY : dataStartY ?? data.y,
            dataStartA : dataStartA ?? data.alpha,
            dataX : dataX,
            dataY : dataY,
            dataA : dataA,
            resultTime: resultTime,
            resultStartX : resultStartX ?? result.x,
            resultStartY : resultStartY ?? result.y,
            resultStartA : resultStartA ?? result.alpha,
            resultX : resultX,
            resultY : resultY,
            resultA : resultA,
            startCb : startCb,
            endCb : endCb,
        }
    }

    public function show():Void {
        tween = showTween;
        tween.time = 0.0;
        data.x = tween.dataStartX;
        data.y = tween.dataStartY;
        data.alpha = tween.dataStartA;
        result.x = tween.resultStartX;
        result.y = tween.resultStartY;
        result.alpha = tween.resultStartA;
        if (tween.startCb != null) tween.startCb();
    }

    public function hide():Void {
        tween = hideTween;
        tween.time = 0.0;
        data.x = tween.dataStartX;
        data.y = tween.dataStartY;
        data.alpha = tween.dataStartA;
        result.x = tween.resultStartX;
        result.y = tween.resultStartY;
        result.alpha = tween.resultStartA;
        if (tween.startCb != null) tween.startCb();
    }

    public override function sync(ctx: h2d.RenderContext):Void {
        super.sync(ctx);
        if (tween != null) {
            var dataT : Float = 1.0;
            if (tween.dataTime != null) {
                dataT = hxd.Math.clamp(tween.time / tween.dataTime);
                if (tween.dataX != null) data.x = hxd.Math.lerp(tween.dataStartX, tween.dataX, dataT);
                if (tween.dataY != null) data.y = hxd.Math.lerp(tween.dataStartY, tween.dataY, dataT);
                if (tween.dataA != null) data.alpha = hxd.Math.lerp(tween.dataStartA, tween.dataA, dataT);
            }
            var resultT : Float = 1.0;
            if (tween.resultTime != null) {
                resultT = hxd.Math.clamp(tween.time / tween.resultTime);
                if (tween.resultX != null) result.x = hxd.Math.lerp(tween.resultStartX, tween.resultX, resultT);
                if (tween.resultY != null) result.y = hxd.Math.lerp(tween.resultStartY, tween.resultY, resultT);
                if (tween.resultA != null) result.alpha = hxd.Math.lerp(tween.resultStartA, tween.resultA, resultT);
            }
            if (dataT == 1.0 && resultT == 1.0) {
                if (tween.endCb != null) tween.endCb();
                tween = null;
            }
            else tween.time += ctx.elapsedTime;
        }
    }
}