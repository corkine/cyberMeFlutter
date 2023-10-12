import 'package:flutter/material.dart';

class MedicView extends StatefulWidget {
  const MedicView({super.key});

  @override
  State<MedicView> createState() => _MedicViewState();
}

class _MedicViewState extends State<MedicView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Medic"),),
    );
  }
}
