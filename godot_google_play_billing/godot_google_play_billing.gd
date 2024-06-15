@tool
extends EditorPlugin

var plugin: AndroidExportPlugin = null

func _enter_tree() -> void:
	plugin = AndroidExportPlugin.new()
	add_autoload_singleton("Billing", "res://addons/godot_google_play_billing/autoload/billing.gd")
	add_export_plugin(plugin)

func _exit_tree() -> void:
	remove_autoload_singleton("Billing")
	remove_export_plugin(plugin)
	plugin = null

class AndroidExportPlugin extends EditorExportPlugin:
	var _plugin_name: String = "GodotGooglePlayBilling"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		if platform is EditorExportPlatformAndroid:
			return true
		return false

	func _get_android_libraries(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		return PackedStringArray(["res://addons/godot_google_play_billing/GodotGooglePlayBilling.aar"])

	func _get_android_dependencies(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		return PackedStringArray(['com.android.billingclient:billing:7.0.0'])

	func _get_name() -> String:
		return _plugin_name
