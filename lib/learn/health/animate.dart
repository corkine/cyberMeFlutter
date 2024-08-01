import 'package:flutter/material.dart';

class GoEachSide extends StatelessWidget {
  final int arrowCount;
  final double arrowHeight;
  final Color arrowColor;
  final double arrowPadding;

  const GoEachSide({
    Key? key,
    required this.arrowCount,
    required this.arrowHeight,
    required this.arrowColor,
    required this.arrowPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
          arrowCount,
              (index) => GoForwardOne(
            height: arrowHeight,
            color: arrowColor,
            padding: arrowPadding,
          )).toList(),
    );
  }
}

class GoForwardOne extends StatelessWidget {
  final double height;
  final Color color;
  final double padding;

  const GoForwardOne(
      {Key? key,
        required this.height,
        required this.color,
        required this.padding})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: padding / 2, bottom: padding / 2),
      child: ClipPath(
        clipper: GoForward(),
        child: ColoredBox(
          color: color,
          child: SizedBox(
            height: height,
            width: height,
          ),
        ),
      ),
    );
  }
}

class GoForward extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..shift(Offset(0, size.height / 2))
      ..lineTo(0, size.height)
      ..lineTo(size.width / 2, size.height / 2)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width / 2, 0)
      ..lineTo(0, size.height / 2)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}