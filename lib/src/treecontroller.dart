import 'dart:collection';

import 'package:flutter/material.dart';

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
       rootNodes = initialNodes {
    _initToDict(null, rootNodes);
  }

  ///Flatly maps the [rootNodes] to the [_nodeDict]
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

  int get rootCount => rootNodes.length;

  final List<TreeNode> rootNodes;
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
      rootNodes.add(node);
    } else {
      newParent.children.add(node);
    }

    notifyListeners();
  }

  void remove(TreeNode node) {
    if (node.parent == null) {
      rootNodes.remove(node);
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
    rootNodes.add(node);
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
  List<TreeNode> get siblings {
    assert(
      _controller != null,
      'Cannot find siblings if this node is not in a tree controller',
    );

    return parent == null ? _controller!.rootNodes : parent!.children;
  }

  TreeNode? parent;
  TreeController? _controller;

  bool get isLeaf => children.isEmpty;
  bool get isNode => children.isNotEmpty;

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

  void moveUp() {
    final index = siblings.indexOf(this);

    if (index <= 0) return;

    siblings[index] = siblings[index - 1];
    siblings[index - 1] = this;
  }

  void moveDown() {
    final index = siblings.indexOf(this);

    if (index == -1 || index == siblings.length - 1) return;

    siblings[index] = siblings[index + 1];
    siblings[index + 1] = this;
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

extension Swap<T> on List<T> {
  ///swaps two elements in the list
  ///If the list contains both objects this returns `True`.
  ///If the list did not contain both objects this returns `False`
  bool swap(T obj1, T obj2) {
    int indexObj1 = -1;
    int indexObj2 = -1;
    for (final (index, obj) in indexed) {
      if (obj1 == obj) {
        indexObj1 = index;
      }
      if (obj2 == obj) {
        indexObj2 == index;
      }
    }

    if (indexObj1 == -1 || indexObj2 == -1) {
      return false;
    }

    this[indexObj1] = obj2;
    this[indexObj2] = obj1;

    return true;
  }
}
