import 'package:flutter/material.dart';

class ClothView extends StatefulWidget {
  const ClothView({super.key});

  @override
  State<ClothView> createState() => _ClothViewState();
}

class _ClothViewState extends State<ClothView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cloth"),
      ),
    );
  }
}
