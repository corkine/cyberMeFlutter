import 'package:flutter/material.dart';

enum CoverFlowStyle {
  none,
  scale,
  opacity,
  both,
}

final _coverFlowStyle = ValueNotifier<CoverFlowStyle>(CoverFlowStyle.both);

class CoverFlowCarouselPage extends StatelessWidget {
  const CoverFlowCarouselPage({super.key});

  static PageRoute route() =>
      MaterialPageRoute(builder: (context) => const CoverFlowCarouselPage());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: _coverFlowStyle,
          builder: (context, value, child) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CoverFlowCarouselView(style: value, children: []),
                  const SizedBox(height: 20),
                  SegmentedButton<CoverFlowStyle>(
                    emptySelectionAllowed: true,
                    segments: const [
                      ButtonSegment(
                          value: CoverFlowStyle.none, label: Text('None')),
                      ButtonSegment(
                          value: CoverFlowStyle.scale, label: Text('Scale')),
                      ButtonSegment(
                          value: CoverFlowStyle.opacity,
                          label: Text('Opacity')),
                      ButtonSegment(
                          value: CoverFlowStyle.both, label: Text('Both')),
                    ],
                    selected: {value},
                    onSelectionChanged: (value) {
                      _coverFlowStyle.value = value.last;
                    },
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class CoverFlowCarouselView extends StatefulWidget {
  final List<Widget> children;
  const CoverFlowCarouselView({
    super.key,
    this.style = CoverFlowStyle.none,
    required this.children,
  });

  final CoverFlowStyle style;

  @override
  State<CoverFlowCarouselView> createState() => _CoverFlowCarouselViewState();
}

class _CoverFlowCarouselViewState extends State<CoverFlowCarouselView> {
  late PageController _pageController;
  final _maxHeight = 150.0;
  final _minItemWidth = 40.0;
  double _currentPageIndex = 0;
  final _spacing = 10.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _currentPageIndex.toInt(),
    );
    _pageController.addListener(_pageControllerListener);
  }

  void _pageControllerListener() {
    setState(() {
      _currentPageIndex = _pageController.page ?? 0;
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_pageControllerListener);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return SizedBox(
      height: _maxHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Stack(
              children: widget.children.asMap().entries.map((item) {
                final currentIndex = _currentPageIndex - item.key;
                return _CoverFlowPositionedItem(
                  baby: item.value,
                  index: currentIndex,
                  absIndex: currentIndex.abs(),
                  size: Size(screenWidth, _maxHeight),
                  minItemWidth: _minItemWidth,
                  maxItemWidth: screenWidth / 2,
                  spacing: _spacing,
                  style: widget.style,
                );
              }).toList(),
            ),
          ),
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              itemBuilder: (context, index) => const SizedBox.expand(),
              itemCount: widget.children.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverFlowPositionedItem extends StatelessWidget {
  const _CoverFlowPositionedItem({
    required this.baby,
    required this.index,
    required this.absIndex,
    required this.size,
    required this.minItemWidth,
    required this.maxItemWidth,
    required this.spacing,
    required this.style,
  });
  final Widget baby;
  final double index;
  final double absIndex;
  final Size size;
  final double minItemWidth;
  final double maxItemWidth;
  final double spacing;
  final CoverFlowStyle style;

  double get _getItemPosition {
    final centerPosition = size.width / 2;
    final mainPosition = centerPosition - (maxItemWidth / 2);
    if (index == 0) return mainPosition;
    return _calculateNewMainPosition(mainPosition);
  }

  double get _calculateItemWidth {
    final diffWidth = maxItemWidth - minItemWidth;
    final newMaxItemWidth = maxItemWidth - (diffWidth * absIndex);
    return (absIndex < 1 ? newMaxItemWidth : minItemWidth) - spacing;
  }

  double get _getScaleValue => 1 - (0.15 * absIndex);

  double get _getOpacityValue {
    return (1 - (0.2 * absIndex)).clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    Widget child = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: _calculateItemWidth,
        height: size.height,
        child: baby,
      ),
    );

    child = AnimatedScale(
      scale: style == CoverFlowStyle.scale || style == CoverFlowStyle.both
          ? _getScaleValue
          : 1,
      duration: const Duration(milliseconds: 150),
      curve: Curves.ease,
      child: child,
    );

    child = AnimatedOpacity(
      opacity: style == CoverFlowStyle.opacity || style == CoverFlowStyle.both
          ? _getOpacityValue
          : 1,
      duration: const Duration(milliseconds: 150),
      curve: Curves.ease,
      child: child,
    );

    child = Padding(
      padding: EdgeInsets.only(left: spacing / 2),
      child: child,
    );

    return Transform.translate(
      offset: Offset(_getItemPosition, 0),
      child: child,
    );
  }

  double _calculateLeftPosition(double mainPosition) {
    return absIndex <= 1 ? mainPosition : (mainPosition - minItemWidth);
  }

  double _calculateRightPosition(double mainPosition) {
    final totalItemWidth = maxItemWidth + minItemWidth;
    return absIndex <= 1 ? mainPosition : mainPosition + totalItemWidth;
  }

  double _calculateRightAndLeftDiffPosition() {
    return absIndex <= 1.0
        ? ((index > 0 ? minItemWidth : maxItemWidth) * absIndex)
        : ((index > 0 ? (absIndex - 1) : (absIndex - 2)) * minItemWidth);
  }

  double _calculateNewMainPosition(double mainPosition) {
    final diffPosition = _calculateRightAndLeftDiffPosition();
    final leftPosition = _calculateLeftPosition(mainPosition);
    final rightPosition = _calculateRightPosition(mainPosition);
    return index > 0
        ? leftPosition - diffPosition
        : rightPosition + diffPosition;
  }
}
