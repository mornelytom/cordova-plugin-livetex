package ru.simdev.livetex;

import android.app.Activity;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;
import android.view.WindowManager;

import androidx.fragment.app.FragmentActivity;

import ru.simdev.evo.video.R;
import ru.simdev.livetex.fragments.InitFragment;
import ru.simdev.livetex.fragments.OnlineChatFragment1;
import ru.simdev.livetex.utils.BusProvider;
import ru.simdev.livetex.utils.DataKeeper;
import sdk.handler.AHandler;

public class FragmentEnvironment extends FragmentActivity {

    private static final String TAG = "Livetex";

    public static Activity fa;

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        fa = this;

        Log.d(TAG, "onCreate FragmentActivity");

        if (!isTaskRoot()
                && getIntent().hasCategory(Intent.CATEGORY_LAUNCHER)
                && getIntent().getAction() != null
                && getIntent().getAction().equals(Intent.ACTION_MAIN)) {

            finish();
            return;
        }

        getWindow().addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
        getWindow().clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS);

        if (Build.VERSION.SDK_INT >= 21) {
            getWindow().setStatusBarColor(getResources().getColor(android.R.color.black));
        }

        setContentView(R.layout.livetex_activity_main1);
        init();

    }

    private boolean isAwakenByPush() {
        Log.d(TAG, "isAwakenByPush");
        if (Const.PUSH_ONLINE_ACTION.equals(getIntent().getAction())) {
            String appID = DataKeeper.restoreAppId(this);
            String regID = DataKeeper.restoreRegId(this);
            String mes = getIntent().getStringExtra("mes");

            OnlineChatFragment1 onlineChatFragment = new OnlineChatFragment1();
            getSupportFragmentManager().beginTransaction().add(R.id.fragment_container, onlineChatFragment).commitAllowingStateLoss();

            LivetexContext.initLivetex(appID, regID, new AHandler<Boolean>() {
                @Override
                public void onError(String errMsg) {

                }

                @Override
                public void onResultRecieved(Boolean result) {
                    OnlineChatFragment1 onlineChatFragment = new OnlineChatFragment1();
                    getSupportFragmentManager().beginTransaction().add(R.id.fragment_container, onlineChatFragment).commitAllowingStateLoss();
                }
            });
            return true;
        }
        return false;
    }

    public void init() {
        if (!isAwakenByPush()) {
            getSupportFragmentManager().beginTransaction().add(R.id.fragment_container, new InitFragment()).commit();
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        LivetexContext.IS_ACTIVE = true;
        if (LivetexContext.getsLiveTex() != null && !TextUtils.isEmpty(sdk.data.DataKeeper.restoreToken(this))) {
            LivetexContext.getsLiveTex().bindService();
        }
    }

    @Override
    public void onBackPressed() {
        LivetexContext.IS_ACTIVE = false;
        if (LivetexContext.getsLiveTex() != null) {
            //LivetexContext.getsLiveTex().destroy();
        }

        BusProvider.unregister(this);
        if (getSupportFragmentManager().getBackStackEntryCount() > 0) {
            String currentFragment = getSupportFragmentManager().getBackStackEntryAt(getSupportFragmentManager().getBackStackEntryCount() - 1).getName();
            if (currentFragment != null && currentFragment.equals(OnlineChatFragment1.class.getName())) {
                finish();
                return;
            }
        }

        super.onBackPressed();
    }

    @Override
    protected void onPause() {
        super.onPause();
    }

    @Override
    protected void onStop() {
        LivetexContext.IS_ACTIVE = false;

        Log.d(TAG, "Activity onStop");

        if (LivetexContext.getsLiveTex() != null) {
            //LivetexContext.getsLiveTex().unbindService();
        }

        super.onStop();
    }
}