class_name OneTimePurchaseOfferDetails
extends RefCounted

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
