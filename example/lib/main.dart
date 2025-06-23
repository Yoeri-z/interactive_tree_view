import 'package:flutter/material.dart';
import 'package:treeview_draggable/treeview_draggable.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  final controller = TreeController(
    initialNodes: [
      TreeNode(
        1,
        'test 1',
        children: [TreeNode(3, 'test 3'), TreeNode(4, 'test 4')],
      ),
      TreeNode(2, 'test 2'),
    ],
  );

  void _onAdd(TreeNode parent) async {
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

    if (result != null) parent.attachChild(TreeNode(result, result));
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
          nodeItemBuilder:
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
                        IconButton(
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
          leafItemBuilder:
              (context, node) => Material(
                borderRadius: BorderRadius.circular(4),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
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
