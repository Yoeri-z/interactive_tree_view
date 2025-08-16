## 0.9.3
 - Fixed a bug where onAttached was called before the node was fully attached.
 - Made the remove method cascade, so now all descendants of the node will also be fed to the onRemoved callback.
 - Made the remove method also call the moved callback for potentially displaced siblings
 - Made it so nodes can be dragged in from outside the tree as long as they are TreeNodes, this will call the onAttached callback
 - Added new onChanged callback to controller.
## 0.9.2
 - Added the option to drag nodes as a child of an empty node, by hovering over the far right of it.
 - Added child option to placement enum

## 0.9.1
 - Updated Documentation.
 - Made internal changes for performance.

## 0.9.0

 - First release to pub.
