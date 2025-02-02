# LaugHell - a bullet hell game for Global Game Jam 2024

In order to build the source code provided:
1. Install Haxe 4.3.3 (https://haxe.org/download/version/4.3.3/). You should install both Haxe and Neko in order to be able to use haxelib
2. Install git versions of Heaps.io and HScript. In command prompt, write:
	- haxelib git format https://github.com/HaxeFoundation/format
	- haxelib git heaps https://github.com/HeapsIO/heaps
	- haxelib git hscript https://github.com/HaxeFoundation/hscript
3. For release build, in command prompt write "haxe build.hxml". For debug build, "haxe build.debug.hxml". This should produce game.js and res.pak in /build folder.