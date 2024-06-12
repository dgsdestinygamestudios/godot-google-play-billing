package org.godotengine.godotgoogleplaybilling;

import android.util.ArraySet;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.android.billingclient.api.AccountIdentifiers;
import com.android.billingclient.api.AcknowledgePurchaseParams;
import com.android.billingclient.api.AcknowledgePurchaseResponseListener;
import com.android.billingclient.api.BillingClient;
import com.android.billingclient.api.BillingClientStateListener;
import com.android.billingclient.api.BillingFlowParams;
import com.android.billingclient.api.BillingResult;
import com.android.billingclient.api.ConsumeParams;
import com.android.billingclient.api.ConsumeResponseListener;
import com.android.billingclient.api.PendingPurchasesParams;
import com.android.billingclient.api.ProductDetails;
import com.android.billingclient.api.ProductDetailsResponseListener;
import com.android.billingclient.api.Purchase;
import com.android.billingclient.api.PurchasesResponseListener;
import com.android.billingclient.api.PurchasesUpdatedListener;
import com.android.billingclient.api.QueryProductDetailsParams;
import com.android.billingclient.api.QueryPurchasesParams;

import org.godotengine.godot.Dictionary;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Objects;
import java.util.Set;

public class GodotGooglePlayBilling extends GodotPlugin implements PurchasesUpdatedListener, BillingClientStateListener, AcknowledgePurchaseResponseListener, ConsumeResponseListener, ProductDetailsResponseListener, PurchasesResponseListener {

    private final HashMap<String, ProductDetails> productDetailsHashMap = new HashMap<>();
    private BillingClient billingClient;

    public GodotGooglePlayBilling(Godot godot) {
        super(godot);
    }

    @UsedByGodot
    public void StartConnection() {
        PendingPurchasesParams pendingPurchasesParams = PendingPurchasesParams.newBuilder().enableOneTimeProducts().build();
        if (getGodot().getActivity() == null) {
            return;
        }
        billingClient = BillingClient.newBuilder(getGodot().getActivity()).setListener(this).enablePendingPurchases(pendingPurchasesParams).build();
        billingClient.startConnection(this);
    }

    @UsedByGodot
    public void EndConnection() {
        billingClient.endConnection();
    }

    @UsedByGodot
    public boolean IsReady() {
        return billingClient.isReady();
    }

    @UsedByGodot
    public int GetConnectionState() {
        return billingClient.getConnectionState();
    }

    @UsedByGodot
    public void AcknowledgePurchase(String purchaseToken) {
        AcknowledgePurchaseParams acknowledgePurchaseParams = AcknowledgePurchaseParams.newBuilder().setPurchaseToken(purchaseToken).build();
        billingClient.acknowledgePurchase(acknowledgePurchaseParams, this);
    }

    @UsedByGodot
    public void QueryPurchases(String productType) {
        QueryPurchasesParams queryPurchasesParams = QueryPurchasesParams.newBuilder().setProductType(productType).build();
        billingClient.queryPurchasesAsync(queryPurchasesParams, this);
    }

    @UsedByGodot
    public void Consume(String purchaseToken) {
        ConsumeParams consumeParams = ConsumeParams.newBuilder().setPurchaseToken(purchaseToken).build();
        billingClient.consumeAsync(consumeParams, this);
    }

    @UsedByGodot
    public void QueryProductDetails(String[] productIds, String productType) {
        if (productIds.length == 0) {
            return;
        }
        List<QueryProductDetailsParams.Product> products = new ArrayList<>();
        for (String id : productIds) {
            products.add(QueryProductDetailsParams.Product.newBuilder().setProductId(id).setProductType(productType).build());
        }
        QueryProductDetailsParams queryProductDetailsParams = QueryProductDetailsParams.newBuilder().setProductList(products).build();
        billingClient.queryProductDetailsAsync(queryProductDetailsParams, this);
    }

    @UsedByGodot
    public void Purchase(String productId, String productType) {
        if (!productDetailsHashMap.containsKey(productId)) {
            emitSignal("purchase", productId, "Product ID does not exist.", BillingClient.BillingResponseCode.ERROR);
            return;
        }
        ProductDetails productDetails = productDetailsHashMap.get(productId);
        if (productDetails == null) {
            return;
        }
        BillingFlowParams.ProductDetailsParams.Builder productDetailsParamsBuilder = BillingFlowParams.ProductDetailsParams.newBuilder().setProductDetails(productDetails);
        if (Objects.equals(productType, "subs")) {
            if (productDetails.getSubscriptionOfferDetails() == null) {
                return;
            }
            productDetailsParamsBuilder.setOfferToken(productDetails.getSubscriptionOfferDetails().get(0).getOfferToken());
        }
        BillingFlowParams.ProductDetailsParams productDetailsParams = productDetailsParamsBuilder.build();
        BillingFlowParams billingFlowParams = BillingFlowParams.newBuilder().setProductDetailsParamsList(List.of(productDetailsParams)).setObfuscatedAccountId("").setObfuscatedProfileId("").build();
        if (getGodot().getActivity() == null) {
            return;
        }
        BillingResult billingResult = billingClient.launchBillingFlow(getGodot().getActivity(), billingFlowParams);
        emitSignal("purchase", productId, billingResult.getDebugMessage(), billingResult.getResponseCode());
    }

