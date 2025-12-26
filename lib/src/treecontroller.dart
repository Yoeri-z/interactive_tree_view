import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';

///A controller that manages a tree consisting of many treenodes.
///Exposes methods to: get, attach, move, delete or modify nodes.
class TreeController extends ChangeNotifier {
  final void Function(TreeNode node, TreeNode? parent)? _onAttached;

  final void Function(TreeNode node, TreeNode? parent)? _onRemoved;

  final void Function()? _onChanged;

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

  ///Wraps a Tree and exposes methods to control or read certain aspects of this tree.
  TreeController({
    ///The tree this controller will contain at its construction
    required List<TreeNode> initialNodes,

    ///A callback to preform sideeffects when a child is added to a node
    void Function(TreeNode node, TreeNode? parent)? onAttached,

    ///A callback to preform sideeffects when a child is removed from a node
    void Function(TreeNode node, TreeNode? parent)? onRemoved,

    ///A callback to perform sideeffect when tree configuration changes.
    ///This will be called only once if the tree changes, instead of being called for every node that changes.
    void Function()? onChanged,

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
       _onChanged = onChanged,
       rootNodes = initialNodes {
    _initToDict(null, rootNodes, 0);
  }

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

    if (_onChanged != null) {
      _onChanged();
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

      if (_onChanged != null) {
        _onChanged();
      }

      if (notify) notifyListeners();
    } else {
      final oldParent = node.parent;
      final oldSiblings = node.siblings;
      final oldIndex = node.index;
      oldSiblings.remove(node);

      node._parent = newParent;

      //if the node is attached as root, depth will be 0
      node.depth = (newParent?.depth ?? -1) + 1;

      newSiblings.insert(index, node);

      if (_onMoved != null) {
        // moved node
        _onMoved(node, index, oldParent, newParent);

        // siblings that shifted in the new parent
        for (final (subIndex, sibling)
            in newSiblings.sublist(index + 1).indexed) {
          _onMoved(
            sibling,
            subIndex + index + 1,
            sibling.parent,
            sibling.parent,
          );
        }

        // siblings that shifted in the old parent
        for (final (subIndex, sibling)
            in oldSiblings.sublist(oldIndex).indexed) {
          _onMoved(
            sibling,
            subIndex + oldIndex,
            sibling.parent,
            sibling.parent,
          );
        }
      }

      if (_onChanged != null) {
        _onChanged();
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

    if (_onChanged != null) {
      _onChanged();
    }
    if (notify) notifyListeners();
  }

  ///Add a node to the root of this tree
  void attachRoot(TreeNode node, {bool notify = true}) {
    rootNodes.add(node);
    node._attach(this);

    if (_onAttached != null) _onAttached(node, null);
    if (_onChanged != null) {
      _onChanged();
    }
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

  ///Traverses all the nodes attached to the tree depth first. Calling back [action] on each node hit.
  void traverse(void Function(TreeNode) action) {
    for (final node in rootNodes) {
      node.traverse(action);
    }
  }

  ///Returns all the nodes attached to this tree in a flat list. The nodes are sorted in no particular order.
  List<TreeNode> flatList() {
    return _nodeMap.values.toList();
  }

  ///Computes a list with all the nodes by traversing them depth first.
  ///
  ///This method is more expensive than [flatList] but the nodes will have a reliable order.
  List<TreeNode> traversedFlatList() {
    final nodes = <TreeNode>[];

    traverse((node) => nodes.add(node));

    return nodes;
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

/// An element of a tree. A tree (managed by a controller) contains many nodes.
/// The nodes define the structure of the tree.
///
/// [identifier] should be unique for each node and is usually related to your [data].
/// If you have no idea what your identifier should be, you should probably use the [TreeNode.auto] constructor
/// to automatically assign the node an identifier.
class TreeNode<T extends Object?> {
  /// Create a [TreeNode].
  TreeNode(
    this.identifier,
    this.data, {
    this.draggable = true,
    List<TreeNode>? children,
    this.expanded = true,
  }) {
    this.children = children ?? List.empty(growable: true);

    for (final child in this.children) {
      child._parent = this;
    }
  }

  /// Create a [TreeNode] with an automatically assigned unique identifier.
  TreeNode.auto(
    T data, {
    bool draggable = true,
    List<TreeNode>? children,
    bool expanded = true,
  }) : this(
         Object(),
         data,
         draggable: draggable,
         children: children,
         expanded: expanded,
       );

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

  ///Attach this node and all its descendants to a controller.
  void _attach(TreeController controller) {
    traverse((node) {
      if (node._controller != null && node._controller != controller) {
        node._controller!.remove(node);
      }
      node._controller = controller;
      node._controller!._nodeMap[node.identifier] = this;
    });
  }

  ///A method to attach a child to this node. Use this to attach new nodes to the tree.
  ///
  ///This method will throw if the node this method is called on is not in the tree controller.
  void attachChild<U>(TreeNode<U> child, {int? index, bool notify = true}) {
    assert(
      isAttached,
      'Cannot attach nodes to eachother if they are not in a tree controller',
    );

    children.insert(index ?? children.length, child);
    child._parent = this;
    child.depth = depth + 1;
    child._attach(_controller!);

    if (_controller!._onAttached != null) {
      _controller!._onAttached!(child, this);
    }

    if (_controller!._onChanged != null) {
      _controller!._onChanged!();
    }

    if (notify) _controller!._notifyListeners();
  }

  ///Adds a sibling next to [this] node or at [index] if it is specified.
  ///Use this to attach new nodes to the tree.
  ///
  ///This method will throw if the node this method is called on is not in the tree controller.
  void attachSibling<U>(TreeNode<U> node, {int? index, bool notify = true}) {
    assert(isAttached, '''
      Cannot attach a node to a node that is not attached
      ''');

    final insertIndex = index ?? this.index + 1;
    siblings.insert(insertIndex, node);
    node._parent = parent;
    node.depth = depth;
    node._attach(_controller!);

    if (_controller!._onAttached != null) {
      _controller!._onAttached!(node, parent);
    }

    if (_controller!._onMoved != null && insertIndex + 1 < siblings.length) {
      for (final (i, sibling) in siblings.sublist(insertIndex + 1).indexed) {
        _controller!._onMoved!(sibling, insertIndex + 1 + i, parent, parent);
      }
    }

    if (_controller!._onChanged != null) {
      _controller!._onChanged!();
    }

    if (notify) _controller!._notifyListeners();
  }

  ///Replace this node by another node
  void replaceWith(TreeNode other, {bool notify = true}) {
    assert(isAttached, 'Can not replace a node that is not attached');
    final controller = _controller!;
    other._parent = parent;
    other.depth = depth;
    final insertIndex = index;
    final insertSiblings = siblings;
    controller.remove(this);
    insertSiblings.insert(insertIndex, other);
    other._attach(_controller!);

    _parent = null;

    if (_controller!._onAttached != null) {
      _controller!._onAttached!(other, other.parent);
    }
    if (_controller?._onChanged != null) {
      _controller!._onChanged!();
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

    if (_controller!._onChanged != null) {
      _controller!._onChanged!();
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

    if (_controller!._onChanged != null) {
      _controller!._onChanged!();
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
