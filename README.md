

# TreeView Draggable

A simple, extensible TreeView widget for Flutter with support for drag-and-drop, dynamic updates, custom node rendering, and animations.

## Example
![Gif](readme_assets/demo.gif)
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
- Added with `controller.addRoot(...)`.
- Added with `node.addChild(...)`.
- Added with `node.addSibling(...)`.

### Constructor example
```dart
final controller = TreeController(
  initialNodes: [...],
  onAttached: (node, index, parent) {
    // node: attached node
    // index: position among siblings
    // parent: parent node or null if root
  },
  onMoved: (node, index, oldParent, newParent) {
    // called when an attached node is moved
  },
  onRemoved: (node, index, parent) {
    // called when a node is removed/detached
  },
);
```

### methods
```dart
controller.getByIdentifier(id);
controller.addRoot(node);
controller.remove(node);
controller.move(node, index, newParent: parentNode);
controller.swap(node1, node2);
```

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
node.depth;          // 0 = root
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
node.swap(otherNode);
node.expand();
node.collapse();
node.toggle();
```

---

## `TreeView` widget

Displays a tree from a `TreeController`. Highly customizable — you can also build a custom UI by listening to the controller.

### Constructor
```dart
TreeView(
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

---

## Misc.

There are no built-in selection or highlighting utilities because this is quite trivial to implement. See the [example](https://github.com/Yoeri-z/interactive_tree_view/blob/master/example/lib/main.dart) in the repository for a suggested implementation.

This widget was not built or tested for performance, until now i have not encountered any performance issues using the package. Since nodes are lazily loaded (only loaded when they will be on screen) performance should be quite good in general.

---

