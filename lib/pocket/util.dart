import 'package:flutter/material.dart';

Widget Function(BuildContext, AsyncSnapshot<Object?>) commonFutureBuilder<T>(
        Widget Function(T) buildMainPage) =>
    (BuildContext context, AsyncSnapshot<Object?> future) {
      if (future.hasData && future.data != null) {
        return buildMainPage(future.data as T);
      }
      if (future.hasError) {
        return SizedBox(
          width: double.infinity,
          height: MediaQuery.of(context).size.height - 100,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset("images/empty.png", width: 200),
                Text("发生了一些错误：${future.error}", textAlign: TextAlign.center)
              ]),
        );
      }
      return Container(
          alignment: Alignment.center,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                Padding(padding: EdgeInsets.all(20), child: Text("正在联系服务器"))
              ]));
    };
