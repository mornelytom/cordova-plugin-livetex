package ru.simdev.livetex;

import android.app.Activity;
import android.content.Context;

import com.nostra13.universalimageloader.core.DisplayImageOptions;
import com.nostra13.universalimageloader.core.ImageLoader;
import com.nostra13.universalimageloader.core.ImageLoaderConfiguration;

import org.apache.thrift.TException;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import livetex.capabilities.Capabilities;
import livetex.dialog.DialogAttributes;
import livetex.queue_service.Destination;
import livetex.queue_service.SendMessageResponse;
import ru.simdev.livetex.models.BaseMessage;
import ru.simdev.livetex.models.ErrorMessage1;
import ru.simdev.livetex.models.EventMessage;
import sdk.Livetex;
import sdk.handler.AHandler;
import sdk.handler.IInitHandler;
import sdk.handler.INotificationDialogHandler;
import sdk.models.LTDialogAttributes;
import sdk.models.LTDialogState;
import sdk.models.LTEmployee;
import sdk.models.LTFileMessage;
import sdk.models.LTHoldMessage;
import sdk.models.LTSerializableHolder;
import sdk.models.LTTextMessage;
import sdk.models.LTTypingMessage;
import sdk.utils.FileUtils;

public class LivetexContext {

    private static LivetexContext sInstance = null;

    private Context mContext;

    public static String currentConversation = "";
    public static boolean IS_ACTIVE = false;
    private static List<Activity> externalActivitiesStack = new ArrayList<>();


    private static final String AUTH_URL_REAL = "https://authentication-service-sdk-production-1.livetex.ru";
    private static final String API_KEY_REAL = "sdkkey235860-163721";

    private static String AUTH_URL = AUTH_URL_REAL;
    private static String API_KEY = API_KEY_REAL;

    public static void setProductionScope() {
        API_KEY = API_KEY_REAL;
        AUTH_URL = AUTH_URL_REAL;
    }

    private static Livetex sLiveTex;

    public static Livetex getsLiveTex() {
        return sLiveTex;
    }

    public LivetexContext(Context context) {
        mContext = context;

        init();

        sInstance = this;
    }

    public static boolean isReady() {
        return sInstance != null;
    }

    public static LivetexContext instance() {
        return sInstance;
    }

    public void updateContext(Context context) {
        mContext = context;
    }

    public void init() {
        DisplayImageOptions defaultOptions = new DisplayImageOptions.Builder()
                .cacheInMemory(true)
                .cacheOnDisk(true)
                .build();

        ImageLoaderConfiguration config = new ImageLoaderConfiguration.Builder(mContext)
                .defaultDisplayImageOptions(defaultOptions)
                .build();

        ImageLoader.getInstance().init(config);

        LivetexContext.setProductionScope();
        //BusProvider.register(this);
    }


    public static void pushToActivitiesStack(Activity activity) {
        externalActivitiesStack.add(activity);
    }

    public static void clearExternalActivitiesStack() {
        for (Activity activity : externalActivitiesStack) {
            activity.finish();
        }
    }

    public static void initLivetex(String id, String regId) {
        initLivetex(id, regId, null);

    }

