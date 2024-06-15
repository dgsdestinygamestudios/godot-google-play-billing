extends Node

enum ResponseCode {
	OK = 0,
	BILLING_UNAVAILABLE = 3,
	ERROR = 6,
	DEVELOPER_ERROR = 5,
	FEATURE_NOT_SUPPORTED = -2,
	ITEM_ALREADY_OWNED = 7,
	ITEM_UNAVAILABLE = 4,
	NETWORK_ERROR = 12,
	SERVICE_DISCONNECTED = -1,
	SERVICE_UNAVAILABLE = 2,
	USER_CANCELED = 1
}

enum ConnectionState {
	CLOSED = 3,
	CONNECTED = 2,
	CONNECTING = 1,
	DISCONNECTED = 0
}

const CONSUMABLE_ITEMS: PackedStringArray = []
const NON_CONSUMABLE_ITEMS: PackedStringArray = ["test_sku"]
const SUBSCRIPTION_ITEMS: PackedStringArray = ["test_sub"]
const LIBRARY_NAME: StringName = &"GodotGooglePlayBilling"

var _library: Object = null
var _consume: Array[Array] = []
var _product_details: Array[ProductDetails] = []
var _purchases: Array[Purchase] = []

func _ready() -> void:
	if not Engine.has_singleton(LIBRARY_NAME):
		print("[Billing]: Can not find library.")
		return
	print("[Billing]: Library found.")
	_library = Engine.get_singleton(LIBRARY_NAME)
	_connect_signals()
	_start_connection()

func purchase(product_id: String) -> void:
	var product_type: String = ""
	if product_id in CONSUMABLE_ITEMS or product_id in NON_CONSUMABLE_ITEMS:
		product_type = "inapp"
	elif product_id in SUBSCRIPTION_ITEMS:
		product_type = "subs"
	if product_type == "":
		print("[Billing]: %s is not valid!" % product_id)
		return
	print("[Billing]: Requesting purchasing %s." % product_id)
	_library.Purchase(product_id, product_type)

func _connect_signals() -> void:
	_library.connect(&"disconnected", _on_disconnected)
	_library.connect(&"resume", _on_resume)
	_library.connect(&"setup_finished", _on_setup_finished)
	_library.connect(&"purchases_updated", _on_purchases_updated)
	_library.connect(&"acknowledge_purchase_response", _on_acknowledge_purchase_response)
	_library.connect(&"consume_response", _on_consume_response)
	_library.connect(&"product_details_response", _on_product_details_response)
	_library.connect(&"query_purchases_response", _on_query_purchases_response)
	_library.connect(&"purchase_attempt", _on_purchase_attempt)

func _handle_purchase(purchase_token: String) -> void:
	print("[Billing]: Handling purchase!\n\tPurchase token: %s" % purchase_token)
	match purchase_token:
		"token":
			pass

func _handle_consume(purchase_token: String) -> void:
	print("[Billing]: Handling consume!\n\tPurchase token: %s" % purchase_token)
	var quantity: int = 0
	for i: int in range(_consume.size() - 1, 0, -1):
		if _consume[i][0] == purchase_token:
			quantity = _consume[i][1]
			_consume.remove_at(i)
			break
	match purchase_token:
		"token":
			pass # You can do something like `money += 1000 * quantity`

func _start_connection() -> void:
	print("[Billing]: Starting connection.")
	_library.StartConnection()

func _end_connection() -> void:
	print("[Billing]: Ending connection.")
	_library.EndConnection()

func _is_ready() -> bool:
	print("[Billing]: Returning is ready.")
	return _library.IsReady()

func _get_connection_state() -> ConnectionState:
	print("[Billing]: Returning connection state.")
	return _library.GetConnectionState()

func _acknowledge_purchase(purchase_token: String) -> void:
	print("[Billing]: Acknowledging purchase!\n\tPurchase Token: %s" % purchase_token)
	_library.AcknowledgePurchase(purchase_token)

func _query_purchases(product_type: String) -> void:
	print("[Billing]: Querying purchases!\n\tProduct Type: %s" % product_type)
	_library.QueryPurchases(product_type)

