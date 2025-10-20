## 0.10.1
 - Added `allowPlacement` method to the `TreeView` widget

## 0.10.0
 - Made attachments cascade through the children of an attached node.
 - changed `addRoot` to `attachRoot` for naming consistency
 - Fixed a bug where onAttached was called before the node was fully attached.
 - Made the remove method cascade, so now all descendants of the node will also be fed to the onRemoved callback.
 - Made the remove method also call the moved callback for potentially displaced siblings
 - Made it so nodes can be dragged in from outside the tree as long as they are TreeNodes, this will call the onAttached callback
 - Added new onChanged callback to controller.
 - Added replaceWith method to `TreeNode`
 - Removed the requirement for the attached node to be not attached.
 - Added `StaticTreeView` widget
 - made internal file structure change
 - Added the option to drag nodes as a child of an empty node, by hovering over the far right of it.
 - Added child option to placement enum

## 0.9.1
 - Updated Documentation.
 - Made internal changes for performance.

## 0.9.0

 - First release to pub.
