import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:treeview_draggable/src/treeview.dart';

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
    _initToDict(null, rootNodes, 0);
  }

  ///Flatly maps the [rootNodes] to the [_nodeDict]
  void _initToDict(TreeNode? parent, List<TreeNode> nodes, int depth) {
    for (final node in nodes) {
      _initToDict(node, node.children, depth + 1);
      node.parent = parent;
      node._controller = this;
      _nodeDict[node.identifier] = node;
      node.depth = depth;
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

  void remove(TreeNode node, {bool notify = true}) {
    if (node.parent == null) {
      final removed = rootNodes.remove(node);
      if (_onRootRemoved != null && removed) _onRootRemoved(node);
      if (notify) notifyListeners();
      return;
    }
    final removed = node.parent!.children.remove(node);
    node.parent = null;
    _nodeDict.remove(node.identifier);
    if (_onChildRemoved != null && removed) _onChildRemoved(node.parent!, node);
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
    this.draggable = true,
    List<TreeNode>? children,
    this.expanded = true,
  }) {
    this.children = children ?? List.empty(growable: true);
  }

  final Object identifier;

  bool draggable;
  bool isBeingDragged = false;
  int depth = 0;
  T data;
  bool expanded;

  WidgetPositionProvider? _positionProvider;

  late List<TreeNode> children;

  List<TreeNode> get siblings {
    assert(
      _controller != null,
      'Cannot find siblings if this node is not in a tree controller',
    );

    return parent == null ? _controller!.rootNodes : parent!.children;
  }

  TreeNode? parent;
  TreeController? _controller;

  int get index => siblings.indexOf(this);
  bool get isLeaf => children.isEmpty;
  bool get isNode => children.isNotEmpty;

  void attachChild<U>(TreeNode<U> child, {int? index, bool notify = true}) {
    assert(
      _controller != null,
      'Cannot attach nodes to eachother if they are not in a tree controller',
    );
    children.insert(index ?? children.length, child);
    child.parent = this;
    child._controller = _controller;
    if (_controller!._onChildAttached != null) {
      _controller!._onChildAttached!(this, child);
    }
    _controller!._nodeDict[identifier] = this;
    if (notify) _controller!._notifyListeners();
  }

  ///Adds a sibling next to [this] node
  void attachSibling<U>(TreeNode<U> node) {
    assert(
      _controller != null,
      'Cannot attach nodes to eachother if they are not in a tree controller',
    );
    if (parent != null) {
      final thisIndex = parent!.children.indexOf(this);
      parent!.attachChild(node, index: thisIndex + 1);
    } else {
      _controller!.addRoot(node);
    }
  }

  void detachChild<U>(TreeNode<U> child, {bool notify = true}) {
    assert(
      _controller != null,
      'Cannot detach nodes if they are not in a tree controller',
    );
    _controller!.remove(child, notify: notify);
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

  void registerPositionProvider(WidgetPositionProvider provider) {
    _positionProvider = provider;
  }

  void deRegisterPositionProvider() {
    _positionProvider = null;
  }

  Offset? getNodeGlobalOffset() {
    return _positionProvider?.getGlobalOffset();
  }

  Size? getNodeSize() {
    return _positionProvider?.getObjectSize();
  }
}
