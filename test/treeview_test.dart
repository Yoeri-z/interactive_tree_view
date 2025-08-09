import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_tree_view/treeview_draggable.dart';

void main() {
  late TreeNode<String> root1;
  late TreeNode<String> root2;
  late TreeNode<String> child1;
  late TreeNode<String> child2;
  late TreeController controller;

  setUp(() {
    child1 = TreeNode('c1', 'child1');
    child2 = TreeNode('c2', 'child2');
    root1 = TreeNode('r1', 'root1', children: [child1, child2]);
    root2 = TreeNode('r2', 'root2');

    controller = TreeController(initialNodes: [root1, root2]);
  });
}
