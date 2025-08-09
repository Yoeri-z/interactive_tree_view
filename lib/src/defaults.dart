import 'package:flutter/material.dart';

class DefaultIndicator extends StatelessWidget {
  const DefaultIndicator({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey,
      child: SizedBox(width: double.infinity, height: height),
    );
  }
}
