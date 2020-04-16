package ru.simdev.livetex;

import android.content.Context;
import android.util.Log;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.json.JSONArray;
import org.json.JSONException;

import ru.simdev.livetex.utils.DataKeeper;

public class Livetex extends CordovaPlugin {

    private static final String TAG = "Livetex";

    public static Context mContext;

    protected LivetexContext livetexContext;

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);

        this.cordova = cordova;
        mContext = cordova.getActivity().getApplicationContext();

        livetexContext = new LivetexContext(mContext);
    }

    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        switch (action) {
            case "init":
                init(callbackContext);
                return true;

            case "open":
                openChat(args.getString(0), callbackContext);
                return true;

            case "callback":
                setCallback(callbackContext);
                return true;

            case "destroy":
                destroy(callbackContext);
                return true;
        }

        return false;
    }

    public void init(final CallbackContext callbackContext) {
        try {
            livetexContext.initPresenter();
        } catch (Exception e) {

        }
    }

    public void openChat(String name, final CallbackContext callbackContext) {
        try {
            DataKeeper.setClientName(mContext, name);
            LivetexContext.setName(name);
            livetexContext.openChat();
        } catch (Exception e) {

        }
    }

    public void destroy(final CallbackContext callbackContext) {
        try {
            livetexContext.destroyLivetex();
        } catch (Exception e) {

        }
    }

    public void setCallback(final CallbackContext callbackContext) {
        try {
            livetexContext.setCallback(callbackContext);
        } catch (Exception e) {
            Log.e(TAG, e.getMessage());
        }
    }
}