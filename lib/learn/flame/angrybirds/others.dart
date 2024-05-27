import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import 'main.dart';

class Background extends SpriteComponent with HasGameReference<AngryBirds> {
  Background({required super.sprite})
      : super(anchor: Anchor.center, position: Vector2(0, 0));
  @override
  void onMount() {
    super.onMount();
    size = Vector2.all(max(game.camera.visibleWorldRect.width,
        game.camera.visibleWorldRect.height));
  }
}

class Ground extends BodyComponentWithData {
  Ground(Vector2 position, Sprite sprite)
      : super(
            renderBody: false,
            bodyDef: BodyDef()
              ..position = position
              ..type = BodyType.static,
            fixtureDefs: [
              FixtureDef(
                  PolygonShape()..setAsBoxXY(groundSize / 2, groundSize / 2),
                  friction: 0.3)
            ],
            children: [
              SpriteComponent(
                  anchor: Anchor.center,
                  sprite: sprite,
                  size: Vector2.all(groundSize),
                  position: Vector2(0, 0))
            ]);
}
