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
var _latest_purchase_token: String = ""
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
	_library.connect(&"billing_resume", _on_billing_resume)
	_library.connect(&"setup_finished", _on_setup_finished)
	_library.connect(&"purchases_updated", _on_purchases_updated)
	_library.connect(&"acknowledge_purchase_response", _on_acknowledge_purchase_response)
	_library.connect(&"consume_response", _on_consume_response)
	_library.connect(&"product_details_response", _on_product_details_response)
	_library.connect(&"purchases_response", _on_purchases_response)
	_library.connect(&"purchase", _on_purchase)

func _handle_purchase(purchase_token: String) -> void:
	print("[Billing]: Rewarding player!\n\tPurchase Token: %s" % purchase_token)
	_latest_purchase_token = ""

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

func _consume(purchase_token: String) -> void:
	print("[Billing]: Consuming!\n\tPurchase Token: %s" % purchase_token)
	_library.Consume(purchase_token)

func _query_product_details(product_ids: PackedStringArray, product_type: String) -> void:
	print("[Billing]: Querying product details!\n\tProduct IDs: %s\n\tProduct Type: %s" % [product_ids, product_type])
	_library.QueryProductDetails(product_ids, product_type)

func _on_disconnected() -> void:
	print("[Billing]: Disconnected!")
	_start_connection()

func _on_billing_resume() -> void:
	print("[Billing]: Resuming!")
	if _get_connection_state() != ConnectionState.CONNECTED:
		return
	_query_product_details(CONSUMABLE_ITEMS, "inapp")
	_query_product_details(NON_CONSUMABLE_ITEMS, "inapp")
	_query_product_details(SUBSCRIPTION_ITEMS, "subs")
	_query_purchases("inapp")
	_query_purchases("subs")

func _on_setup_finished(debug_message: String, response_code: ResponseCode) -> void:
	print("[Billing]: Setup finished!\n\tDebug Message: %s\n\tResponse Code: %s" % [debug_message, response_code])
	_query_product_details(CONSUMABLE_ITEMS, "inapp")
	_query_product_details(NON_CONSUMABLE_ITEMS, "inapp")
	_query_product_details(SUBSCRIPTION_ITEMS, "subs")
	_query_purchases("inapp")
	_query_purchases("subs")

func _on_purchases_updated(debug_message: String, response_code: ResponseCode, purchases: Array) -> void:
	print("[Billing]: Purchases updated!\n\tDebug Message: %s\n\tResponse Code: %s\n\tPurchases: %s" % [debug_message, response_code, purchases])
	var converted_purchases: Array = purchases.map(func(data: Dictionary) -> Purchase: return Purchase.new().deserialize(data))
	for purchase: Purchase in converted_purchases:
		if purchase.is_acknowledged:
			continue
		if purchase.token in CONSUMABLE_ITEMS:
			_consume(purchase.token)
		elif purchase.token in NON_CONSUMABLE_ITEMS or purchase.token in SUBSCRIPTION_ITEMS:
			_acknowledge_purchase(purchase.token)
			_latest_purchase_token = purchase.token

func _on_acknowledge_purchase_response(debug_message: String, response_code: ResponseCode) -> void:
	print("[Billing]: Acknowledge purchase response!\n\tDebug Message: %s\n\tResponse Code: %s" % [debug_message, response_code])
	if response_code != ResponseCode.OK:
		return
	_handle_purchase(_latest_purchase_token)

func _on_consume_response(debug_message: String, purchase_token: String, response_code: ResponseCode) -> void:
	print("[Billing]: Consume response!\n\tDebug Message: %s\n\tPurchase Token: %s\n\tResponse Code: %s" % [debug_message, purchase_token, response_code])
	if response_code != ResponseCode.OK:
		return
	_handle_purchase(purchase_token)

func _on_product_details_response(debug_message: String, response_code: ResponseCode, product_details: Array) -> void:
	print("[Billing]: Product details response!\n\tDebug Message: %s\n\tResponse Code: %s\n\tProduct Details: %s" % [debug_message, response_code, product_details])
	if product_details.is_empty():
		return
	for detail: Dictionary in product_details:
		var object: ProductDetails = ProductDetails.new().deserialize(detail)
		if not object in _product_details:
			_product_details.append(object)
	print("[Billing]: Product details size: %s" % _product_details.size())

