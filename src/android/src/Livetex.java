package ru.simdev.livetex;

import android.content.Context;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;

import org.json.JSONArray;
import org.json.JSONException;

public class Livetex extends CordovaPlugin {
    
    public static Context mContext;

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);

        this.cordova = cordova;
        mContext = cordova.getActivity().getApplicationContext();
    }

    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        switch (action) {
            case "login":
                return true;
        }

        return false;
    }
}