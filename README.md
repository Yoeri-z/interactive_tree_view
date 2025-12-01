# Interactive tree view

A flutter library that aims to make it easier to deal with tree structures in both logic and UI.

## Example
![demo](https://github.com/user-attachments/assets/9d1bd2cf-daf1-4f03-87c2-6aa4f3c61453)

```dart
final uuid = Uuid();

class ExampleTreeView extends StatefulWidget {
  const ExampleTreeView({super.key, required this.title});
  final String title;

  @override
  State<ExampleTreeView> createState() => _ExampleTreeViewState();
}

class _ExampleTreeViewState extends State<ExampleTreeView> {
  final controller = TreeController(
    initialNodes: [
      TreeNode(
        uuid.v1(),
        'node 1',
        children: [
          TreeNode(uuid.v1(), 'node 3'),
          TreeNode(uuid.v1(), 'node 4'),
        ],
      ),
      TreeNode(uuid.v1(), 'node 2', children: [TreeNode(uuid.v1(), 'node 5')]),
    ],
    onAttached: (node, parent) {
      print('Attached node ${node.identifier}');
    },
    onMoved: (node, index, oldParent, newParent) {
      print('Moved node ${node.identifier} to index $index');
    },
    onRemoved: (node, parent) {
      print('Removed node ${node.identifier}');
    },
  );

  void _onAdd(TreeNode parent) async {
    // Show dialog to add a new node
  }

  @override
  Widget build(BuildContext context) {
    return TreeView(
      controller: controller,
      dragStartMode: DragStartMode.longPress,
      nodeBuilder: (context, node) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        height: 48,
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Text(node.data!.toString()),
            const Spacer(),
            IconButton(
              onPressed: () => _onAdd(node),
              icon: const Icon(Icons.add),
            ),
            IconButton(
              onPressed: () => controller.remove(node),
              icon: const Icon(Icons.remove),
            ),
            if (node.isParent)
              IconButton(
                onPressed: node.toggle,
                icon: Icon(
                  node.expanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

## Features

- Drag-and-drop nodes
- Configurable drag start mode (tap or long press)
- Expand / collapse animations
- Controller- and node-based updates
- Node lookup and manipulation via unique identifiers
- Event listeners for node changes through `TreeController`

## Key terms

- **Node** — an element in the tree.
  - **Parent node** — the node directly above a given node.
  - **Sibling node** — a node sharing the same parent.
  - **Child node** — a node directly under a given node.
  - **Root node** — a node without a parent (depth 0).
- **Depth** — number of steps from the node to a root node (root = 0).
- **Indicator** — UI element shown while dragging that indicates the drop position.

---

## `TreeController`

Manages nodes, their positions, and notifies listeners when changes occur.

**Important:** movement and relationship methods require the node to be attached to the controller.

### How nodes become attached

- Provided via `initialNodes` in the controller constructor.
- Added with `controller.attachRoot(...)`.
- Added with `node.attachChild(...)`.
- Added with `node.attachSibling(...)`.

### Constructor example
```dart
final controller = TreeController(
  initialNodes: [...],
  onAttached: (node, index, parent) {
    // called when a node is attached
    // node: attached node
    // index: position among siblings
    // parent: parent node or null if root
  },
  onMoved: (node, index, oldParent, newParent) {
    // called when an attached node is moved, directly or indirectly
  },
  onRemoved: (node, index, parent) {
    // called when a node is removed/detached
  },
  onChanged: (){
    // called when the tree configuration changes
    // this calls only once per change
  }
);
```

### methods
```dart
controller.getByIdentifier(id);
controller.addRoot(node);
controller.remove(node);
controller.move(node, index, newParent: parentNode);
controller.swap(node1, node2);
controller.traverse(action);
controller.collapseAll();
controller.expandAll();
```
For more details, see: [TreeController api reference](https://pub.dev/documentation/interactive_tree_view/latest/interactive_tree_view/TreeController-class.html)

---

## Tree nodes (`TreeNode`)

A `TreeNode` is an individual item. Construction alone does **not** attach it to a controller — attach it before using movement-related APIs.

### Constructor example
```dart
final node = TreeNode<String>(
  uuid.v1(),                 // unique identifier
  'Node data',               // payload
  children: [nodeA, nodeB], // optional children
  draggable: true,           // defaults to true
  expanded: true,            // defaults to true
);
```

### Properties
```dart
node.identifier;     // unique id
node.data;           // payload
node.children;       // list of children
node.parent;         // parent node (null for root)
node.siblings;       // sibling list (attached nodes only)
node.isParent;       // true when this node has children
node.isNotParent;    // inverse of isParent
node.depth;          // root depth = 0
node.expanded;       // whether this node is expanded
node.isBeingDragged; // true when the node is currently dragged
```

### Methods
```dart
node.attachChild(childNode);
node.attachSibling(siblingNode);
node.moveUp();
node.moveDown();
node.move(index, parent: parentNode);
//swap swaps the location of two nodes in the tree
node.swap(otherNode);
//replaceWith replaces a node with a new node instance
node.replaceWith(notAttachedNode);
node.expand();
node.collapse();
node.toggle();
node.traverse(action)
```
For more details, see: [TreeNode api reference](https://pub.dev/documentation/interactive_tree_view/latest/interactive_tree_view/TreeController-class.html)

---

## `TreeView` widget

Displays a tree from a `TreeController`.
### Constructor
```dart
TreeView(
  //Optionally configure the drag start mode
  dragStartMode: DragStartMode.tap,
  //Controller to build from.
  controller: controller,
  //Builder that is used for each node.
  nodeBuilder: (context, node) {},
  //UI element shown while dragging that indicates the drop position.
  indicator: const DefaultIndicator(height: 15),
  //A builder to use if you want an indicator that depends on the node that is used as reference for its placement. 
  indicatorBuilder: (context, referenceNode, placement) {},
  indent: 8.0, // horizontal indent per depth (default 8.0).
  spacing: 8.0, // vertical spacing between nodes
  //The duration of the animation.
  animationDuration: const Duration(milliseconds: 100),
);
```

Nodes in this tree can be dragged by the user to be placed somewhere else in the tree. To make a node a child of another node, drag it to the right side of that node until the indicator becomes indented.

## `StaticTreeView` widget
Displays a tree from a list of `TreeNodes`. 
Very similar to `TreeView`, but does not allow the user to modify the tree through the ui.
Takes a list of `TreeNode` instead of a `TreeController`.

## Misc.

There are no built-in selection or highlighting utilities because this is quite trivial to implement. See the [example](https://github.com/Yoeri-z/interactive_tree_view/blob/master/example/lib/main.dart) in the repository for a suggested implementation.

This widget was not built or tested for performance, until now i have not encountered any performance issues using the package.Performance could degrade when using very deep trees but since trees are not a very convenient way to display large datasets this is not an expected usecase.

---

