#
# a class with some static methods that have no relation to playsim and instead
# are just supplementary functions for godot itself.
#


static func reparent_or_add_child(child: Node, parent: Node) -> void:
	var f := parent.add_child.bind(child)

	if child.is_inside_tree():
		f = child.reparent.bind(parent)

	f.call_deferred()