func _consume_purchase(purchase_token: String) -> void:
	print("[Billing]: Consuming!\n\tPurchase Token: %s" % purchase_token)
	_library.Consume(purchase_token)

func _query_product_details(product_ids: PackedStringArray, product_type: String) -> void:
	print("[Billing]: Querying product details!\n\tProduct IDs: %s\n\tProduct Type: %s" % [product_ids, product_type])
	_library.QueryProductDetails(product_ids, product_type)

func _on_disconnected() -> void:
	print("[Billing]: Disconnected!")
	_start_connection()

func _on_resume() -> void:
	if _get_connection_state() != ConnectionState.CONNECTED:
		print("[Billing]: Can not resume. Library is not connected!")
		return
	print("[Billing]: Resuming!")
	_purchases.clear()
	_query_purchases("inapp")
	_query_purchases("subs")

func _on_setup_finished(debug_message: String, response_code: ResponseCode) -> void:
	print("[Billing]: Setup finished!\n\tDebug Message: %s\n\tResponse Code: %s" % [debug_message, response_code])
	_product_details.clear()
	_query_product_details(CONSUMABLE_ITEMS, "inapp")
	_query_product_details(NON_CONSUMABLE_ITEMS, "inapp")
	_query_product_details(SUBSCRIPTION_ITEMS, "subs")
	_purchases.clear()
	_query_purchases("inapp")
	_query_purchases("subs")

func _on_purchases_updated(debug_message: String, response_code: ResponseCode, purchases: Array) -> void:
	print("[Billing]: Purchases updated!\n\tDebug Message: %s\n\tResponse Code: %s\n\tPurchases: %s" % [debug_message, response_code, purchases])
	for data: Dictionary in purchases:
		_purchases.append(Purchase.new().deserialize(data))
	for purchase: Purchase in _purchases:
		if purchase.is_acknowledged or purchase.state != purchase.PurchaseState.PURCHASED:
			continue
		if purchase.token in CONSUMABLE_ITEMS:
			_consume.append([purchase.token, purchase.quantity])
			_consume_purchase(purchase.token)
		elif purchase.token in NON_CONSUMABLE_ITEMS or purchase.token in SUBSCRIPTION_ITEMS:
			_acknowledge_purchase(purchase.token)

func _on_acknowledge_purchase_response(purchase_token: String, debug_message: String, response_code: ResponseCode) -> void:
	print("[Billing]: Acknowledge purchase response!\n\tDebug Message: %s\n\tResponse Code: %s" % [debug_message, response_code])
	if response_code != ResponseCode.OK:
		return
	_handle_purchase(purchase_token)

func _on_consume_response(purchase_token: String, debug_message: String, response_code: ResponseCode) -> void:
	print("[Billing]: Consume response!\n\tDebug Message: %s\n\tPurchase Token: %s\n\tResponse Code: %s" % [debug_message, purchase_token, response_code])
	if response_code != ResponseCode.OK:
		return
	_handle_consume(purchase_token)

func _on_product_details_response(debug_message: String, response_code: ResponseCode, product_details: Array) -> void:
	print("[Billing]: Product details response!\n\tDebug Message: %s\n\tResponse Code: %s\n\tProduct Details: %s" % [debug_message, response_code, product_details])
	if product_details.is_empty():
		return
	for data: Dictionary in product_details:
		_product_details.append(ProductDetails.new().deserialize(data))
	print("[Billing]: Product details size: %s" % _product_details.size())

func _on_query_purchases_response(debug_message: String, response_code: ResponseCode, purchases: Array) -> void:
	print("[Billing]: Purchases response!\n\tDebug Message: %s\n\tResponse Code: %s\n\tPurchases: %s" % [debug_message, response_code, purchases])
	if purchases.is_empty():
		return
	for purchase: Dictionary in purchases:
		var object: Purchase = Purchase.new().deserialize(purchase)
		if not object in _purchases:
			_purchases.append(object)
	print("[Billing]: Purchases size: %s" % _purchases.size())

func _on_purchase_attempt(product_id: String, debug_message: String, response_code: ResponseCode) -> void:
	print("[Billing]: Purchase attempted!\n\tProduct ID: %s\n\tDebug Message: %s\n\tResponse Code: %s" % [product_id, debug_message, response_code])
