import 'package:flutter/material.dart';

///The default indicator for a treeview.
class DefaultIndicator extends StatelessWidget {
  ///The default indicator for a treeview.
  const DefaultIndicator({super.key, required this.height});

  ///The height of this indicator
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey,
      child: SizedBox(width: double.infinity, height: height),
    );
  }
}
