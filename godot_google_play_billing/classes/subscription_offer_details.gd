class_name SubscriptionOfferDetails
extends RefCounted

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
