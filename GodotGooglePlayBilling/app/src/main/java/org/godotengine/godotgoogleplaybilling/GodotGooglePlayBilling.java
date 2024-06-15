package org.godotengine.godotgoogleplaybilling;

import android.util.ArraySet;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

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
    private String latestToken = "";

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
        latestToken = purchaseToken;
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
            emitSignal("purchase_attempt", productId, "Product ID does not exist.", BillingClient.BillingResponseCode.ERROR);
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
        emitSignal("purchase_attempt", productId, billingResult.getDebugMessage(), billingResult.getResponseCode());
    }

    @Override
    public void onMainResume() {
        emitSignal("resume");
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
        emitSignal("purchases_updated", billingResult.getDebugMessage(), billingResult.getResponseCode(), Converter.PurchaseListToDictionaryArray(list));
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
        infos.add(new SignalInfo("resume"));
        infos.add(new SignalInfo("setup_finished", String.class, Integer.class)); // debug_message, response_code
        infos.add(new SignalInfo("purchases_updated", String.class, Integer.class, Object[].class)); // debug_message, response_code, purchases
        infos.add(new SignalInfo("acknowledge_purchase_response", String.class, String.class, Integer.class)); // purchase_token, debug_message, response_code
        infos.add(new SignalInfo("consume_response", String.class, String.class, Integer.class)); // purchase_token, debug_message, response_code
        infos.add(new SignalInfo("product_details_response", String.class, Integer.class, Object[].class)); // error_message, response_code, product_details
        infos.add(new SignalInfo("query_purchases_response", String.class, Integer.class, Object[].class)); // error_message, response_code, purchases
        infos.add(new SignalInfo("purchase_attempt", String.class, String.class, Integer.class)); // product_id, error_message, response_code
        return infos;
    }

    @Override
    public void onAcknowledgePurchaseResponse(@NonNull BillingResult billingResult) {
        emitSignal("acknowledge_purchase_response", latestToken, billingResult.getDebugMessage(), billingResult.getResponseCode());
        latestToken = "";
    }

    @Override
    public void onConsumeResponse(@NonNull BillingResult billingResult, @NonNull String purchaseToken) {
        emitSignal("consume_response", purchaseToken, billingResult.getDebugMessage(), billingResult.getResponseCode());
    }

    @Override
    public void onProductDetailsResponse(@NonNull BillingResult billingResult, @NonNull List<ProductDetails> list) {
        for (ProductDetails productDetails : list) {
            productDetailsHashMap.put(productDetails.getProductId(), productDetails);
        }
        emitSignal("product_details_response", billingResult.getDebugMessage(), billingResult.getResponseCode(), Converter.ProductDetailsListToDictionaryArray(list));
    }

    @Override
    public void onQueryPurchasesResponse(@NonNull BillingResult billingResult, @NonNull List<Purchase> list) {
        emitSignal("query_purchases_response", billingResult.getDebugMessage(), billingResult.getResponseCode(), Converter.PurchaseListToDictionaryArray(list));
    }
}
