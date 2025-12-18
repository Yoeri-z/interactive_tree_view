import 'package:flutter/material.dart';

import './defaults.dart';
import './internal/node_widget.dart';
import './internal/tree_props.dart';
import './treeview.dart';
import './treecontroller.dart';

///A widget used to render a treeview in the ui, this tree does not take a controller but root nodes instead.
///Use this widget if you want to display a treeview that the user can not modify.
class StaticTreeview extends StatefulWidget {
  ///A widget used to render a treeview in the ui, this tree does not take a controller but root nodes instead.
  ///Use this widget if you want to display a treeview that the user can not modify.
  const StaticTreeview({
    super.key,
    required this.nodes,
    required this.nodeBuilder,
    this.indicator = const DefaultIndicator(height: 15),
    this.indicatorBuilder,
    this.childExtent = 8.0,
    this.spacing = 8.0,
    this.animationDuration,
  });

  ///The tree the widget will use to build its contents.
  final List<TreeNode> nodes;

  ///The builder used to build each node.
  ///Provides the context and the node being built, use the methods available on node to interact with it.
  final Widget Function(BuildContext context, TreeNode node) nodeBuilder;

  ///A builder that can be used to create indicators that depend on the node the dragged node will be placed under.
  ///If no builder is provided the regular [indicator] property will be used.
  ///
  ///The indicator is visible when a node is being dragged and shows where the widget would be placed if it would be dropped.
  ///
  ///The builder provides 3 parameters:
  /// - BuildContext: The buildcontext this indicator is built in.
  /// - TreeNode: The node that the indicator uses as a reference to place itself.
  /// - Placement: the placement it will have in respect to the given node.
  final Widget Function(
    BuildContext context,
    TreeNode referenceNode,
    Placement intendedPlacement,
  )?
  indicatorBuilder;

  ///The indicator that is visible when a node is being dragged
  ///and shows where the widget would be placed if it would be dropped.
  ///To make an indicator that depends on the position it is in take a look at the [indicatorBuilder] property
  final Widget indicator;

  ///The indent each child node has with respect to its parent.
  final double childExtent;

  ///The amount of space between nodes.
  final double spacing;

  ///The duration of the collapse and expand animations.
  final Duration? animationDuration;

  // TreeViewProps get _props => TreeViewProps(
  //   controller: controller,
  //   itemBuilder: nodeBuilder,
  //   indicator: indicator,
  //   indicatorBuilder: indicatorBuilder,
  //   childExtent: childExtent,
  //   spacing: spacing,
  //   animationDuration: animationDuration ?? const Duration(milliseconds: 150),
  // );

  @override
  State<StaticTreeview> createState() => _TreeViewState();
}

class _TreeViewState extends State<StaticTreeview> {
  void listener() => setState(() {});

  late var controller = TreeController(initialNodes: widget.nodes);

  @override
  void initState() {
    super.initState();
    controller.traverse((node) => node.draggable = false);
    controller.addListener(listener);
  }

  @override
  void didUpdateWidget(covariant StaticTreeview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nodes == widget.nodes) return;

    controller.dispose();
    controller = TreeController(initialNodes: widget.nodes);
    controller.addListener(listener);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: controller.rootCount,
      itemBuilder:
          (context, index) => NodeWidget(
            key: ValueKey(controller.rootNodes[index].identifier),
            node: controller.rootNodes[index],
            props: TreeViewProps(
              controller: controller,
              itemBuilder: widget.nodeBuilder,
              indicator: widget.indicator,
              indicatorBuilder: widget.indicatorBuilder,
              allowPlacement: (_, _) => true,
              childExtent: widget.childExtent,
              spacing: widget.spacing,
              animationDuration:
                  widget.animationDuration ?? const Duration(milliseconds: 150),
            ),
          ),
    );
  }
}
