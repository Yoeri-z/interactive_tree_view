import 'package:flutter/material.dart';
import 'package:interactive_tree_view/interactive_tree_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Treeview Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'Tree View Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //create a controller to manage the nodes and to give to the TreeView widget.
  final controller = TreeController(
    initialNodes: [
      //Since our nodes dont come from a database they dont really have an id.
      //the auto constructor automatically assigns each new node a unique identifier.
      TreeNode.auto(
        //The payload of  this node
        'node 1',
        //the children of this node
        children: [TreeNode.auto('node 3'), TreeNode.auto('node 4')],
      ),
      TreeNode.auto('node 2', children: [TreeNode.auto('node 5')]),
      TreeNode.auto('node 6'),
    ],
    onAttached: (node, parent) {
      print('attached node ${node.data}');
      //Example usage: add node to remote database.
    },
    onMoved: (node, index, oldParent, newParent) {
      print('moved node ${node.data} to index $index');
      //Example usage: update node position and parent parameters in remote database.
    },
    onRemoved: (node, parent) {
      print('removed node ${node.data}');
      //Example usage: remove node from database
    },
  );

  TreeNode? selectedNode;

  //shows a dialog to add a new node, see the example on github for the full code
  void _onAdd(TreeNode parent) async {
    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        String textValue = '';
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add new node',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextField(onChanged: (value) => textValue = value),
                  TextButton(
                    onPressed: () => Navigator.pop(context, textValue),
                    child: Text('Add'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result != null) parent.attachChild(TreeNode.auto(result));
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
        child: TreeView(
          controller: controller,
          nodeBuilder:
              (context, node) => InkWell(
                onTap:
                    () => setState(() {
                      selectedNode = node;
                    }),
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        (selectedNode?.identifier == node.identifier)
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  height: 48,
                  width: double.infinity,
                  padding: EdgeInsets.all(8),
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
                      if (node.isParent)
                        IconButton(
                          //this toggles the expansion of the node
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
    );
  }
}
