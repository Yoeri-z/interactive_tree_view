import 'package:flutter/material.dart';
import 'package:treeview_draggable/treeview_draggable.dart';

class TreeView extends StatefulWidget {
  const TreeView({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.rowExtent = 8.0,
    this.spacing = 8.0,
    this.animationDuration,
  });

  final TreeController controller;
  final Widget Function(BuildContext context, TreeNode node) itemBuilder;
  final double rowExtent;
  final double spacing;
  final Duration? animationDuration;

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
    return SingleChildScrollView(
      child: NodeList(
        nodes: widget.controller.rootNodes,
        controller: widget.controller,
        spacing: widget.spacing,
        rowExtent: widget.rowExtent,
        itemBuilder: widget.itemBuilder,
        animationDuration:
            widget.animationDuration ?? Duration(milliseconds: 100),
      ),
    );
  }
}

class NodeList extends StatelessWidget {
  const NodeList({
    super.key,
    required this.nodes,
    required this.controller,
    required this.spacing,
    required this.rowExtent,
    required this.itemBuilder,
    required this.animationDuration,
  });

  final List<TreeNode> nodes;
  final TreeController controller;
  final double spacing;
  final double rowExtent;
  final Widget Function(BuildContext context, TreeNode node) itemBuilder;
  final Duration animationDuration;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing / 2),
      child: Column(
        spacing: spacing,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final node in nodes)
            AnimatedCrossFade(
              firstChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NodeWidget(
                    node: node,
                    rowExtent: rowExtent,
                    controller: controller,
                    itemBuilder: itemBuilder,
                    spacing: spacing,
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: rowExtent),
                    child: NodeList(
                      nodes: node.children,
                      controller: controller,
                      spacing: spacing,
                      rowExtent: rowExtent,
                      itemBuilder: itemBuilder,
                      animationDuration: animationDuration,
                    ),
                  ),
                ],
              ),
              secondChild: NodeWidget(
                node: node,
                rowExtent: rowExtent,
                controller: controller,
                itemBuilder: itemBuilder,
                spacing: spacing,
              ),
              crossFadeState:
                  node.expanded && !node.isBeingDragged
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
              duration: animationDuration,
            ),
        ],
      ),
    );
  }
}

class NodeWidget extends StatefulWidget {
  const NodeWidget({
    super.key,
    required this.node,
    required this.controller,
    required this.spacing,
    required this.rowExtent,
    required this.itemBuilder,
  });

  final TreeNode node;
  final TreeController controller;
  final double spacing;
  final double rowExtent;
  final Widget Function(BuildContext context, TreeNode node) itemBuilder;

  @override
  State<NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget>
    implements WidgetPositionProvider {
  bool isBeingDragged = false;
  bool indentIndicator = false;

  @override
  void initState() {
    super.initState();
    widget.node.registerPositionProvider(this);
  }

  @override
  void didUpdateWidget(covariant NodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node == widget.node) return;
    oldWidget.node.deRegisterPositionProvider();
    widget.node.registerPositionProvider(this);
  }

  @override
  void dispose() {
    widget.node.deRegisterPositionProvider();
    super.dispose();
  }

  ///the offset of the visual center of the widget
  @override
  Offset? getGlobalOffset() {
    final renderObj = context.findRenderObject() as RenderBox;
    return renderObj.localToGlobal(Offset.zero);
  }

  ///the visual size of the widget
  @override
  Size? getObjectSize() {
    final renderObj = context.findRenderObject() as RenderBox;
    return renderObj.size;
  }

  bool shouldAddAsChild(DragTargetDetails<TreeNode> details) {
    final offset = getGlobalOffset();
    final size = getObjectSize();

    return details.offset.dx > offset!.dx + size!.width / 3;
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<TreeNode>(
      onAcceptWithDetails: (details) {
        widget.controller.remove(details.data, notify: false);
        if (shouldAddAsChild(details)) {
          widget.node.attachChild(details.data, index: 0);
        } else {
          widget.node.attachSibling(details.data);
        }
      },
      onMove: (details) {
        if (shouldAddAsChild(details)) {
          if (!indentIndicator) {
            indentIndicator = true;
            setState(() {});
          }
        } else {
          if (indentIndicator) {
            indentIndicator = false;
            setState(() {});
          }
        }
      },
      builder: (context, candidate, _) {
        return candidate.isEmpty && !isBeingDragged
            ? Draggable(
              data: widget.node,
              onDragStarted: () {
                widget.node.collapse();
                widget.node.isBeingDragged = true;
                isBeingDragged = true;
                if (mounted) setState(() {});
              },
              onDragEnd: (details) {
                widget.node.isBeingDragged = false;
                isBeingDragged = false;
                if (mounted) setState(() {});
              },
              onDraggableCanceled: (velocity, offset) {
                widget.node.isBeingDragged = false;
                isBeingDragged = false;
                if (mounted) setState(() {});
              },
              onDragCompleted: () {
                widget.node.isBeingDragged = false;
                isBeingDragged = false;
                if (mounted) setState(() {});
              },
              feedback: SizedBox(
                width: 700,
                child: widget.itemBuilder(context, widget.node),
              ),
              child:
                  isBeingDragged
                      ? SizedBox()
                      : widget.itemBuilder(context, widget.node),
            )
            : isBeingDragged
            ? SizedBox()
            : Column(
              mainAxisSize: MainAxisSize.min,
              spacing: widget.spacing,
              children: [
                widget.itemBuilder(context, widget.node),
                Padding(
                  padding:
                      indentIndicator
                          ? EdgeInsets.only(left: widget.rowExtent)
                          : EdgeInsets.zero,
                  child: Material(
                    color: Colors.grey,
                    child: SizedBox(width: double.infinity, height: 15),
                  ),
                ),
              ],
            );
      },
    );
  }
}

abstract interface class WidgetPositionProvider {
  Offset? getGlobalOffset();

  Size? getObjectSize();
}
