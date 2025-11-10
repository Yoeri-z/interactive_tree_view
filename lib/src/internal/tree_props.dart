import 'package:flutter/material.dart';
import 'package:interactive_tree_view/interactive_tree_view.dart';

///A props class containing all the customizable properties of a TreeView widget.
class TreeViewProps {
  const TreeViewProps({
    required this.controller,
    required this.itemBuilder,
    required this.indicator,
    this.indicatorBuilder,
    required this.allowPlacement,
    required this.childExtent,
    required this.spacing,
    required this.animationDuration,
    this.dragStartMode = DragStartMode.tap,
  });

  final TreeController controller;
  final Widget Function(BuildContext context, TreeNode node) itemBuilder;
  final Widget Function(
    BuildContext context,
    TreeNode referenceNode,
    Placement intendedPlacement,
  )?
  indicatorBuilder;
  final bool Function(TreeNode referenceNode, Placement intendedPlacement)
  allowPlacement;

  final Widget indicator;
  final double childExtent;
  final double spacing;
  final Duration animationDuration;
  final DragStartMode dragStartMode;
}
