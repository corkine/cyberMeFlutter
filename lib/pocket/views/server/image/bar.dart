import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class BarView extends ConsumerWidget {
  final String registry;
  const BarView({super.key, required this.registry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color =
        Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.4);
    return DefaultTextStyle(
      style: const TextStyle(color: Colors.black, fontSize: 11),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(
          child: InkWell(
              child: Container(
                  color: Theme.of(context).colorScheme.primary,
                  height: 25,
                  alignment: Alignment.center,
                  child: Text(registry.toUpperCase(),
                      style: const TextStyle(color: Colors.white))),
              onTap: () {}),
        ),
        Expanded(
          child: InkWell(
              child: Container(
                  color: color,
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  alignment: Alignment.center,
                  child: const Text("LOGIN")),
              onTap: () {}),
        ),
        Expanded(
          child: InkWell(
              child: Container(
                  color: color,
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  alignment: Alignment.center,
                  child: const Text("PULL")),
              onTap: () {}),
        ),
        // Expanded(
        //   child: InkWell(
        //       child: Container(
        //           color: color,
        //           padding: const EdgeInsets.symmetric(vertical: 3),
        //           alignment: Alignment.center,
        //           child: const Text("TAG")),
        //       onTap: () {}),
        // ),
        // Expanded(
        //   child: InkWell(
        //       child: Container(
        //           color: color,
        //           padding: const EdgeInsets.symmetric(vertical: 3),
        //           alignment: Alignment.center,
        //           child: const Text("PUSH")),
        //       onTap: () {}),
        // ),
        Expanded(
          child: InkWell(
              child: Container(
                  color: Theme.of(context)
                      .colorScheme
                      .errorContainer
                      .withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  alignment: Alignment.center,
                  child: const Text("DELETE")),
              onTap: () {}),
        ),
      ]),
    );
  }
}
