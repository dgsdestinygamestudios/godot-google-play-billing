package org.godotengine.godotgoogleplaybilling;

import com.android.billingclient.api.AccountIdentifiers;
import com.android.billingclient.api.ProductDetails;
import com.android.billingclient.api.Purchase;

import org.godotengine.godot.Dictionary;

import java.util.ArrayList;
import java.util.List;

public class Converter {
    public static Dictionary PurchaseToDictionary(Purchase purchase) {
        Dictionary data = new Dictionary();
        if (purchase.getAccountIdentifiers() != null) {
            data.put("account_identifiers", AccountIdentifiersToDictionary(purchase.getAccountIdentifiers())); // dictionary
        }
        if (purchase.getPendingPurchaseUpdate() != null) {
            data.put("pending_purchase_update", PendingPurchaseUpdateToDictionary(purchase.getPendingPurchaseUpdate())); // dictionary
        }
        data.put("products", purchase.getProducts().toArray()); // string array
        data.put("token", purchase.getPurchaseToken()); // string
        data.put("state", purchase.getPurchaseState()); // int
        data.put("is_auto_renewing", purchase.isAutoRenewing()); // bool
        data.put("original_json", purchase.getOriginalJson()); // string
        data.put("package_name", purchase.getPackageName()); // string
        data.put("order_id", purchase.getOrderId()); // string
        data.put("developer_payload", purchase.getDeveloperPayload()); // string
        data.put("quantity", purchase.getQuantity()); // int
        data.put("is_acknowledged", purchase.isAcknowledged()); // bool
        data.put("signature", purchase.getSignature()); // string
        return data;
    }

    public static Dictionary AccountIdentifiersToDictionary(AccountIdentifiers accountIdentifiers) {
        Dictionary data = new Dictionary();
        data.put("obfuscated_account_id", accountIdentifiers.getObfuscatedAccountId()); // string
        data.put("obfuscated_profile_id", accountIdentifiers.getObfuscatedProfileId()); // string
        return data;
    }

    public static Dictionary PendingPurchaseUpdateToDictionary(Purchase.PendingPurchaseUpdate pendingPurchaseUpdate) {
        Dictionary data = new Dictionary();
        data.put("token", pendingPurchaseUpdate.getPurchaseToken()); // string
        data.put("products", pendingPurchaseUpdate.getProducts().toArray()); // string array
        return data;
    }

    public static Dictionary ProductDetailsToDictionary(ProductDetails productDetails) {
        Dictionary data = new Dictionary();
        data.put("id", productDetails.getProductId()); // string
        data.put("type", productDetails.getProductType()); // string
        data.put("description", productDetails.getDescription()); // string
        data.put("name", productDetails.getName()); // string
        data.put("title", productDetails.getTitle()); // string
        if (productDetails.getOneTimePurchaseOfferDetails() != null) {
            data.put("one_time_purchase_offer_details", OneTimePurchaseOfferDetailsToDictionary(productDetails.getOneTimePurchaseOfferDetails())); // dictionary
        }
        if (productDetails.getSubscriptionOfferDetails() != null) {
            data.put("subscription_offer_details", SubscriptionOfferDetailsListToDictionaryArray(productDetails.getSubscriptionOfferDetails())); // array
        }
        return data;
    }

    public static Dictionary OneTimePurchaseOfferDetailsToDictionary(ProductDetails.OneTimePurchaseOfferDetails oneTimePurchaseOfferDetails) {
        Dictionary data = new Dictionary();
        data.put("currency_code", oneTimePurchaseOfferDetails.getPriceCurrencyCode()); // string
        data.put("formatted_price", oneTimePurchaseOfferDetails.getFormattedPrice()); // string
        data.put("price_amount", oneTimePurchaseOfferDetails.getPriceAmountMicros()); // int
        return data;
    }

    public static Dictionary SubscriptionOfferDetailsToDictionary(ProductDetails.SubscriptionOfferDetails details) {
        Dictionary data = new Dictionary();
        data.put("id", details.getOfferId()); // string
        data.put("tags", details.getOfferTags().toArray()); // string array
        data.put("token", details.getOfferToken()); // string
        data.put("base_plan_id", details.getBasePlanId()); // string
        data.put("pricing_phases", details.getPricingPhases().getPricingPhaseList().toArray()); // string array
        if (details.getInstallmentPlanDetails() != null) {
            data.put("installment_plan_commitment_payments_count", details.getInstallmentPlanDetails().getInstallmentPlanCommitmentPaymentsCount()); // int
            data.put("subsequent_installment_plan_commitment_payments_count", details.getInstallmentPlanDetails().getSubsequentInstallmentPlanCommitmentPaymentsCount()); // int
        }
        return data;
    }

    public static Object[] ProductDetailsListToDictionaryArray(List<ProductDetails> productDetails) {
        List<Dictionary> data = new ArrayList<>();
        for (ProductDetails details : productDetails) {
            data.add(ProductDetailsToDictionary(details));
        }
        return data.toArray();
    }

    public static Object[] SubscriptionOfferDetailsListToDictionaryArray(List<ProductDetails.SubscriptionOfferDetails> subscriptionOfferDetails) {
        List<Dictionary> data = new ArrayList<>();
        for (ProductDetails.SubscriptionOfferDetails details : subscriptionOfferDetails) {
            data.add(SubscriptionOfferDetailsToDictionary(details));
        }
        return data.toArray();
    }

    public static Object[] PurchaseListToDictionaryArray(List<Purchase> purchases) {
        List<Dictionary> list = new ArrayList<>();
        for (Purchase purchase : purchases) {
            list.add(PurchaseToDictionary(purchase));
        }
        return list.toArray();
    }
}
