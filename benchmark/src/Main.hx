
import uk.aidanlee.flurry.Flurry;
import uk.aidanlee.flurry.FlurryConfig;
import uk.aidanlee.flurry.api.maths.Vector;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.resources.Resource.ShaderResource;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.QuadGeometry;
import uk.aidanlee.flurry.api.gpu.batcher.Batcher;
import uk.aidanlee.flurry.api.gpu.shader.Uniforms;
import uk.aidanlee.flurry.api.gpu.camera.OrthographicCamera;
import uk.aidanlee.flurry.modules.imgui.ImGuiImpl;
import imgui.NativeImGui;

typedef UserConfig = {};

class Main extends Flurry
{
    /**
     * Batcher to store all of our quad geometry.
     */
    var batcher : Batcher;

    /**
     * 2D camera to view all our geometries.
     */
    var camera : OrthographicCamera;

    /**
     * Number of haxe logos to create.
     */
    var numLogos : Int;

    /**
     * Array of all our haxe logos.
     */
    var sprites : Array<QuadGeometry>;

    /**
     * Array of all our haxe logos direction unit vector.
     */
    var vectors : Array<Vector>;

    /**
     * Imgui implementation helper.
     */
    var imgui : ImGuiImpl;

    override function onConfig(_config : FlurryConfig) : FlurryConfig
    {
        _config.window.title  = 'Flurry';
        _config.window.width  = 1600;
        _config.window.height = 900;

        _config.renderer.backend = OGL3;

        _config.resources.preload.images.push({ id : 'assets/images/haxe.png' });
        _config.resources.preload.images.push({ id : 'assets/images/logo.png' });
        _config.resources.preload.shaders.push({
            id : 'std-shader-textured.json', path : 'assets/shaders/textured.json',
            hlsl : { vertex: 'assets/shaders/hlsl/textured.hlsl', fragment: 'assets/shaders/hlsl/textured.hlsl' },
            ogl4 : { vertex: 'assets/shaders/ogl4/textured.vert', fragment: 'assets/shaders/ogl4/textured.frag' },
            ogl3 : { vertex: 'assets/shaders/ogl3/textured.vert', fragment: 'assets/shaders/ogl3/textured.frag' }
        });

        return _config;
    }

    override function onReady()
    {
        var shader = resources.get('std-shader-textured.json', ShaderResource);
        shader.uniforms.vector4.set('cvec', new Vector(0, 0, 0, 0));
        shader.uniforms.float.set('alpha', 1);

        imgui   = new ImGuiImpl(events, display, resources, input, renderer);
        camera  = new OrthographicCamera(1600, 900);
        batcher = renderer.createBatcher({ shader : shader, camera : camera });

        // Add some sprites.
        var largeHaxe = 'assets/images/haxe.png';
        var smallHaxe = 'assets/images/logo.png';

        sprites  = [];
        vectors  = [];
        numLogos = 10000;
        
        var unif = new Uniforms();
        unif.vector4.set('cvec', new Vector(0, 0, 0, 0));
        unif.float.set('alpha', 0.5);

        for (i in 0...numLogos)
        {
            var sprite = new QuadGeometry({
                textures   : [ resources.get(largeHaxe, ImageResource) ],
                batchers   : [ batcher ],
                uniforms   : unif,
                uploadType : Stream
            });
            sprite.scale.set_xy(0.5, 0.5);
            sprite.origin.set_xy(75, 75);
            sprite.position.set_xy(1600 / 2, 900 / 2);

            sprites.push(sprite);
            vectors.push(random_point_in_unit_circle());
        }

        var logo = new QuadGeometry({
            textures   : [ resources.get(smallHaxe, ImageResource) ],
            batchers   : [ batcher ],
            depth      : 2,
            uploadType : Stream
        });
        logo.origin.set_xy(resources.get(smallHaxe, ImageResource).width / 2, resources.get(smallHaxe, ImageResource).height / 2);
        logo.position.set_xy(1600 / 2, 900 / 2);
    }

    override function onUpdate(_dt : Float)
    {
        camera.viewport.set(0, 0, display.width, display.height);

        // Make all of our haxe logos bounce around the screen.
        for (i in 0...numLogos)
        {
            sprites[i].position.x += (vectors[i].x * 1000) * _dt;
            sprites[i].position.y += (vectors[i].y * 1000) * _dt;

            if (sprites[i].position.x > 1600) vectors[i].x = -vectors[i].x;
            if (sprites[i].position.x <    0) vectors[i].x = -vectors[i].x;
            if (sprites[i].position.y >  900) vectors[i].y = -vectors[i].y;
            if (sprites[i].position.y <    0) vectors[i].y = -vectors[i].y;
        }
    }

    override function onPostUpdate()
    {
        uiShowRenderStats();
    }

    /**
     * Draw some stats about the renderer.
     */
    function uiShowRenderStats()
    {
        var distance       = 10;
        var windowPos      = ImVec2.create(NativeImGui.getIO().displaySize.x - distance, distance);
        var windowPosPivot = ImVec2.create(1, 0);

        NativeImGui.setNextWindowPos(windowPos, ImGuiCond.Always, windowPosPivot);
        NativeImGui.setNextWindowBgAlpha(0.3);
        if (NativeImGui.begin('Render Stats', null, ImGuiWindowFlags.NoMove | ImGuiWindowFlags.NoTitleBar | ImGuiWindowFlags.NoResize | ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoSavedSettings | ImGuiWindowFlags.NoFocusOnAppearing | ImGuiWindowFlags.NoNav))
        {
            NativeImGui.text('total batchers   ${renderer.stats.totalBatchers}');
            NativeImGui.text('total geometry   ${renderer.stats.totalGeometry}');
            NativeImGui.text('total vertices   ${renderer.stats.totalVertices}');
            NativeImGui.text('dynamic draws    ${renderer.stats.dynamicDraws}');
            NativeImGui.text('unchanging draws ${renderer.stats.unchangingDraws}');

            NativeImGui.text('');
            NativeImGui.text('state changes');
            NativeImGui.separator();

            NativeImGui.text('target           ${renderer.stats.targetSwaps}');
            NativeImGui.text('shader           ${renderer.stats.shaderSwaps}');
            NativeImGui.text('texture          ${renderer.stats.textureSwaps}');
            NativeImGui.text('viewport         ${renderer.stats.viewportSwaps}');
            NativeImGui.text('blend            ${renderer.stats.blendSwaps}');
            NativeImGui.text('scissor          ${renderer.stats.scissorSwaps}');
        }

        NativeImGui.end();
    }

    /**
     * Create a random unit vector.
     * @return Vector
     */
    function random_point_in_unit_circle() : Vector
    {
        var r : Float = Math.sqrt(Math.random());
        var t : Float = (-1 + (2 * Math.random())) * (Math.PI * 2);

        return new Vector(r * Math.cos(t), r * Math.sin(t));
    }
}