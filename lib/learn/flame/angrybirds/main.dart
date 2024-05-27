import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';

import 'enemy.dart';
import 'player.dart';
import 'brick.dart';
import 'others.dart';

var gameWidth = 800.0;
var gameHeight = 600.0;
const groundSize = 7.0;
const brickScale = 0.5;
const playerSize = 5.0;
const enemySize = 5.0;

void main() {
  // assets from https://kenney.nl/assets/physics-assets
  runApp(const GameWidget.controlled(gameFactory: AngryBirds.new));
}

void modifyAngryBirds({required double width, required double height}) {
  gameWidth = width;
  gameHeight = height;
}

enum PlayState { welcome, playing, won }

class AngryBirds extends Forge2DGame with TapDetector {
  AngryBirds()
      : super(
            gravity: Vector2(0, 10),
            camera: CameraComponent.withFixedResolution(
                width: gameWidth, height: gameHeight));

  late final XmlSpriteSheet aliens;
  late final XmlSpriteSheet elements;
  late final XmlSpriteSheet tiles;
  late final ui.Image background;
  final _random = Random();

  final debug = false;
  var enemiesFullyAdded = false;
  var state = PlayState.welcome;

  @override
  FutureOr<void> onLoad() async {
    images.prefix = "images/angrybirds/";
    final [background, ai, ei, ti] = await [
      images.load('colored_grass.png'),
      images.load('spritesheet_aliens.png'),
      images.load('spritesheet_elements.png'),
      images.load('spritesheet_tiles.png')
    ].wait;
    this.background = background;
    aliens = XmlSpriteSheet(
        ai,
        await rootBundle
            .loadString('images/angrybirds/spritesheet_aliens.xml'));
    elements = XmlSpriteSheet(
        ei,
        await rootBundle
            .loadString('images/angrybirds/spritesheet_elements.xml'));
    tiles = XmlSpriteSheet(ti,
        await rootBundle.loadString('images/angrybirds/spritesheet_tiles.xml'));

    state = PlayState.welcome;
    await startGame();
    return super.onLoad();
  }

  Future<void> startGame() async {
    if (state == PlayState.playing) return;
    if (state == PlayState.won) {
      world.removeAll(world.children);
    }
    await world.add(Background(sprite: Sprite(background)));
    await addGround();
    unawaited(addBricks().then((_) => addEnemies().then((_) {
          state = PlayState.playing;
        })));
    await addPlayer();
  }

  @override
  void onTap() {
    super.onTap();
    startGame();
  }

  Future<void> addGround() async {
    final grass = tiles['grass.png'];
    return world.addAll([
      for (var x = camera.visibleWorldRect.left;
          x < camera.visibleWorldRect.right + groundSize;
          x += groundSize)
        Ground(Vector2(x, (camera.visibleWorldRect.height - groundSize) / 2),
            grass)
    ]);
  }

  Future<void> addBricks() async {
    for (var i = 0; i < (debug ? 0 : 5); i++) {
      final type = BrickType.randomType;
      final size = BrickSize.randomSize;
      await world.add(Brick(
          type: type,
          size: size,
          damage: BrickDamage.some,
          position: Vector2(
              camera.visibleWorldRect.right / 3 +
                  (_random.nextDouble() * 5 - 2.5),
              0),
          sprites: brickFileNames(type, size)
              .map((k, f) => MapEntry(k, elements[f]))));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> addPlayer() async {
    world.add(Player(Vector2(camera.visibleWorldRect.left * 2 / 3, 0),
        aliens[PlayerColor.randomColor.fileName]));
  }

  Future<void> addEnemies() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    for (var i = 0; i < (debug ? 1 : 3); i++) {
      await world.add(
        Enemy(
          Vector2(
              camera.visibleWorldRect.right / 3 +
                  (_random.nextDouble() * 7 - 3.5),
              (_random.nextDouble() * 3)),
          aliens[EnemyColor.randomColor.fileName],
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    enemiesFullyAdded = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (state == PlayState.playing &&
        isMounted &&
        world.children.whereType<Player>().isEmpty) {
      addPlayer();
    }
    if (state == PlayState.playing &&
        isMounted &&
        world.children.whereType<Enemy>().isEmpty &&
        world.children.query<TextComponent>().isEmpty) {
      world.addAll([
        (position: Vector2(0.5, 0.5), color: Colors.white),
        (position: Vector2.zero(), color: Colors.orangeAccent),
      ].map((e) => TextComponent(
          text: 'You win!',
          anchor: Anchor.center,
          position: e.position,
          textRenderer:
              TextPaint(style: TextStyle(color: e.color, fontSize: 16)))));
      state = PlayState.won;
    }
  }
}

class XmlSpriteSheet {
  XmlSpriteSheet(this.image, String xml) {
    final doc = XmlDocument.parse(xml);
    for (final node in doc.xpath("//TextureAtlas/SubTexture")) {
      final name = node.getAttribute("name")!;
      final x = double.parse(node.getAttribute("x")!);
      final y = double.parse(node.getAttribute("y")!);
      final w = double.parse(node.getAttribute("width")!);
      final h = double.parse(node.getAttribute("height")!);
      _rects[name] = Rect.fromLTWH(x, y, w, h);
    }
  }
  final ui.Image image;
  final _rects = <String, Rect>{};
  Sprite operator [](String name) {
    final rect = _rects[name];
    if (rect == null) {
      throw ArgumentError('Sprite $name not found');
    }
    return Sprite(
      image,
      srcPosition: rect.topLeft.toVector2(),
      srcSize: rect.size.toVector2(),
    );
  }
}

class BodyComponentWithData extends BodyComponent {
  BodyComponentWithData(
      {super.key,
      super.bodyDef,
      super.children,
      super.fixtureDefs,
      super.paint,
      super.priority,
      super.renderBody});
  @override
  Body createBody() {
    final body = world.createBody(super.bodyDef!)..userData = this;
    fixtureDefs?.forEach(body.createFixture);
    return body;
  }
}

class AngryBirdsGameSimple extends StatelessWidget {
  const AngryBirdsGameSimple({super.key});

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.maybeSizeOf(context)!;
    modifyAngryBirds(width: s.width, height: s.height);
    return const GameWidget.controlled(gameFactory: AngryBirds.new);
  }
}

class AngryBirdsGame extends StatefulWidget {
  const AngryBirdsGame({super.key});

  @override
  State<AngryBirdsGame> createState() => _GameAppState();
}

class _GameAppState extends State<AngryBirdsGame> {
  late final AngryBirds game;
  @override
  void initState() {
    super.initState();
    game = AngryBirds();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            useMaterial3: true,
            textTheme: GoogleFonts.pressStart2pTextTheme().apply(
                bodyColor: const Color(0xff184e77),
                displayColor: const Color(0xff184e77))),
        home: Scaffold(
            body: Container(
                decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xffa9d6e5), Color(0xfff2e8cf)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter)),
                child: SafeArea(
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                            child: Column(children: [
                          Expanded(
                              child: FittedBox(
                                  child: SizedBox(
                                      width: gameWidth,
                                      height: gameHeight,
                                      child: GameWidget.controlled(
                                          gameFactory: () => game))))
                        ])))))));
  }
}
