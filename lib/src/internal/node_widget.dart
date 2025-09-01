import 'package:flutter/material.dart';
import 'package:interactive_tree_view/src/internal/tree_props.dart';
import 'package:interactive_tree_view/src/treecontroller.dart';
import 'package:interactive_tree_view/src/treeview.dart';

class NodeWidget extends StatefulWidget {
  const NodeWidget({super.key, required this.node, required this.props});

  final TreeNode node;
  final TreeViewProps props;

  @override
  State<NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget> {
  bool isBeingDragged = false;
  Placement? indicatorPlacement;

  Offset? getGlobalOffset() =>
      (context.findRenderObject() as RenderBox?)?.localToGlobal(Offset.zero);

  Size? getObjectSize() => (context.findRenderObject() as RenderBox?)?.size;

  Placement getIndicatorPlacement(DragTargetDetails<TreeNode> details) {
    final offset = getGlobalOffset();
    final size = getObjectSize();

    final isAbove = details.offset.dy < offset!.dy;

    final isChild = details.offset.dx > offset.dx + size!.width / 2;

    if (isChild) {
      return Placement.child;
    } else if (isAbove) {
      return Placement.above;
    } else {
      return Placement.below;
    }
  }

  void resetDrag() {
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
              if (placement == Placement.child) {
                details.data.isAttached
                    ? widget.props.controller.move(
                      details.data,
                      0,
                      newParent: widget.node,
                    )
                    : widget.node.attachChild(details.data, index: 0);
              } else if (placement == Placement.below) {
                details.data.isAttached
                    ? widget.props.controller.move(
                      details.data,
                      widget.node.index + 1,
                      newParent: widget.node.parent,
                    )
                    : widget.node.attachSibling(details.data);
              } else {
                details.data.isAttached
                    ? widget.props.controller.move(
                      details.data,
                      widget.node.index,
                      newParent: widget.node.parent,
                    )
                    : widget.node.attachSibling(
                      details.data,
                      index: widget.node.index,
                    );
              }
            },
            onMove: (details) {
              final placement = getIndicatorPlacement(details);

              if (placement == Placement.child) {
                widget.node.expand();
              } else {
                widget.node.collapse();
              }

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
                        widget.node.isBeingDragged = true;
                        isBeingDragged = true;
                        widget.node.collapse();
                      },
                      onDragEnd: (_) => resetDrag(),
                      onDraggableCanceled: (_, __) => resetDrag(),
                      onDragCompleted: () => resetDrag(),
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
                  if (indicatorPlacement == Placement.child)
                    Padding(
                      padding: EdgeInsets.only(left: widget.props.childExtent),
                      child:
                          widget.props.indicatorBuilder?.call(
                            context,
                            widget.node,
                            indicatorPlacement!,
                          ) ??
                          widget.props.indicator,
                    ),
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
                      padding: EdgeInsets.only(left: widget.props.childExtent),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final child in widget.node.children)
                            NodeWidget(
                              key: ValueKey(child.identifier),
                              node: child,
                              props: widget.props,
                            ),
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
