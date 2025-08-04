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
  void dispose() {
    widget.controller.removeListener(listener);
    super.dispose();
  }

  Widget expandedNodeBuilder(BuildContext context, List<TreeNode> nodes) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: widget.spacing / 2),
      child: Column(
        spacing: widget.spacing,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final node in nodes)
            if (node.children.isEmpty)
              widget.itemBuilder(context, node)
            else
              AnimatedCrossFade(
                firstChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    widget.itemBuilder(context, node),
                    Padding(
                      padding: EdgeInsets.only(left: widget.rowExtent),
                      child: expandedNodeBuilder(context, node.children),
                    ),
                  ],
                ),
                secondChild: widget.itemBuilder(context, node),
                crossFadeState:
                    node.expanded
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                duration:
                    widget.animationDuration ?? Duration(milliseconds: 150),
              ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: expandedNodeBuilder(context, widget.controller.rootNodes),
    );
  }
}