    private Dictionary PurchaseToDictionary(Purchase purchase) {
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

    private Dictionary AccountIdentifiersToDictionary(AccountIdentifiers accountIdentifiers) {
        Dictionary data = new Dictionary();
        data.put("obfuscated_account_id", accountIdentifiers.getObfuscatedAccountId()); // string
        data.put("obfuscated_profile_id", accountIdentifiers.getObfuscatedProfileId()); // string
        return data;
    }

    private Dictionary PendingPurchaseUpdateToDictionary(Purchase.PendingPurchaseUpdate pendingPurchaseUpdate) {
        Dictionary data = new Dictionary();
        data.put("token", pendingPurchaseUpdate.getPurchaseToken()); // string
        data.put("products", pendingPurchaseUpdate.getProducts().toArray()); // string array
        return data;
    }

    private Object[] PurchaseListToDictionaryArray(List<Purchase> purchases) {
        List<Dictionary> list = new ArrayList<>();
        for (Purchase purchase : purchases) {
            list.add(PurchaseToDictionary(purchase));
        }
        return list.toArray();
    }

    private Dictionary ProductDetailsToDictionary(ProductDetails productDetails) {
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

    private Object[] ProductDetailsListToDictionaryArray(List<ProductDetails> productDetails) {
        List<Dictionary> data = new ArrayList<>();
        for (ProductDetails details : productDetails) {
            data.add(ProductDetailsToDictionary(details));
        }
        return data.toArray();
    }

    private Object[] SubscriptionOfferDetailsListToDictionaryArray(List<ProductDetails.SubscriptionOfferDetails> subscriptionOfferDetails) {
        List<Dictionary> data = new ArrayList<>();
        for (ProductDetails.SubscriptionOfferDetails details : subscriptionOfferDetails) {
            data.add(SubscriptionOfferDetailsToDictionary(details));
        }
        return data.toArray();
    }

    private Dictionary OneTimePurchaseOfferDetailsToDictionary(ProductDetails.OneTimePurchaseOfferDetails oneTimePurchaseOfferDetails) {
        Dictionary data = new Dictionary();
        data.put("currency_code", oneTimePurchaseOfferDetails.getPriceCurrencyCode()); // string
        data.put("formatted_price", oneTimePurchaseOfferDetails.getFormattedPrice()); // string
        data.put("price_amount", oneTimePurchaseOfferDetails.getPriceAmountMicros()); // int
        return data;
    }

    private Dictionary SubscriptionOfferDetailsToDictionary(ProductDetails.SubscriptionOfferDetails details) {
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

    @Override
    public void onBillingServiceDisconnected() {
        emitSignal("disconnected");
    }

    @Override
    public void onBillingSetupFinished(@NonNull BillingResult billingResult) {
        emitSignal("setup_finished", billingResult.getDebugMessage(), billingResult.getResponseCode());
    }

    @Override
    public void onPurchasesUpdated(@NonNull BillingResult billingResult, @Nullable List<Purchase> list) {
        if (list == null || list.size() == 0) {
            return;
        }
        emitSignal("purchases_updated", billingResult.getDebugMessage(), billingResult.getResponseCode(), PurchaseListToDictionaryArray(list));
    }

    @NonNull
    @Override
    public String getPluginName() {
        return "GodotGooglePlayBilling";
    }

    @NonNull
    @Override
    public Set<SignalInfo> getPluginSignals() {
        Set<SignalInfo> infos = new ArraySet<>();
        infos.add(new SignalInfo("disconnected"));
        infos.add(new SignalInfo("setup_finished", String.class, Integer.class)); // debug_message, response_code
        infos.add(new SignalInfo("purchases_updated", String.class, Integer.class, Object[].class)); // debug_message, response_code, purchases
        infos.add(new SignalInfo("acknowledge_purchase_response", String.class, Integer.class)); // debug_message, response_code
        infos.add(new SignalInfo("consume_response", String.class, String.class, Integer.class)); // debug_message, purchase_token, response_code
        infos.add(new SignalInfo("product_details_response", String.class, Integer.class, Object[].class)); // error_message, response_code, product_details
        infos.add(new SignalInfo("purchases_response", String.class, Integer.class, Object[].class)); // error_message, response_code, purchases
        infos.add(new SignalInfo("purchase", String.class, String.class, Integer.class)); // product_id, error_message, response_code
        return infos;
    }

    @Override
    public void onAcknowledgePurchaseResponse(@NonNull BillingResult billingResult) {
        emitSignal("acknowledge_purchase_response", billingResult.getDebugMessage(), billingResult.getResponseCode());
    }

    @Override
    public void onConsumeResponse(@NonNull BillingResult billingResult, @NonNull String purchaseToken) {
        emitSignal("consume_response", billingResult.getDebugMessage(), purchaseToken, billingResult.getResponseCode());
    }

    @Override
    public void onProductDetailsResponse(@NonNull BillingResult billingResult, @NonNull List<ProductDetails> list) {
        for (ProductDetails productDetails : list) {
            productDetailsHashMap.put(productDetails.getProductId(), productDetails);
        }
        emitSignal("product_details_response", billingResult.getDebugMessage(), billingResult.getResponseCode(), ProductDetailsListToDictionaryArray(list));
    }

    @Override
    public void onQueryPurchasesResponse(@NonNull BillingResult billingResult, @NonNull List<Purchase> list) {
        emitSignal("purchases_response", billingResult.getDebugMessage(), billingResult.getResponseCode(), PurchaseListToDictionaryArray(list));
    }
}
