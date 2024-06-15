class_name AccountIdentifiers
extends RefCounted

var obfuscated_account_id: String = ""
var obfuscated_profile_id: String = ""

func deserialize(data: Dictionary) -> AccountIdentifiers:
	if &"obfuscated_account_id" in data:
		obfuscated_account_id = data[&"obfuscated_account_id"]
	if &"obfuscated_profile_id" in data:
		obfuscated_profile_id = data[&"obfuscated_profile_id"]
	return self
