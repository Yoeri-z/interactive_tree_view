import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_tree_view/treeview_draggable.dart';

void main() {
  group('TreeController & TreeNode (nested)', () {
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

    test('attach child to nested node', () {
      final grandChild = TreeNode('gc1', 'grandChild');
      child1.attachChild(grandChild);
      expect(grandChild.parent, child1);
      expect(grandChild.isAttached, true);
      expect(events.contains('attached:gc1 to c1'), true);
      expect(controller.getByIdentifier('gc1'), grandChild);
      expect(child1.children.contains(grandChild), true);
    });

    test('attach sibling inside nested level', () {
      final newSib = TreeNode('ns1', 'nestedSib');
      child1.attachSibling(newSib);
      expect(child1.siblings, contains(newSib));
      expect(newSib.parent, child1.parent);
      expect(events.contains('attached:ns1 to r1'), true);
    });

    test('swap inside same nested parent', () {
      controller.swap(child1, child2);
      expect(root1.children.first, child2);
      expect(root1.children.last, child1);
      expect(events.any((e) => e.startsWith('moved:c1')), true);
    });

    test('swap across nested parents', () {
      root2.attachChild(TreeNode('c3', 'child3'));
      final c3 = controller.getByIdentifier('c3');
      controller.swap(child1, c3);
      expect(c3.parent, root1);
      expect(child1.parent, root2);
    });

    test('swapByIdentifier inside nested', () {
      controller.swapByIdentifier('c1', 'c2');
      expect(root1.children.first.identifier, 'c2');
    });

    test('move inside same nested parent', () {
      controller.move(child2, 0, newParent: root1);
      expect(root1.children.first, child2);
    });

    test('move to different nested parent', () {
      final newChild = TreeNode('nc', 'newChild');
      final oldParent = child1.parent;
      root2.attachChild(newChild);
      controller.move(child1, 0, newParent: newChild);
      if (oldParent != null) {
        expect(oldParent.children.contains(child1), false);
      }
      if (oldParent == null) {
        expect(controller.rootNodes.contains(child1), false);
      }
      expect(child1.parent, newChild);
      expect(newChild.children.length, 1);
    });

    test('remove nested node', () {
      controller.remove(child1);
      expect(child1.isAttached, false);
      expect(events.contains('removed:c1 from r1'), true);
      expect(root1.children.contains(child1), false);
    });

    test('removeByIdentifier nested', () {
      controller.removeByIdentifier('c2');
      expect(root1.children.any((n) => n.identifier == 'c2'), false);
    });

    test('moveUp/moveDown inside nested', () {
      child2.moveUp();
      expect(root1.children.first, child2);
      child2.moveDown();
      expect(root1.children.last, child2);
    });

    test('expand/collapse/toggle on nested node', () {
      child1.expanded = false;
      child1.expand();
      expect(child1.expanded, true);

      child1.collapse();
      expect(child1.expanded, false);

      child1.toggle();
      expect(child1.expanded, true);
    });
  });
}
