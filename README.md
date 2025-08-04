# 🌳 A (not yet Draggale) TreeView

A simple and extensible TreeView widget for Flutter with support for dynamic updates, custom node rendering, and animations.

## Features

- Separate builders for leaf and branch nodes
- Automatic expand/collapse animations
- Controller and Node based updates
- Optionally manipulate nodes via unique identifiers

## 🧱 Example Usage

```dart
final controller = TreeController(
  initialNodes: [
    TreeNode('root', 'Root Node', children: [
      TreeNode('child1', 'Leaf Node 1'),
      TreeNode('child2', 'Leaf Node 2'),
    ]),
  ],
);

TreeView(
  controller: controller,
  itemBuilder: (context, node) => node.isLeaf ? 
    Text(node.data.toString()):
    ListTile(
      title: Text(node.data.toString()),
      onTap: node.toggle,
    ),
);
```

## 🧠 API Overview

### `TreeView`

| Property            | Description                                       |
|---------------------|---------------------------------------------------|
| `controller`        | Required. Manages the tree structure.             |
| `leafItemBuilder`   | Builder for nodes with no children.               |
| `nodeItemBuilder`   | Builder for nodes with children.                  |
| `rowExtent`         | Indentation for child nodes. Default: `8.0`.      |
| `spacing`           | Vertical spacing between nodes. Default: `8.0`.   |
| `animationDuration` | Optional expand/collapse animation duration.      |

### `TreeController`

- `addRoot(node)` : Add a node to the root of the list
- `remove(node)` / `removeByIdentifier(id)`
- `move(node, newParent)` : move a node to a new parent
- `swap(node1, node2)` / `swapByIdentifier(id1, id2)` : swap two nodes
- `getByIdentifier(id)` : get a node by its identifier

### `TreeNode`

- `identifier`: Unique ID (e.g., `String`, `int`)
- `data`: Custom payload
- `children`: List of child nodes
- `expanded`: Whether the node is expanded
- `attachChild(node)` : attach a child to the node
- `isLeaf` : a getter boolean that indicates wether the node is a leaf or not.
- Functions on the visual expansion of the node: `expand()`, `collapse()`, `toggle()`

All these methods will automatically update the treeview widgets attached to the controller.

## 📦 TODO
- Drag & drop support
- Lazy loading
- Selection & highlight callbacks

## 📄 License

MIT
