package shaders;

class Blink extends hxsl.Shader {
    static var SRC = {
        @global var time : Float;
        @param var enabled : Int;
        @param var frequency : Float;
        @param var color : Vec4;
        @param var blend : Float;
        
        var pixelColor : Vec4;

        function fragment():Void {
            if (enabled == 0 || (time % frequency * 2.0) < frequency) pixelColor.rgba = pixelColor.rgba;
            else if (time % frequency < frequency) pixelColor.rgba = mix(pixelColor.rgba, color.rgba, blend);
        }
    }

    public function new(enabled: Int, frequency: Float, color: h3d.Vector4, blend: Float):Void {
        super();
        this.enabled = enabled;
        this.frequency = frequency;
        this.color = color;
        this.blend = blend;
    }
}