func _on_purchases_response(debug_message: String, response_code: ResponseCode, purchases: Array) -> void:
	print("[Billing]: Purchases response!\n\tDebug Message: %s\n\tResponse Code: %s\n\tPurchases: %s" % [debug_message, response_code, purchases])
	if purchases.is_empty():
		return
	for purchase: Dictionary in purchases:
		var object: Purchase = Purchase.new().deserialize(purchase)
		if not object in _purchases:
			_purchases.append(object)
	print("[Billing]: Purchases size: %s" % _purchases.size())

func _on_purchase(product_id: String, debug_message: String, response_code: ResponseCode) -> void:
	print("[Billing]: Purchase!\n\tProduct ID: %s\n\tDebug Message: %s\n\tResponse Code: %s" % [product_id, debug_message, response_code])

class Purchase extends RefCounted:
	var token: String = ""
	var original_json: String = ""
	var package_name: String = ""
	var order_id: String = ""
	var developer_payload: String = ""
	var signature: String = ""
	var products: PackedStringArray = []
	var state: int = 0
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

class PendingPurchaseUpdate extends RefCounted:
	var token: String = ""
	var products: PackedStringArray = []

	func deserialize(data: Dictionary) -> PendingPurchaseUpdate:
		if &"token" in data:
			token = data[&"token"]
		if &"products" in data:
			products = data[&"products"]
		return self

class AccountIdentifiers extends RefCounted:
	var obfuscated_account_id: String = ""
	var obfuscated_profile_id: String = ""

	func deserialize(data: Dictionary) -> AccountIdentifiers:
		if &"obfuscated_account_id" in data:
			obfuscated_account_id = data[&"obfuscated_account_id"]
		if &"obfuscated_profile_id" in data:
			obfuscated_profile_id = data[&"obfuscated_profile_id"]
		return self

class ProductDetails extends RefCounted:
	var id: String = ""
	var type: String = ""
	var description: String = ""
	var pd_name: String = ""
	var title: String = ""
	var one_time_purchase_offer_details: OneTimePurchaseOfferDetails = OneTimePurchaseOfferDetails.new()
	var subscription_offer_details: SubscriptionOfferDetails = SubscriptionOfferDetails.new()

	func deserialize(data: Dictionary) -> ProductDetails:
		if &"id" in data:
			id = data[&"id"]
		if &"type" in data:
			type = data[&"type"]
		if &"description" in data:
			description = data[&"description"]
		if &"name" in data:
			pd_name = data[&"name"]
		if &"title" in data:
			title = data[&"title"]
		if &"one_time_purchase_offer_details" in data and data[&"one_time_purchase_offer_details"] is Dictionary and data[&"one_time_purchase_offer_details"] != null:
			one_time_purchase_offer_details = OneTimePurchaseOfferDetails.new().deserialize(data[&"one_time_purchase_offer_details"])
		if &"subscription_offer_details" in data and data[&"subscription_offer_details"] is Dictionary and data[&"subscription_offer_details"] != null:
			subscription_offer_details = SubscriptionOfferDetails.new().deserialize(data[&"subscription_offer_details"])
		return self

class OneTimePurchaseOfferDetails extends RefCounted:
	var currency_code: String = ""
	var formatted_price: String = ""
	var price_amount: int = 0

	func deserialize(data: Dictionary) -> OneTimePurchaseOfferDetails:
		if &"currency_code" in data:
			currency_code = data[&"currency_code"]
		if &"formatted_price" in data:
			formatted_price = data[&"formatted_price"]
		if &"price_amount" in data:
			price_amount = data[&"price_amount"]
		return self

class SubscriptionOfferDetails extends RefCounted:
	var id: String = ""
	var token: String = ""
	var base_plan_id: String = ""
	var tags: PackedStringArray = []
	var pricing_phases: PackedStringArray = []
	var installment_plan_commitment_payments_count: int = 0
	var subsequent_installment_plan_commitment_payments_count: int = 0

	func deserialize(data: Dictionary) -> SubscriptionOfferDetails:
		if &"id" in data:
			id = data[&"id"]
		if &"token" in data:
			token = data[&"token"]
		if &"base_plan_id" in data:
			base_plan_id = data[&"base_plan_id"]
		if &"tags" in data:
			tags = data[&"tags"]
		if &"pricing_phases" in data:
			pricing_phases = data[&"pricing_phases"]
		if &"installment_plan_commitment_payments_count" in data:
			installment_plan_commitment_payments_count = data[&"installment_plan_commitment_payments_count"]
		if &"subsequent_installment_plan_commitment_payments_count" in data:
			subsequent_installment_plan_commitment_payments_count = data[&"subsequent_installment_plan_commitment_payments_count"]
		return self
