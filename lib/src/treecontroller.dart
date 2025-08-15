import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';

///Wraps a Tree and exposes methods to control or read certain aspects of this tree.
class TreeController extends ChangeNotifier {
  ///Wraps a Tree and exposes methods to control or read certain aspects of this tree.
  TreeController({
    ///The initial tree this controller will manage.
    required List<TreeNode> initialNodes,

    ///A callback to preform sideeffects when a child is added to a node
    void Function(TreeNode node, TreeNode? parent)? onAttached,

    ///A callback to preform sideeffects when a child is removed from a node
    void Function(TreeNode node, TreeNode? parent)? onRemoved,

    ///A callback to preform sideeffection when a node is moved to another location in the tree
    ///the position parameter is the position the node has in the array of siblings.
    ///
    ///equal to node.index
    void Function(
      TreeNode node,
      int position,
      TreeNode? oldParent,
      TreeNode? newParent,
    )?
    onMoved,
  }) : _onAttached = onAttached,
       _onRemoved = onRemoved,
       _onMoved = onMoved,
       rootNodes = initialNodes {
    _initToDict(null, rootNodes, 0);
  }

  final void Function(TreeNode node, TreeNode? parent)? _onAttached;

  final void Function(TreeNode node, TreeNode? parent)? _onRemoved;

  final void Function(
    TreeNode node,
    int position,
    TreeNode? oldParent,
    TreeNode? newParent,
  )?
  _onMoved;

  ///The number of rootnodes in the tree.
  int get rootCount => rootNodes.length;

  ///The rootnodes of this tree.
  final List<TreeNode> rootNodes;
  final _nodeMap = HashMap<Object, TreeNode>();

  ///Flatly maps the [rootNodes] to the [_nodeMap]
  void _initToDict(TreeNode? parent, List<TreeNode> nodes, int depth) {
    for (final node in nodes) {
      node._parent = parent;
      node._controller = this;
      _nodeMap[node.identifier] = node;
      node.depth = depth;
      _initToDict(node, node.children, depth + 1);
    }
  }

  void _notifyListeners() {
    notifyListeners();
  }

  ///Swap two nodes in the tree. This moves [node1] to the position of [node2] and [node2] to the position of [node1].
  ///
  ///This method will throw if [node1] and [node2] are not attached to the tree.
  void swap(TreeNode node1, TreeNode node2, {bool notify = true}) {
    assert(node1.isAttached && node2.isAttached, '''
      Nodes must be attached in order for it to be able to be moved
      ''');

    final node1Siblings = node1.siblings;
    final node2Siblings = node2.siblings;
    final node1Index = node1.index;
    final node2Index = node2.index;
    final node1Parent = node1.parent;
    final node2Parent = node2.parent;

    node1Siblings.remove(node1);
    node1Siblings.insert(node1Index, node2);
    node2Siblings.remove(node2);
    node2Siblings.insert(node2Index, node1);

    node1._parent = node2Parent;
    node2._parent = node1Parent;

    if (_onMoved != null) {
      _onMoved(node1, node2Index, node1Parent, node2Parent);
      _onMoved(node2, node1Index, node2Parent, node1Parent);
    }

    if (notify) notifyListeners();
  }

  ///Move a node to a new position in the tree, takes the following arguments:
  /// - node: the node to be moved
  /// - index: the position the new node should be inserted at among its new siblings
  /// - (optional) newParent: the new parent for this node, if null the node will be inserted in the root of the tree
  ///
  /// Index must be valid or this method will throw.
  /// The node must also be attached to the tree controller.
  void move(
    TreeNode node,
    int index, {
    TreeNode? newParent,
    bool notify = true,
  }) {
    assert(node.isAttached, '''
      Node must be attached in order for it to be able to be moved
      ''');

    assert(index >= 0, 'Index must be greater than 0');
    if (newParent != null) {
      assert(
        index <= newParent.children.length,
        'Index must be within bounds 0 <= index <= new sibling array length',
      );
    }
    if (newParent == null) {
      assert(
        index <= rootCount,
        'Index must be within bounds 0 <= index <= new sibling array length',
      );
    }

    final newSiblings = newParent?.children ?? rootNodes;

    if (node.siblings == newSiblings) {
      final oldIndex = newSiblings.indexOf(node);

      if (oldIndex == index) return;

      var targetIndex = index;

      if (oldIndex < index) {
        targetIndex--;
      }

      newSiblings.removeAt(oldIndex);
      newSiblings.insert(targetIndex, node);

      if (_onMoved != null) {
        for (
          var i = math.min(oldIndex, targetIndex);
          i <= math.max(oldIndex, targetIndex);
          i++
        ) {
          if (i < newSiblings.length) {
            _onMoved(newSiblings[i], i, node.parent, node.parent);
          }
        }
      }

      if (notify) notifyListeners();
    } else {
      final oldParent = node.parent;
      node.siblings.remove(node);

      node._parent = newParent;
      newSiblings.insert(index, node);

      if (_onMoved != null) {
        _onMoved(node, index, oldParent, newParent);
        for (final (subIndex, sibling)
            in newSiblings.sublist(index + 1).indexed) {
          _onMoved(
            sibling,
            subIndex + index + 1,
            sibling.parent,
            sibling.parent,
          );
        }
      }
      if (notify) notifyListeners();
    }
  }

