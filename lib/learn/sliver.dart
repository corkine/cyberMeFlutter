import 'package:flutter/material.dart';

class SliverApp extends StatelessWidget {
  const SliverApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HelloSliver(),
    );
  }
}

class HelloSliver extends StatefulWidget {
  const HelloSliver({Key? key}) : super(key: key);

  @override
  State<HelloSliver> createState() => _HelloSliverState();
}

class _HelloSliverState extends State<HelloSliver> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //CustomScrollView 用于实现滚动视窗
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        shrinkWrap: false,
        slivers: [
          const SliverAppBar(
            automaticallyImplyLeading: true,
            title: Text("HELLO"),
            floating: true,
            pinned: false,
            snap: true,
            stretch: true,
            expandedHeight: 150,
            collapsedHeight: 150,
            flexibleSpace: FlexibleSpaceBar(
              background: FlutterLogo(
                size: 40,
              ),
              title: Text("HELLO AGAIN"),
              stretchModes: [StretchMode.fadeTitle, StretchMode.zoomBackground],
              collapseMode: CollapseMode.parallax,
            ),
          ),
          //不能是普通组件，必须是 Sliver
          const SliverToBoxAdapter(
            child: FlutterLogo(
              size: 160,
            ),
          ),
          const SliverOpacity(
            opacity: 0.5,
            sliver: SliverToBoxAdapter(
              child: Text("HELLO WORLD"),
            ),
          ),
          const SliverAnimatedOpacity(
            duration: Duration(seconds: 2),
            opacity: 0.5,
            sliver: SliverToBoxAdapter(
              child: Text("HELLO WORLD"),
            ),
          ),
          SliverIgnorePointer(
            ignoring: true,
            sliver: SliverToBoxAdapter(
              child: TextButton(onPressed: () {}, child: const Text("HELLO")),
            ),
          ),
          //自动从开始处填满整个视窗，最大为一个视窗大小
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          SliverLayoutBuilder(builder: (context, constraint) {
            print(constraint);
            /*SliverConstraints(AxisDirection.down, 轴的方向
                GrowthDirection.forward, 弹性伸展方向
                ScrollDirection.idle,  用户滚动方向
                scrollOffset: 0.0, 滚出去的高度
                remainingPaintExtent: 0.0, 剩余可用空间
                crossAxisExtent: 392.7,
                crossAxisDirection: AxisDirection.right, 交叉轴方向
                viewportMainAxisExtent: 769.5, 视窗主轴最大高度
                remainingCacheExtent: 250.0, 剩余缓存高度，用于提前构造和处理新组件
                cacheOrigin: 0.0)*/
            return const SliverToBoxAdapter();
          }),
          //SliverList 提供了比 ListView 更底层的控制能力
          //实际上 ListView 就是一个 SliverList
          SliverList(
              //Or SliverChildListDelegate 非动态加载
              delegate: SliverChildBuilderDelegate(
                  (context, index) => Container(
                        height: 100,
                        alignment: Alignment.center,
                        child: Text("Hello $index"),
                      ),
                  childCount: 4)),
          //ListView.extent 就是 SliverFixedExtentList
          SliverFixedExtentList(
              delegate: SliverChildListDelegate([
                const FlutterLogo(),
                const FlutterLogo(),
                const FlutterLogo(
                  size: 30,
                )
              ]),
              itemExtent: 30),
          //Sliver 有一些更好玩的：
          //SliverPrototypeExtentList 基于原型布局，
          //其 prototypeItem，其不会显示，但其布局作为基础用于决定其余元素布局，
          //比 FixedExtent 更灵活。
          SliverPrototypeExtentList(
              delegate: SliverChildListDelegate([const Text("HELLO")]),
              prototypeItem: const FlutterLogo()),
          //SliverFillViewport 每个元素都填满视窗
          SliverFillViewport(
              delegate: SliverChildListDelegate(
                  [const Text("HELLO"), const Text("WORLD")])),
          //GridView 对应 SliverGrid，通过委托实现功能
          SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                return const Icon(Icons.add);
              }, childCount: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3))
        ],
      ),
    );
  }
}
