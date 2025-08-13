import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_tree_view/interactive_tree_view.dart';

void main() {
  group('TreeController & TreeNode', () {
    late TreeNode<String> root1;
    late TreeNode<String> root2;
    late TreeNode<String> child1;
    late TreeNode<String> child2;
    late TreeController controller;
    late List<String> events;

    setUp(() {
      events = [];
      child1 = TreeNode('c1', 'child1');
      child2 = TreeNode('c2', 'child2');
      root1 = TreeNode('r1', 'root1', children: [child1, child2]);
      root2 = TreeNode('r2', 'root2');
      controller = TreeController(
        initialNodes: [root1, root2],
        onAttached:
            (n, p) => events.add(
              'attached:${n.identifier} to ${p?.identifier ?? 'root'}',
            ),
        onRemoved:
            (n, p) => events.add(
              'removed:${n.identifier} from ${p?.identifier ?? 'root'}',
            ),
        onMoved: (n, i, op, np) => events.add('moved:${n.identifier} to $i'),
      );
    });

    test('attach child', () {
      final child = TreeNode('c3', 'child');

      expect(child.isAttached, false);

      root2.attachChild(child);

      expect(child.isAttached, true);
      expect(child.parent, root2);
      expect(root2.children.contains(child), true);
      expect(events.contains('attached:c3 to r2'), true);
      expect(controller.getByIdentifier('c3'), child);
    });

    test('attach sibling in root', () {
      final newSib = TreeNode('r3', 'root 3');

      expect(newSib.isAttached, false);

      root1.attachSibling(newSib);

      expect(newSib.isAttached, true);
      expect(controller.rootNodes.contains(newSib), true);
      expect(newSib.parent, null);
      expect(newSib.index, 1);
      expect(events.contains('attached:r3 to root'), true);
      expect(events.contains('moved:r2 to 2'), true);
      expect(controller.getByIdentifier('r3'), newSib);
    });

    test('attach sibling in node', () {
      final newSib = TreeNode('c3', 'child 3');

      expect(newSib.isAttached, false);

      child1.attachSibling(newSib);

      expect(newSib.isAttached, true);
      expect(child1.siblings.contains(newSib), true);
      expect(newSib.parent, child1.parent);
      expect(newSib.index, 1);
      expect(events.contains('attached:c3 to r1'), true);
      expect(events.contains('moved:c2 to 2'), true);
      expect(controller.getByIdentifier('c3'), newSib);
    });

    test('swap inside same nested parent', () {
      controller.swap(child1, child2);

      expect(root1.children.first, child2);
      expect(root1.children.last, child1);
      expect(events.any((e) => e == 'moved:c1 to 1'), true);
      expect(events.any((e) => e == 'moved:c2 to 0'), true);
    });

    test('swap across nested parents', () {
      final child3 = TreeNode('c3', 'child3');
      root2.attachChild(child3);
      controller.swap(child1, child3);
      expect(child3.parent, root1);
      expect(child1.parent, root2);
      expect(root1.children.contains(child3), true);
      expect(root2.children.contains(child1), true);
      expect(events.any((e) => e.startsWith('moved:c1')), true);
      expect(events.any((e) => e.startsWith('moved:c3')), true);
    });

    test('move inside same nested parent', () {
      controller.move(child2, 0, newParent: root1);
      expect(root1.children.first, child2);
      expect(events.contains('moved:c2 to 0'), true);
      expect(events.contains('moved:c1 to 1'), true);
    });

    test('move up inside same nested parent with many children', () {
      final child3 = TreeNode('c3', 'child3');
      final child4 = TreeNode('c4', 'child4');

      root1
        ..attachChild(child3)
        ..attachChild(child4);

      controller.move(child4, 0, newParent: root1);
      expect(root1.children.first, child4);
      expect(events.contains('moved:c4 to 0'), true);
      expect(events.contains('moved:c1 to 1'), true);
      expect(events.contains('moved:c2 to 2'), true);
      expect(events.contains('moved:c3 to 3'), true);
    });

    test('move up inside same nested parent with many children', () {
      final child3 = TreeNode('c3', 'child3');
      final child4 = TreeNode('c4', 'child4');

      root1
        ..attachChild(child3)
        ..attachChild(child4);

      controller.move(child1, 4, newParent: root1);
      expect(root1.children.last, child1);
      expect(events.contains('moved:c2 to 0'), true);
      expect(events.contains('moved:c3 to 1'), true);
      expect(events.contains('moved:c4 to 2'), true);
      expect(events.contains('moved:c1 to 3'), true);
    });

    test('move to different nested parent', () {
      controller.move(root2, 0, newParent: root1);

      expect(controller.rootNodes.contains(root2), false);
      expect(root1.children.contains(root2), true);
      expect(events.contains('moved:r2 to 0'), true);
      expect(events.contains('moved:c1 to 1'), true);
      expect(events.contains('moved:c2 to 2'), true);
    });

    test('remove nested node', () {
      controller.remove(child1);
      expect(child1.isAttached, false);
      expect(events.contains('removed:c1 from r1'), true);
      expect(root1.children.contains(child1), false);
    });

    test('moveUp/moveDown', () {
      child2.moveUp();
      expect(root1.children.first, child2);
      expect(events.any((e) => e == 'moved:c2 to 0'), true);
      expect(events.any((e) => e == 'moved:c1 to 1'), true);

      child2.moveDown();
      expect(root1.children.last, child2);
      expect(events.any((e) => e == 'moved:c2 to 1'), true);
      expect(events.any((e) => e == 'moved:c1 to 0'), true);
    });

    test('expand/collapse/toggle on nested node', () {
      child1.expanded = false;
      child1.expand();
      expect(child1.expanded, true);

      child1.collapse();
      expect(child1.expanded, false);

      child1.toggle();
      expect(child1.expanded, true);

      // No callback expected here since expand/collapse/toggle are UI-only
      expect(events.isEmpty, true);
    });
    test('traverse on controller hits each node', () {
      final nodes = [];
      controller.traverse((node) => nodes.add(node.identifier));

      expect(nodes.length, 4);
      expect(['r1', 'r2', 'c1', 'c2'].every(nodes.contains), true);
    });

    test('traverse on node hits the node and its descendants', () {
      final nodes = [];
      root1.traverse((node) => nodes.add(node.identifier));

      expect(nodes.length, 3);
      expect(['r1', 'c1', 'c2'].every(nodes.contains), true);
    });

    test('expand and collapse all', () {
      //by default nodes are all expanded so we start with collapse.
      controller.collapseAll();

      controller.traverse((node) => expect(node.expanded, false));

      controller.expandAll();

      controller.traverse((node) => expect(node.expanded, true));
    });
  });

  group('TreeView widget', () {
    late TreeNode<String> root1;
    late TreeNode<String> root2;
    late TreeNode<String> child1;
    late TreeNode<String> child2;
    late TreeController controller;
    late List<String> events;

    late Finder root1Finder;
    late Finder root2Finder;
    late Finder child1Finder;
    late Finder child2Finder;

    setUp(() {
      events = [];
      child1 = TreeNode('c1', 'child1');
      child2 = TreeNode('c2', 'child2');
      root1 = TreeNode('r1', 'root1', children: [child1, child2]);
      root2 = TreeNode('r2', 'root2');

      root1Finder = find.byKey(ValueKey('${root1.identifier}_test'));
      root2Finder = find.byKey(ValueKey('${root1.identifier}_test'));
      child1Finder = find.byKey(ValueKey('${child1.identifier}_test'));
      child2Finder = find.byKey(ValueKey('${child2.identifier}_test'));

      controller = TreeController(
        initialNodes: [root1, root2],
        onAttached:
            (n, p) => events.add(
              'attached:${n.identifier} to ${p?.identifier ?? 'root'}',
            ),
        onRemoved:
            (n, p) => events.add(
              'removed:${n.identifier} from ${p?.identifier ?? 'root'}',
            ),
        onMoved: (n, i, op, np) => events.add('moved:${n.identifier} to $i'),
      );
    });

    testWidgets('Treeview has 2 rootnodes and child nodes after expanding', (
      tester,
    ) async {
      await tester.pumpWidget(
        TestSetupWidget(
          child: TreeView(
            controller: controller,
            childExtent: 16,
            nodeBuilder:
                (context, node) => NodeWidget(
                  key: ValueKey('${node.identifier}_test'),
                  node: node,
                ),
          ),
        ),
      );

      expect(root1Finder, findsOneWidget);
      expect(root2Finder, findsOneWidget);
      expect(child1Finder, findsOneWidget);
      expect(child2Finder, findsOneWidget);

      root1.collapse();

      await tester.pumpAndSettle();

      expect(root1Finder, findsOneWidget);
      expect(root2Finder, findsOneWidget);
      expect(child1Finder, findsNothing);
      expect(child2Finder, findsNothing);

      root1.expand();

      await tester.pumpAndSettle();
      expect(root1Finder, findsOneWidget);
      expect(root2Finder, findsOneWidget);
      expect(child1Finder, findsOneWidget);
      expect(child2Finder, findsOneWidget);
    });

    testWidgets('Child nodes are indented', (tester) async {
      await tester.pumpWidget(
        TestSetupWidget(
          child: TreeView(
            controller: controller,
            childExtent: 16,
            nodeBuilder:
                (context, node) => NodeWidget(
                  key: ValueKey('${node.identifier}_test'),
                  node: node,
                ),
          ),
        ),
      );
      final root1Dx = tester.getTopLeft(root1Finder).dx;
      final child1Dx = tester.getTopLeft(child1Finder).dx;

      expect(child1Dx, equals(root1Dx + 16));
    });

    testWidgets('Dragging a node moves it', (tester) async {
      await tester.pumpWidget(
        TestSetupWidget(
          child: TreeView(
            controller: controller,
            childExtent: 16,
            nodeBuilder:
                (context, node) => NodeWidget(
                  key: ValueKey('${node.identifier}_test'),
                  node: node,
                ),
          ),
        ),
      );
      final movement =
          Offset(700, tester.getCenter(root2Finder).dy) -
          tester.getCenter(child1Finder);

      await tester.dragFrom(tester.getTopLeft(child1Finder), movement);

      await tester.pumpAndSettle();

      expect(root2.children.first, child1);
    });
  });
}

class NodeWidget extends StatelessWidget {
  const NodeWidget({super.key, required this.node});

  final TreeNode node;

  @override
  Widget build(BuildContext context) {
    return Text(node.data!.toString());
  }
}

class TestSetupWidget extends StatelessWidget {
  const TestSetupWidget({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: SizedBox(width: 1000, child: child));
  }
}
