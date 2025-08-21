import 'package:flutter/material.dart';
import 'package:interactive_tree_view/interactive_tree_view.dart';

///A props class containing all the customizable properties of a TreeView widget.
class _TreeViewProps {
  const _TreeViewProps({
    required this.controller,
    required this.itemBuilder,
    required this.indicator,
    this.indicatorBuilder,
    required this.rowExtent,
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
  final double rowExtent;
  final double spacing;
  final Duration animationDuration;
}

enum Placement { above, below }

///A widget used to render a treeview in the ui, based on the state of this tree inside the controller.
class TreeView extends StatefulWidget {
  ///A widget used to render a treeview in the ui, based on the state of this tree inside the controller.
  const TreeView({
    super.key,
    required this.controller,
    required this.nodeBuilder,
    this.indicator = const DefaultIndicator(height: 15),
    this.indicatorBuilder,
    this.rowExtent = 8.0,
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
  ///   This can be either a sibling or a parent.
  /// - Placement: the placement it will have in respect to [referenceNode].
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
  final double rowExtent;

  ///The amount of space between nodes.
  final double spacing;

  ///The duration of the collapse and expand animations.
  final Duration? animationDuration;

  _TreeViewProps get _props => _TreeViewProps(
    controller: controller,
    itemBuilder: nodeBuilder,
    indicator: indicator,
    indicatorBuilder: indicatorBuilder,
    rowExtent: rowExtent,
    spacing: spacing,
    animationDuration: animationDuration ?? Duration(milliseconds: 150),
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
    if (oldWidget.controller != widget.controller) return;
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
          (context, index) => _NodeWidget(
            node: widget.controller.rootNodes[index],
            props: widget._props,
          ),
    );
  }
}

class _NodeWidget extends StatefulWidget {
  const _NodeWidget({required this.node, required this.props});

  final TreeNode node;
  final _TreeViewProps props;

  @override
  State<_NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<_NodeWidget> {
  bool isBeingDragged = false;
  Placement? indicatorPlacement;

  Offset? getGlobalOffset() =>
      (context.findRenderObject() as RenderBox?)?.localToGlobal(Offset.zero);

  Size? getObjectSize() => (context.findRenderObject() as RenderBox?)?.size;

  Placement getIndicatorPlacement(DragTargetDetails<TreeNode> details) {
    final offset = getGlobalOffset();
    final size = getObjectSize();

    final isAbove = details.offset.dy < offset!.dy + size!.height / 3;

    if (isAbove) {
      return Placement.above;
    } else {
      return Placement.below;
    }
  }

  void _resetDrag() {
    widget.node.expand(notify: false);
    widget.node.isBeingDragged = false;
    isBeingDragged = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: widget.props.spacing / 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DragTarget<TreeNode>(
            onAcceptWithDetails: (details) {
              final placement = getIndicatorPlacement(details);

              if (placement == Placement.below) {
                widget.props.controller.move(
                  details.data,
                  widget.node.index + 1,
                  newParent: widget.node.parent,
                );
              } else {
                widget.props.controller.move(
                  details.data,
                  widget.node.index,
                  newParent: widget.node.parent,
                );
              }
            },
            onMove: (details) {
              widget.node.expand();
              final placement = getIndicatorPlacement(details);

              if (placement != indicatorPlacement) {
                indicatorPlacement = placement;
                setState(() {});
              }
            },
            builder: (context, candidate, _) {
              if (isBeingDragged) {
                return const SizedBox();
              }
              if (candidate.isEmpty) {
                return widget.node.draggable
                    ? Draggable(
                      data: widget.node,
                      onDragStarted: () {
                        widget.node.collapse();
                        widget.node.isBeingDragged = true;
                        isBeingDragged = true;
                      },
                      onDragEnd: (_) => _resetDrag(),
                      onDraggableCanceled: (_, __) => _resetDrag(),
                      onDragCompleted: () => _resetDrag(),
                      feedback: Material(
                        child: SizedBox(
                          width: getObjectSize()?.width ?? 500,
                          child: widget.props.itemBuilder(context, widget.node),
                        ),
                      ),
                      child: widget.props.itemBuilder(context, widget.node),
                    )
                    : widget.props.itemBuilder(context, widget.node);
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                spacing: widget.props.spacing,
                children: [
                  if (indicatorPlacement == Placement.above)
                    widget.props.indicatorBuilder?.call(
                          context,
                          widget.node,
                          indicatorPlacement!,
                        ) ??
                        widget.props.indicator,
                  widget.props.itemBuilder(context, widget.node),
                  if (indicatorPlacement == Placement.below)
                    widget.props.indicatorBuilder?.call(
                          context,
                          widget.node,
                          indicatorPlacement!,
                        ) ??
                        widget.props.indicator,
                ],
              );
            },
          ),
          if (widget.node.expanded && !isBeingDragged)
            SizedBox(height: widget.props.spacing / 2),
          AnimatedSwitcher(
            duration: widget.props.animationDuration,
            transitionBuilder:
                (child, animation) =>
                    SizeTransition(sizeFactor: animation, child: child),
            child:
                widget.node.expanded && !isBeingDragged
                    ? Padding(
                      padding: EdgeInsets.only(left: widget.props.rowExtent),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final child in widget.node.children)
                            _NodeWidget(node: child, props: widget.props),
                        ],
                      ),
                    )
                    : const SizedBox(),
          ),
        ],
      ),
    );
  }
}
