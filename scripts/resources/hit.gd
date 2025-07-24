extends Resource


var check_function: Callable


func check(argv: Array) -> Variant:
	return check_function.callv(argv)