    public static void initLivetex(String id, String regId, final AHandler<Boolean> handler) {

        ArrayList<Capabilities> capabilities = new ArrayList(){{add(Capabilities.QUEUE);}};

        sLiveTex = new Livetex.Builder(instance().mContext, API_KEY, id)
                .addAuthUrl(AUTH_URL)
                .addDeviceId(regId)
                .addCapabilities(capabilities)
                .addToken(sdk.data.DataKeeper.restoreToken(instance().mContext))
                .build();

        sLiveTex.init(new IInitHandler() {
            @Override
            public void onSuccess(String token) {
                sdk.data.DataKeeper.saveToken(instance().mContext, token);
                postMessage(new EventMessage(BaseMessage.TYPE.INIT, token));
                if (handler != null) {
                    handler.onResultRecieved(true);
                }

                sLiveTex.setNotificationDialogHandler(new INotificationDialogHandler() {


                    @Override
                    public void updateDialogState(LTDialogState state) throws TException {
                        if (state.getEmployee() == null) {
                            EventMessage eventMessage = new EventMessage(BaseMessage.TYPE.CLOSE);
                            postMessage(eventMessage);
                        } else {
                            EventMessage eventMessage = new EventMessage(BaseMessage.TYPE.UPDATE_STATE);
                            eventMessage.putSerializable(state.getEmployee());
                            postMessage(eventMessage);
                        }
                    }

                    @Override
                    public void receiveHoldMessage(LTHoldMessage message) throws TException {

                    }

                    @Override
                    public void receiveTypingMessage(LTTypingMessage message) throws TException {
                        EventMessage eventMessage = new EventMessage(BaseMessage.TYPE.TYPING_MESSAGE);
                        postMessage(eventMessage);
                    }

                    @Override
                    public void onError(String message) {

                    }

                    @Override
                    public void receiveTextMessage(LTTextMessage message) throws TException {
                        EventMessage eventMessage = new EventMessage(BaseMessage.TYPE.RECEIVE_QUEUE_MSG);
                        eventMessage.putSerializable(message);

                        postMessage(eventMessage);
                    }

                    @Override
                    public void receiveFileMessage(LTFileMessage message) throws TException {
                        EventMessage eventMessage = new EventMessage(BaseMessage.TYPE.RECEIVE_FILE);
                        eventMessage.putSerializable(message);
                        postMessage(eventMessage);
                    }

                });
            }

            @Override
            public void onError(String errorMessage) {
                postMessage(new ErrorMessage1(BaseMessage.TYPE.INIT, errorMessage));
            }
        });

    }

    public static void postMessage(BaseMessage message) {
        if (message != null) {
            ru.simdev.livetex.utils.BusProvider.getInstance().post(message);
        }
    }


    public static void confirmQueueMessage(String messageId) {
        if (sLiveTex != null) {
            sLiveTex.confirm(messageId);
        }
    }

    public static void getQueueHistory(long offset, long limit, AHandler<LTSerializableHolder> handler) {
        if(sLiveTex != null) {
            sLiveTex.getHistory(offset, limit, handler);
        }
    }

    public static void requestDialogByEmployee(String id, String livetexId, AHandler<LTDialogState> handler) {
        if (sLiveTex != null) {
            DialogAttributes dialogAttributes = new DialogAttributes();
            HashMap<String, String> hashMap = new HashMap<>();
            hashMap.put("Livetex ID", livetexId);
            dialogAttributes.setVisible(hashMap);
            LTEmployee operator = new LTEmployee(id, "online", "", "", "");
        }
    }

    public static void getDestinations(AHandler<ArrayList<Destination>> handler) {
        if(sLiveTex != null) {
            sLiveTex.getDestinations(handler);
        }
    }

    public static void setDestination(Destination destination, LTDialogAttributes dialogAttrs) {

        if(sLiveTex != null) {
            sLiveTex.setDestination(destination, dialogAttrs);
        }
    }

    public static void sendTextMessage(String message, AHandler<SendMessageResponse> handler) {
        if(sLiveTex != null) {
            sLiveTex.sendTextMessage(message, handler);
        }
    }

    public static void getStateQueue(AHandler<livetex.queue_service.DialogState> handler) {
        if(sLiveTex != null) {
            sLiveTex.getState(handler);
        }
    }

    public static void sendFileToFileService(final File file, final AHandler<String> handler) {
        new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    handler.onResultRecieved(FileUtils.sendMultipart(file, "http://file-service-0-sdk-prerelease.livetex.ru/upload"));
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }).start();
    }

    public static void sendFileQueue(String url, final AHandler<Boolean> handler) {
        if (sLiveTex != null) {
            sLiveTex.sendFile(url, handler);

        }
    }

    public static void setName(String name) {
        if (sLiveTex != null) {
            sLiveTex.setName(name);
        }
    }


    public void destroy() {
        sInstance = null;
    }
}
