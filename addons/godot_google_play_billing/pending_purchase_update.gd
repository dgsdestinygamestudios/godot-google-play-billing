class_name PendingPurchaseUpdate
extends RefCounted

var token: String = ""
var products: PackedStringArray = []

func deserialize(data: Dictionary) -> PendingPurchaseUpdate:
	if &"token" in data:
		token = data[&"token"]
	if &"products" in data:
		products = data[&"products"]
	return self
