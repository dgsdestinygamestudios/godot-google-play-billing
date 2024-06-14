class_name Purchase
extends RefCounted

enum PurchaseState {
	PENDING = 2,
	PURCHASED = 1,
	UNSPECIFIED_STATE = 0
}

var token: String = ""
var original_json: String = ""
var package_name: String = ""
var order_id: String = ""
var developer_payload: String = ""
var signature: String = ""
var products: PackedStringArray = []
var state: PurchaseState = PurchaseState.UNSPECIFIED_STATE
var quantity: int = 0
var is_auto_renewing: bool = false
var is_acknowledged: bool = false
var account_identifiers: AccountIdentifiers = AccountIdentifiers.new()
var pending_purchase_update: PendingPurchaseUpdate = PendingPurchaseUpdate.new()

func deserialize(data: Dictionary) -> Purchase:
	if &"token" in data:
		token = data[&"token"]
	if &"original_json" in data:
		original_json = data[&"original_json"]
	if &"package_name" in data:
		package_name = data[&"package_name"]
	if &"order_id" in data:
		order_id = data[&"order_id"]
	if &"developer_payload" in data:
		developer_payload = data[&"developer_payload"]
	if &"signature" in data:
		signature = data[&"signature"]
	if &"products" in data:
		products = data[&"products"]
	if &"state" in data:
		state = data[&"state"]
	if &"quantity" in data:
		quantity = data[&"quantity"]
	if &"is_auto_renewing" in data:
		is_auto_renewing = data[&"is_auto_renewing"]
	if &"is_acknowledged" in data:
		is_acknowledged = data[&"is_acknowledged"]
	if &"account_identifiers" in data and data[&"account_identifiers"] is Dictionary and data[&"account_identifiers"] != null:
		account_identifiers = AccountIdentifiers.new().deserialize(data[&"account_identifiers"])
	if &"pending_purchase_update" in data and data[&"pending_purchase_update"] is Dictionary and data[&"pending_purchase_update"] != null:
		pending_purchase_update = PendingPurchaseUpdate.new().deserialize(data[&"pending_purchase_update"])
	return self
