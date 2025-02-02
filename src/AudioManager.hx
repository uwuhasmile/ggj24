import hxd.snd.Channel;
import hxd.snd.SoundGroup;

class AudioManager {
    public static var instance(default, null) : AudioManager;

    private var sfxSoundGroup : SoundGroup;
    private var musicSoundGroup : SoundGroup;

    private var channels : Map<Int, Channel>;
    private var music : Channel;

    @:allow(Main.init)
    private function new():Void {
        instance = this;
        channels = new Map();
        sfxSoundGroup = new SoundGroup("sfxSoundGroup");
        sfxSoundGroup.maxAudible = 32;
        sfxSoundGroup.volume = 1.0;
        musicSoundGroup = new SoundGroup("musicSoundGroup");
        musicSoundGroup.maxAudible = 1;
    }

    public function setSoundVolume(vol: Float):Void {
        sfxSoundGroup.volume = vol;
    }

    public function setMusicVolume(vol: Float):Void {
        musicSoundGroup.volume = vol;
    }

    inline public function getSoundVolume():Float return sfxSoundGroup.volume;
    inline public function getMusicVolume():Float return musicSoundGroup.volume;

    public function playSound(channel: Int, path: String, loop: Bool = false, volume: Float = 1.0):Void {
        if (channel < 0 || channel >= 16) throw 'Invalid sound channel $channel!';
        if (channels.exists(channel)) channels[channel].stop();
        channels[channel] = hxd.Res.load(path).toSound().play(loop, volume, null, sfxSoundGroup);
        channels[channel].onEnd = channels.remove.bind(channel);
    }

    public function playSoundNoChannel(path: String, volume: Float = 1.0):Void {
        hxd.Res.load(path).toSound().play(false, volume, null, sfxSoundGroup);
    }

    public function stopSound(channel: Int):Void {
        if (!channels.exists(channel)) return;
        channels[channel].stop();
        channels.remove(channel);
    }

    public function stopAllSounds():Void {
        channels.clear();
        final mgr = hxd.snd.Manager.get();
        if (mgr != null) mgr.stopByName("sfxSoundGroup");
    }

    public function setSoundLoop(channel: Int, loop: Bool):Void {
        if (!channels.exists(channel)) return;
        channels[channel].loop = loop;
    }

    public function playMusic(path: String, loop: Bool = true, volume: Float = 1.0):Void {
        if (music != null) music.stop();
        music = hxd.Res.load(path).toSound().play(loop, volume, null, musicSoundGroup);
        music.onEnd = () -> { if (!music.loop) music = null; };
    }

    public function stopMusic(fadeOutTime: Float = 0.0):Void {
        if (music == null) return;
        if (fadeOutTime > 0.0) music.fadeTo(0.0, fadeOutTime, () -> { music.stop(); music = null; });
        else {
            music.stop();
            music = null;
        }
    }

    public function fadeMusic(to: Float, time: Float):Void {
        if (music == null) return;
        music.fadeTo(to, time);
    }

    public function setMusicLoop(loop: Bool):Void {
        if (music == null) return;
        music.loop = loop;
    }

    inline public function isPlaying(channel: Int):Bool {
        return channels.exists(channel);
    }
}