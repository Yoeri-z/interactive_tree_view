# Treeview Draggable

A simple and extensible TreeView widget for Flutter with support for dynamic updates, custom node rendering, and animations.

## Features

- Nodes in the tree are drag and droppable
- Automatic expand/collapse animations
- Controller and Node based updates
- Optionally manipulate nodes via unique identifiers
- Do side-effects based on node position changes using listeners exposed by the `TreeController`

## 🧱 Example Usage

```dart
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //define a controller
  final controller = TreeController(
    initialNodes: [
      TreeNode(
        //usually nodes will come from a database and thus have a unique id, for this example we use the
        //uuid package to simulate that.
        uuid4(),
        //This is the payload of the node
        'test 1',
        children: [TreeNode(uuid4(), 'test 3'), TreeNode(uuid4(), 'test 4')],
      ),
      TreeNode(uuid4(), 'test 2'),
    ],
    //when a child is attached somewhere this callback will be executed
    onChildAttached: (parent, child) {
      print('parent ${parent.data}');
      print('child ${child.data}');
    },
  );

  @override
  void dispose(){
    controller.dispose();
    super.dispose()
  }

  ///Call this to add a new child to a node
  void _onAdd(TreeNode parent) async {
    //quick dialog that returns a string for payload
    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        String textValue = '';
        return Dialog(
          child: Column(
            children: [
              TextField(onChanged: (value) => textValue = value),
              TextButton(
                onPressed: () => Navigator.pop(context, textValue),
                child: Text('Add'),
              ),
            ],
          ),
        );
      },
    );

    //create the treenode and attach it to the parent, the widget will automatically rebuild!
    if (result != null) parent.attachChild(TreeNode( uuid4(), result));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        //The TreeView widget allows us to display the tree inside the controller as a ui
        child: TreeView(
          controller: controller,
          itemBuilder:
              (context, node) => Material(
                borderRadius: BorderRadius.circular(4),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Text(node.data!.toString()),
                        Spacer(),
                        IconButton(
                          onPressed: () => _onAdd(node),
                          icon: Icon(Icons.add),
                        ),
                        IconButton(
                          onPressed: () => controller.remove(node),
                          icon: Icon(Icons.remove),
                        ),
                        if (node.isNode)
                          IconButton(
                            //this will toggle the extension of the node
                            onPressed: node.toggle,
                            icon: Icon(
                              node.expanded
                                  ? Icons.arrow_drop_up
                                  : Icons.arrow_drop_down,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
        ),
      ),
    );
  }
}
```

## API Overview

### `TreeView`

| Constructor Property| Description                                       |
|---------------------|---------------------------------------------------|
| `controller`        | Required. Manages the tree structure.             |
| `leafItemBuilder`   | Builder for nodes with no children.               |
| `nodeItemBuilder`   | Builder for nodes with children.                  |
| `rowExtent`         | Indentation for child nodes. Default: `8.0`.      |
| `spacing`           | Vertical spacing between nodes. Default: `8.0`.   |
| `animationDuration` | Optional expand/collapse animation duration.      |

### `TreeController`

```dart
final controller = TreeController(
  initialNodes: [
    TreeNode(
      1,
      'test 1',
      children: [TreeNode(3, 'test 3'), TreeNode(4, 'test 4')],
      ),
      TreeNode(2, 'test 2'),
    ],
    onChildAttached: (parent, child) {
      //do operations here when a node gets a (new) parent
    },
    onChildRemoved: (parent, child){
      //do operations here when a node gets removed from its parent
    }
    onRootAdded: (node){
      //do operations here when a node gets added as root to the tree (I.E. No parent node)
    }
    onRootRemoved: (node){
      //do operations here when a root node gets removed
    }
);

//methods:

//add a node to the root of the tree
controller.addRoot(node)
//remove a node from the tree (can be anywhere in the tree)
controller.remove(node)
//move a node to a new parent
controller.move(node, newParent)
//swap two nodes
controller.swap(node1, node2)
//get a node by identifier
final node = controller.getByIdentifier(identifier)
```

### `TreeNode`
```dart
///A node can be contructed as follows
final node = TreeNode(
  //a unique id
  'asdfieqv',
  //the payload of this node
  'This is an awesome node',
  //nodes that are a child to this node, can be null if the node has no child nodes
  children: [
    nodeA,
    nodeB,
    ...
  ]
  //wether this node can be dragged or not, defaults to true
  draggable: true
  //wether or not this node is expanded, defaults to true
  expanded: true
)

//Once a node is attached to a controller (see the ###controller section) you can use the following props and methods:
//the unique identifier of the node
final id =node.identifier;
//the data in the node
final data = node.data;
//the children of this node
final children = node.children;
//the parent of this node
final parent = node.parent;
//the siblings of this node
final siblings = node.siblings;
//the depth of this node (rootnodes are at 0 depth)
final depth = node.depth;
//wether or not this node is expanded
final expanded = node.expanded;
//wether or not the user is currently dragging this node
final dragging = node.isBeingDragged;

//methods:

//attach a child to this node
node.attachChild(childNode);
//attach a sibling, this will put a node next to the node the method is called on
node.attachSibling(node);
//Move the node up 1 spot if possible
node.moveUp();
//Move the node down 1 spot if possible
node.moveDown();
//Expand the node
node.expand();
//collapse the node
node.collapse();
//toggle the node
node.toggle();
//get a possible pixel offset of the displayed widget belonging to the node
//returns null if no widget is drawn
final offset = node.getNodeGlobalOffset();
//get a possible size for the displayed widget belonging to the node
//returns null if no widget is drawn
final size = node.getNodeSize();

```




All these methods will automatically update the treeview widgets attached to the controller.

## 📦 TODO before first release
- Clean Up
- Make node auto expand and collapse when hovered over
- Lazy loading
- Selection & highlight callbacks

## 📄 License

MIT
