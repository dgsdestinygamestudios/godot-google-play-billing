class_name ProductDetails
extends RefCounted

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
