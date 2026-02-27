module scene;

import dagon;

class SponzaScene: Scene
{
    Game game;
    TextureAsset splashTextureAsset;
    LoadingScreen loadingScreen;
    GLTFAsset sponza;
    Camera camera;
    FirstPersonViewComponent fpview;
    TextureAsset aTexEnvmap;
    
    Light sun;
    float sunPitch = -80.0f;
    float sunTurn = 40;

    this(Game game)
    {
        super(game);
        this.game = game;
        splashTextureAsset = addTextureAsset("data/loading.jpg", true);
        loadingScreen = New!LoadingScreen(game, this);
        loadingScreen.backgroundTexture = splashTextureAsset.texture;
        loadingScreen.progressbarCentered = false;
    }

    override void beforeLoad()
    {
        sponza = addGLTFAsset("data/sponza/Sponza.gltf");
        aTexEnvmap = addTextureAsset("data/envmap.hdr");
    }
    
    override void onLoad(Time t, float progress)
    {
        loadingScreen.progressbar.position = Vector3f(
            (game.drawableWidth - loadingScreen.progressbarWidth) * 0.5f,
            game.drawableHeight - 40.0f, 0);
        loadingScreen.update(t, progress);
        loadingScreen.render();
    }

    override void afterLoad()
    {
        Texture cubemap = generateCubemap(1024, aTexEnvmap.texture, null);
        Texture prefilteredCubemap = prefilterCubemap(1024, cubemap, assetManager);
        Delete(cubemap);
        
        environment.backgroundColor = Color4f(0.5f, 0.5f, 0.0f, 1.0f);
        environment.ambientMap = prefilteredCubemap;
        environment.ambientEnergy = 0.2f;
        
        camera = addCamera();
        camera.position = Vector3f(1.0f, 2.0f, 0.0f);
        fpview = New!FirstPersonViewComponent(eventManager, camera);
        game.renderer.activeCamera = camera;

        sun = addLight(LightType.Sun);
        sun.shadowEnabled = true;
        sun.energy = 10.0f;
        sun.scatteringEnabled = true;
        sun.scattering = 0.3f;
        sun.mediumDensity = 0.075f;
        sun.scatteringUseShadow = true;
        sun.scatteringMaxRandomStepOffset = 0.055f;
        environment.sun = sun;
        
        auto sky = addEntity();
        sky.layer = EntityLayer.Background;
        auto psync = New!PositionSync(eventManager, sky, camera);
        sky.drawable = New!ShapeBox(Vector3f(1.0f, 1.0f, 1.0f), assetManager);
        sky.scaling = Vector3f(100.0f, 100.0f, 100.0f);
        sky.material = addMaterial();
        sky.material.depthWrite = false;
        sky.material.useCulling = false;
        sky.material.shader = New!RayleighShader(assetManager);
        
        useEntity(sponza.rootEntity);
        foreach(node; sponza.nodes)
        {
            useEntity(node.entity);
        }
        sponza.rootEntity.updateTransformationTopDown();
        
        fpview.active = false;
    }
    
    void cameraControl(double dt)
    {
        Vector3f forward = camera.transformation.forward;
        Vector3f right = camera.transformation.right; 
        float speed = 3;
        Vector3f dir = Vector3f(0, 0, 0);
        if (eventManager.keyPressed[KEY_W]) dir += -forward;
        if (eventManager.keyPressed[KEY_S]) dir += forward;
        if (eventManager.keyPressed[KEY_A]) dir += -right;
        if (eventManager.keyPressed[KEY_D]) dir += right;
        camera.position += dir.normalized * speed * dt;
    }
    
    void sunControl(double dt)
    {
        if (inputManager.getButton("sunDown")) sunPitch += 30.0f * dt;
        if (inputManager.getButton("sunUp")) sunPitch -= 30.0f * dt;
        if (inputManager.getButton("sunLeft")) sunTurn += 30.0f * dt;
        if (inputManager.getButton("sunRight")) sunTurn -= 30.0f * dt;
        
        sun.rotation =
            rotationQuaternion(Axis.y, degtorad(sunTurn)) *
            rotationQuaternion(Axis.x, degtorad(sunPitch));
    }
    
    override void onUpdate(Time time)
    {
        cameraControl(time.delta);
        sunControl(time.delta);
    }
    
    override void onKeyDown(int key)
    {
        if (!focused) return;
        
        if (key == KEY_ESCAPE)
        {
            application.exit();
        }
        else if (key == KEY_F12)
        {
            application.takeScreenshot("screenshots/screenshot");
        }
    }

    override void onKeyUp(int key) { }
    override void onMouseButtonDown(int button) { }
    
    override void onMouseButtonUp(int button)
    {
        if (!focused) return;
        
        fpview.active = !fpview.active;
        eventManager.showCursor(!fpview.active);
    }
}