  void _cascadeRemove(TreeNode node) {
    node.siblings.remove(node);
    final parent = node.parent;
    node._parent = null;
    _nodeMap.remove(node.identifier);
    node._controller == null;
    if (_onRemoved != null) _onRemoved(node, parent);
    for (final child in node.children.toList()) {
      _cascadeRemove(child);
    }
  }

  ///Remove a node from this tree
  ///
  ///Will throw if the node is not attached to the tree when the method is called
  void remove(TreeNode node, {bool notify = true}) {
    assert(node.isAttached, '''
      Node must be attached in order for it to be able to be removed
      ''');
    final oldIndex = node.index;
    final movedSiblings = node.siblings.sublist(oldIndex + 1);
    _cascadeRemove(node);
    if (_onMoved != null) {
      for (final (index, sibling) in movedSiblings.indexed) {
        _onMoved(sibling, oldIndex + index, sibling.parent, sibling.parent);
      }
    }

    if (notify) notifyListeners();
  }

  ///Add a node to the root of this tree
  ///
  ///If the node is already attached to the tree controller this method will throw.
  void addRoot(TreeNode node, {bool notify = true}) {
    assert(!node.isAttached, '''
      A node with this identifier is already attached to the tree.
      If you want to move a node use [move] instead. 
      You can get the node with this identifier by calling [getByIdentifier(identifier)]
      ''');

    rootNodes.add(node);
    node._controller = this;
    _nodeMap[node.identifier] = node;
    if (_onAttached != null) _onAttached(node, null);
    if (notify) notifyListeners();
  }

  ///Get a node registered in this controller by its identifier.
  ///
  ///will throw if no corresponding node is found, if you are unsure wether the node will be available use
  ///[maybeGetByIdentifier] instead
  TreeNode getByIdentifier(Object identifier, {bool notify = true}) {
    final node = _nodeMap[identifier];
    assert(node != null, 'No node registered with this identifier');
    return node!;
  }

  ///Get a node registered in this controller by its identifier.
  ///Returns null if no corresponding node is found.
  TreeNode? maybeGetByIdentifier(Object identifier) {
    final node = _nodeMap[identifier];
    return node;
  }

  ///Traverses all the nodes attached to the tree. Calling back [action] on each node hit.
  void traverse(void Function(TreeNode) action) {
    for (final node in _nodeMap.values) {
      action(node);
    }
  }

  ///Expands all nodes in the tree.
  void expandAll({bool notify = true}) {
    traverse((node) => node.expand(notify: false));
    if (notify) notifyListeners();
  }

  ///Collapses all nodes in the tree.
  void collapseAll({bool notify = true}) {
    traverse((node) => node.collapse(notify: false));
    if (notify) notifyListeners();
  }
}

///The representation of a single node in the tree
class TreeNode<T extends Object?> {
  ///The representation of a single node in the tree
  TreeNode(
    this.identifier,
    this.data, {
    this.draggable = true,
    List<TreeNode>? children,
    this.expanded = true,
  }) {
    this.children = children ?? List.empty(growable: true);
  }

  ///The identifier of this node.
  final Object identifier;

  ///A flag indicating if the node can be dragged.
  bool draggable;

  ///A flag indicating if the node is being dragged by the user.
  bool isBeingDragged = false;

  ///The depth of this node, starting at 0 depth for the rootnodes of the tree.
  int depth = 0;

  ///The data contained by this node.
  T data;

  ///A flag indicating if the node should be expanded in the ui.
  bool expanded;

  ///A flag indicating if this node is attached to a tree controller.
  bool get isAttached =>
      _controller != null && _controller!._nodeMap[identifier] != null;

  ///The children of this node
  late List<TreeNode> children;

  ///The siblings of this node
  List<TreeNode> get siblings {
    assert(
      isAttached,
      'Cannot find siblings if this node is not in a tree controller',
    );

    return parent == null ? _controller!.rootNodes : parent!.children;
  }

  ///The parent of this node
  TreeNode? get parent => _parent;

  TreeNode? _parent;
  TreeController? _controller;

  ///The index this node has in its sibling array
  int get index => siblings.indexOf(this);

  ///A flag indicating if this node is not a parent node (so a node with no child nodes)
  bool get isNotParent => children.isEmpty;

  ///A flag indicating if this node is a parent node (so a node with children)
  bool get isParent => children.isNotEmpty;

