# godot-google-play-billing
Google Play Billing 7.0.0 for Godot 4.2+

# Usage

1 - Add `godot_google_play_billing` folder to your project's `addons` folder.
2 - Go to `Project/Project Settings/Plugins` and enable the plugin.
3 - Open `billing.gd` file.
4 - Change `const CONSUMABLE_ITEMS: PackedStringArray`, `const NON_CONSUMABLE_ITEMS: PackedStringArray` and `const SUBSCRIPTION_ITEMS: PackedStringArray` for your spesific use.
5 - Calling `Billing.purchase(product_token: String)` anywhere will initiate the process.
