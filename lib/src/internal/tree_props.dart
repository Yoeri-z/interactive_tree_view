import 'package:flutter/material.dart';
import 'package:interactive_tree_view/interactive_tree_view.dart';

///A props class containing all the customizable properties of a TreeView widget.
class TreeViewProps {
  const TreeViewProps({
    required this.controller,
    required this.itemBuilder,
    required this.indicator,
    this.indicatorBuilder,
    required this.childExtent,
    required this.spacing,
    required this.animationDuration,
  });

  final TreeController controller;
  final Widget Function(BuildContext context, TreeNode node) itemBuilder;
  final Widget Function(
    BuildContext context,
    TreeNode referenceNode,
    Placement intendedPlacement,
  )?
  indicatorBuilder;
  final Widget indicator;
  final double childExtent;
  final double spacing;
  final Duration animationDuration;
}