  ///A method to attach a child to this node. Use this to attach new nodes to the tree.
  ///
  ///This method will throw if the childnode is already in the tree or if the node this method is called on is not in the tree controller.
  void attachChild<U>(TreeNode<U> child, {int? index, bool notify = true}) {
    assert(
      isAttached,
      'Cannot attach nodes to eachother if they are not in a tree controller',
    );

    assert(!child.isAttached, '''
      A node with this identifier is already attached to the tree.
      If you want to move a node use [moveTo] instead. 
      You can get the node with this identifier by calling [getByIdentifier(identifier)] on the [TreeController]
      ''');

    children.insert(index ?? children.length, child);
    child._parent = this;
    child._controller = _controller;
    _controller!._nodeMap[child.identifier] = child;

    if (_controller!._onAttached != null) {
      _controller!._onAttached!(child, this);
    }
    if (notify) _controller!._notifyListeners();
  }

  ///Adds a sibling next to [this] node or at [index] if it is specified.
  ///Use this to attach new nodes to the tree.
  ///
  ///This method will throw if the node is already in the tree or if the node this method is called on is not in the tree controller.
  void attachSibling<U>(TreeNode<U> node, {int? index, bool notify = true}) {
    assert(
      _controller != null,
      'Cannot attach nodes to eachother if they are not in a tree controller',
    );
    assert(!node.isAttached, '''
      A node with this identifier is already attached to the tree.
      If you want to move a node use [moveTo] instead. 
      You can get the node with this identifier by calling [getByIdentifier(identifier)] on the [TreeController]
      ''');
    final insertIndex = index ?? this.index + 1;
    siblings.insert(insertIndex, node);
    node._parent = parent;
    node._controller = _controller;
    _controller!._nodeMap[node.identifier] = node;

    if (_controller!._onAttached != null) {
      _controller!._onAttached!(node, parent);
    }

    if (_controller!._onMoved != null && insertIndex + 1 < siblings.length) {
      for (final (i, sibling) in siblings.sublist(insertIndex + 1).indexed) {
        _controller!._onMoved!(sibling, insertIndex + 1 + i, parent, parent);
      }
    }
    if (notify) _controller!._notifyListeners();
  }

  ///Move this node to the [newParent] or the root of the tree if no [newParent] is supplied
  ///
  ///This method will throw if the node is not attached to a tree controller
  void move(int index, {TreeNode? newParent, bool notify = true}) {
    assert(
      isAttached,
      'Node must be attached to the tree in order for it to be moved',
    );

    _controller!.move(this, index, newParent: newParent);
  }

  ///Move this node up one spot with respect to its siblings.
  ///
  ///This method will throw if the node is not attached to a tree controller
  void moveUp({bool notify = true}) {
    assert(
      isAttached,
      'Node must be attached to the tree in order for it to be moved',
    );
    final index = siblings.indexOf(this);

    if (index <= 0) return;

    siblings[index] = siblings[index - 1];
    siblings[index - 1] = this;

    if (_controller!._onMoved != null) {
      _controller!._onMoved!(this, index - 1, parent, parent);
      _controller!._onMoved!(siblings[index], index, parent, parent);
    }

    if (notify) _controller!._notifyListeners();
  }

  ///Move this node down one spot with respect to its siblings.
  ///
  ///This method will throw if the node is not attached to a tree controller.
  void moveDown({bool notify = true}) {
    assert(
      _controller != null,
      'Cannot move nodes to if they are not in a tree controller',
    );
    assert(
      isAttached,
      'Node must be attached to the tree in order for it to be moved',
    );

    final index = siblings.indexOf(this);

    if (index == siblings.length - 1) return;

    siblings[index] = siblings[index + 1];
    siblings[index + 1] = this;

    if (_controller!._onMoved != null) {
      _controller!._onMoved!(this, index + 1, parent, parent);
      _controller!._onMoved!(siblings[index], index, parent, parent);
    }

    if (notify) _controller!._notifyListeners();
  }

  ///Expand this node in UI's.
  void expand({bool notify = true}) {
    assert(
      isAttached,
      'Cannot expand nodes if they are not in a tree controller',
    );
    if (expanded) return;

    expanded = true;
    if (notify) _controller!._notifyListeners();
  }

  ///Collapse this node in UI's.
  void collapse({bool notify = true}) {
    assert(
      _controller != null,
      'Cannot collapse nodes if they are not in a tree controller',
    );
    if (!expanded) return;

    expanded = false;
    if (notify) _controller!._notifyListeners();
  }

  ///Toggle the expansion of this node in UI's.
  void toggle({bool notify = true}) {
    assert(
      _controller != null,
      'Cannot toggle nodes if they are not in a tree controller',
    );
    expanded = !expanded;
    if (notify) _controller!._notifyListeners();
  }

  ///Travels this node and all its descendants. Calling back [action] on each node hit.
  void traverse(void Function(TreeNode node) action) {
    action(this);
    for (final child in children) {
      child.traverse(action);
    }
  }
}
