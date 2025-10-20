import 'package:flutter/material.dart';
import 'package:interactive_tree_view/interactive_tree_view.dart';
import 'package:interactive_tree_view/src/internal/node_widget.dart';
import 'package:interactive_tree_view/src/internal/tree_props.dart';

///Indicates the placement of a node with respect to another node.
///
///Used in the [TreeView.indicatorBuilder] to indicate the placement of the indicator with respect to the given node.
enum Placement {
  ///Placed above.
  above,

  ///Placed below.
  below,

  ///Placed as child.
  child,

  ///Not placed in the tree.
  none,
}

///A widget used to render a treeview in the ui, based on the state of this tree inside the controller.
class TreeView extends StatefulWidget {
  ///A widget used to render a treeview in the ui, based on the state of this tree inside the controller.
  const TreeView({
    super.key,
    required this.controller,
    required this.nodeBuilder,
    this.indicator = const DefaultIndicator(height: 15),
    this.indicatorBuilder,
    this.allowPlacement,
    this.childExtent = 8.0,
    this.spacing = 8.0,
    this.animationDuration,
  });

  ///The controller this widget should use to build its contents.
  final TreeController controller;

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

  ///Wether or not the user is allowed to place the node at the intended placement with reference to the passed node.
  final bool Function(TreeNode referenceNode, Placement intendedPlacement)?
  allowPlacement;

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

  TreeViewProps get _props => TreeViewProps(
    controller: controller,
    itemBuilder: nodeBuilder,
    indicator: indicator,
    indicatorBuilder: indicatorBuilder,
    allowPlacement: allowPlacement ?? (_, _) => true,
    childExtent: childExtent,
    spacing: spacing,
    animationDuration: animationDuration ?? const Duration(milliseconds: 150),
  );

  @override
  State<TreeView> createState() => _TreeViewState();
}

class _TreeViewState extends State<TreeView> {
  void listener() => setState(() {});

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(listener);
  }

  @override
  void didUpdateWidget(covariant TreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;

    oldWidget.controller.removeListener(listener);
    widget.controller.addListener(listener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.controller.rootCount,
      itemBuilder:
          (context, index) => NodeWidget(
            key: ValueKey(widget.controller.rootNodes[index].identifier),
            node: widget.controller.rootNodes[index],
            props: widget._props,
          ),
    );
  }
}
