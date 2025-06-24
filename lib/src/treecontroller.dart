part of 'treeview.dart';

class TreeController extends ChangeNotifier {
  TreeController({
    required List<TreeNode> initialNodes,

    ///A callback to preform sideeffects (I.E. Sync with a remote database) when a child is added to a node
    void Function(TreeNode parent, TreeNode child)? onChildAttached,

    ///A callback to preform sideeffects (I.E. Sync with a remote database) when a child is removed from a node
    void Function(TreeNode parent, TreeNode child)? onChildRemoved,

    ///A callback to preform sideeffects (I.E. Sync with a remote database) when a root in the tree is added
    void Function(TreeNode node)? onRootAdded,

    ///A callback to preform sideeffects (I.E. Sync with a remote database) when a root in the tree is removed
    void Function(TreeNode node)? onRootRemoved,
  }) : _onChildAttached = onChildAttached,
       _onChildRemoved = onChildRemoved,
       _onRootAdded = onRootAdded,
       _onRootRemoved = onRootRemoved,
       _rootNodes = initialNodes {
    _initToDict(null, _rootNodes);
  }

  ///Flatly maps the [_rootNodes] to the [_nodeDict]
  void _initToDict(TreeNode? parent, List<TreeNode> nodes) {
    for (final node in nodes) {
      _initToDict(node, node.children);
      node.parent = parent;
      node._controller = this;
      _nodeDict[node.identifier] = node;
    }
  }

  final void Function(TreeNode parent, TreeNode child)? _onChildAttached;

  final void Function(TreeNode parent, TreeNode child)? _onChildRemoved;

  final void Function(TreeNode node)? _onRootAdded;

  final void Function(TreeNode node)? _onRootRemoved;

  int get rootCount => _rootNodes.length;

  final List<TreeNode> _rootNodes;
  final _nodeDict = HashMap<Object, TreeNode>();

  void _notifyListeners() {
    notifyListeners();
  }

  void swap(TreeNode node1, TreeNode node2) {
    node1.parent!.children
      ..remove(node1)
      ..add(node2);
    node2.parent!.children
      ..remove(node2)
      ..add(node1);
    notifyListeners();
  }

  void swapByIdentifier(Object identifier1, Object identifier2) {
    final node1 = _nodeDict[identifier1];
    final node2 = _nodeDict[identifier2];
    assert(
      node1 != null && node2 != null,
      'No nodes registered with these identifiers',
    );
    swap(node1!, node2!);
  }

  void move(TreeNode node, TreeNode? newParent) {
    if (newParent == null) {
      _rootNodes.add(node);
    } else {
      newParent.children.add(node);
    }

    notifyListeners();
  }

  void remove(TreeNode node) {
    if (node.parent == null) {
      _rootNodes.remove(node);
      if (_onRootRemoved != null) _onRootRemoved(node);
      notifyListeners();
      return;
    }
    node.parent?.children.remove(node);
    _nodeDict.remove(node.identifier);
    if (_onChildRemoved != null) _onChildRemoved(node.parent!, node);
    notifyListeners();
  }

  void removeByIdentifier(Object identifier) {
    final node = _nodeDict[identifier];
    assert(node != null, 'No node registered with this identifier');
    remove(node!);
    notifyListeners();
  }

  void addRoot(TreeNode node) {
    _rootNodes.add(node);
    node._controller = this;
    _nodeDict[node.identifier] = node;
    if (_onRootAdded != null) _onRootAdded(node);
    notifyListeners();
  }

  TreeNode getByIdentifier(Object identifier) {
    final node = _nodeDict[identifier];
    assert(node != null, 'No node registered with this identifier');
    return node!;
  }
}

class TreeNode<T extends Object?> {
  TreeNode(
    this.identifier,
    this.data, {
    this.children = const [],
    this.expanded = true,
  });

  final Object identifier;
  T data;

  bool expanded;

  List<TreeNode> children;
  TreeNode? parent;
  TreeController? _controller;

  void attachChild<U>(TreeNode<U> child) {
    assert(
      _controller != null,
      'Cannot attach nodes to eachother if they are not in a tree controller',
    );
    children = [...children, child];
    child.parent = this;
    child._controller = _controller;
    if (_controller!._onChildAttached != null) {
      _controller!._onChildAttached!(this, child);
    }
    _controller!._nodeDict[identifier] = this;
    _controller!._notifyListeners();
  }

  void expand() {
    assert(
      _controller != null,
      'Cannot expand nodes to if they are not in a tree controller',
    );
    expanded = true;

    _controller!._notifyListeners();
  }

  void collapse() {
    assert(
      _controller != null,
      'Cannot collapse nodes if they are not in a tree controller',
    );
    expanded = false;

    _controller!._notifyListeners();
  }

  void toggle() {
    assert(
      _controller != null,
      'Cannot toggle nodes if they are not in a tree controller',
    );
    expanded = !expanded;
    _controller!._notifyListeners();
  }
}
