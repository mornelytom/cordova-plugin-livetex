package ru.simdev.livetex.fragments;

import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.os.ResultReceiver;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ImageView;
import android.widget.Toast;

import androidx.annotation.Nullable;

import com.squareup.otto.Subscribe;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;

import livetex.livetex_service.LivetexService;
import livetex.queue_service.Destination;
import livetex.queue_service.FileMessage;
import livetex.queue_service.Message;
import livetex.queue_service.MessageAttributes;
import livetex.queue_service.SendMessageResponse;
import permissions.dispatcher.NeedsPermission;
import permissions.dispatcher.RuntimePermissions;
import ru.simdev.evo.video.R;
import ru.simdev.livetex.Const;
import ru.simdev.livetex.FragmentEnvironment;
import ru.simdev.livetex.LivetexContext;
import ru.simdev.livetex.fragments.dialogs.AttachChooseDialog;
import ru.simdev.livetex.fragments.dialogs.FileManagerDialog;
import ru.simdev.livetex.models.EventMessage;
import ru.simdev.livetex.models.MessageModel;
import ru.simdev.livetex.services.DownloadService;
import ru.simdev.livetex.utils.CommonUtils;
import ru.simdev.livetex.utils.DataKeeper;
import ru.simdev.livetex.utils.LivetexUtils;
import sdk.handler.AHandler;
import sdk.models.LTDialogAttributes;
import sdk.models.LTEmployee;
import sdk.models.LTFileMessage;
import sdk.models.LTSerializableHolder;
import sdk.models.LTTextMessage;
import sdk.utils.FileUtils;

/**
 * Created by dev on 02.06.16.
 */

@RuntimePermissions
public class OnlineChatFragment1 extends BaseChatFragment1 {

    private static final String TAG = "Livetex";

    private String avatar;
    private String name;

    private boolean isDialogClosed;

    private int prevHistoryCount;
    private boolean allHistoryDownloaded;
    private String lastMessageId = "";

    public static boolean isActive;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (!isStoragePermissionsGranted()) {
            OnlineChatFragment1PermissionsDispatcher.initWithExternalStorageWithCheck(OnlineChatFragment1.this);
        }
    }

    @Override
    protected View onCreateView(View v) {
        super.onCreateView(v);

        isActive = true;

        ImageView ivSendFile = (ImageView) v.findViewById(R.id.ivSendFile);
        ivSendFile.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                AttachChooseDialog dialog = new AttachChooseDialog();
                dialog.setTargetFragment(OnlineChatFragment1.this, CHOOSER_DIALOG_REQUEST);

                if (!isStoragePermissionsGranted()) {
                    dialog.showAllowingStateLoss(getFragmentEnvironment().getSupportFragmentManager(), "AttachChooseDialog");
                } else {
                    dialog.show(getFragmentEnvironment().getSupportFragmentManager(), "AttachChooseDialog");
                }
            }
        });

        LivetexContext.removeMessagesFlag();

        return v;
    }

    private void updateMessageHistory(int offset, int limit, final boolean scrollDown) {
        Log.d(TAG, "updateMessageHistory");
        pbHistory.setVisibility(View.VISIBLE);
        LivetexContext.getLastMessages(offset, limit, new AHandler<LTSerializableHolder>() {
            @Override
            public void onError(String errMsg) {
                pbHistory.setVisibility(View.GONE);
                dismissProgress();
            }

            @Override
            public void onResultRecieved(LTSerializableHolder result1) {
                if (result1 == null) {
                    pbHistory.setVisibility(View.GONE);
                    return;
                }

                List<Message> result = (List<Message>) result1.getSerializable();
                if (result != null) {
                    ArrayList<MessageModel> messages = new ArrayList<>();
                    for (Message message2 : result) {
                        if (message2.attributes.isSetText()) {
                            livetex.queue_service.TextMessage message1 = (livetex.queue_service.TextMessage) message2.attributes.getFieldValue(MessageAttributes._Fields.TEXT);
                            String created = (String) message1.getFieldValue(livetex.queue_service.TextMessage._Fields.CREATED);
                            String sender = (String) message1.getFieldValue(livetex.queue_service.TextMessage._Fields.SENDER);
                            String text = (String) message1.getFieldValue(livetex.queue_service.TextMessage._Fields.TEXT);
                            MessageModel messageModel = new MessageModel(!(sender != null), text, created, conversationId, sender == null ? null : avatar, sender == null ? null : name);
                            messages.add(messageModel);
                        } else if (message2.attributes.isSetFile()) {
                            livetex.queue_service.FileMessage messageFile = (livetex.queue_service.FileMessage) message2.attributes.getFieldValue(MessageAttributes._Fields.FILE);
                            String created = (String) messageFile.getFieldValue(FileMessage._Fields.CREATED);
                            String sender = (String) messageFile.getFieldValue(FileMessage._Fields.SENDER);
                            String text = (String) messageFile.getFieldValue(FileMessage._Fields.URL);
                            MessageModel messageModel = new MessageModel(!(sender != null), text, created, conversationId, sender == null ? null : avatar, sender == null ? null : name);
                            messages.add(messageModel);
                        }

                    }
                    allHistoryDownloaded = (prevHistoryCount == messages.size()) ? true : false;
                    prevHistoryCount = messages.size();
                    Collections.reverse(messages);
                    adapter.setData(messages);
                    if (scrollDown) {
                        lvChat.setSelection(adapter.getCount() - 1);
                    }
                    if (allHistoryDownloaded) {
                        lvChat.setOnScrollListener(null);
                    }
                }
                pbHistory.setVisibility(View.GONE);

                LivetexContext.sendCallback("updated");
            }
        });

    }

    @Override
    public void onResume() {
        super.onResume();

        DataKeeper.resetUnreadMessagesCount(getContext());

        handler.postDelayed(() -> updateMessageHistory(0, 100, true), 500);

        handler.post(new GetDialogStateTask());
        // todo: not required, updateDialogState should be used
        handler.postDelayed(new GetDialogStateTask(), 7000);

        isActive = true;
    }

    @Override
    public void onPause() {
        super.onPause();
        isActive = false;
    }

    @Override
    public void onStop() {
        super.onStop();
        isActive = false;
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        isActive = false;
    }

    private class GetDialogStateTask implements Runnable {

        @Override
        public void run() {
            LivetexContext.getStateQueue(new AHandler<livetex.queue_service.DialogState>() {
                @Override
                public void onError(String errMsg) {
                    Log.e(TAG, "GetDialogStateTask: error " + errMsg);
                }

                @Override
                public void onResultRecieved(livetex.queue_service.DialogState result) {
                    setHeaderData(result);
                }
            });
        }
    }

    private void setHeaderData(livetex.queue_service.DialogState result) {
        if (result == null || result.getEmployee() == null) {
            return;
        }
        Log.w(TAG, "getAvatar: " + result.getEmployee().getAvatar());
        setHeaderData(result.getEmployee().getAvatar(), result.getEmployee().getFirstname(), result.getEmployee().getLastname());
        setConversationId(result.getEmployee().getEmployeeId());
        sendingMessagesEnabled(true);
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        OnlineChatFragment1PermissionsDispatcher.onRequestPermissionsResult(this, requestCode, grantResults);
    }

    @Subscribe
    public void onMessageReceive(EventMessage eventMessage) {
        Log.d(TAG, "onMessageReceive");

        switch (eventMessage.getMessageType()) {
            case UPDATE_STATE:
                LTEmployee employee = (LTEmployee) eventMessage.getSerializable();

                setHeaderData(employee.getAvatar(), employee.getFirstname(), employee.getLastname());
                setConversationId(employee.getEmployeeId());
                sendingMessagesEnabled(true);

                if (!lastMessageId.equals("OPEN_DIALOG")) {
                    scrollWithMessage(false, "OPEN_DIALOG", String.valueOf(System.currentTimeMillis()), employee.getAvatar(), employee.getFirstname() + " " + employee.getLastname());
                }

                lastMessageId = "OPEN_DIALOG";
                break;
            case CLOSE:
                setHeaderData(null, "Оператор", "");
                if (!lastMessageId.equals("CLOSE_DIALOG")) {
                    scrollWithMessage(false, "CLOSE_DIALOG", String.valueOf(System.currentTimeMillis()), null, null);
                }
                lastMessageId = "CLOSE_DIALOG";
                break;
            case TYPING_MESSAGE:
                Log.d(TAG, "typing...");
                break;
            case RECEIVE_QUEUE_MSG:
                Log.d(TAG, "RECEIVE_QUEUE_MSG");

                LTTextMessage textMessage = (LTTextMessage) eventMessage.getSerializable();
                LivetexContext.confirmQueueMessage(textMessage.getId());
                if (!lastMessageId.equals(textMessage.getId())) {
                    scrollWithMessage(false, textMessage.getText(), textMessage.timestamp, avatar, name);
                }
                lastMessageId = textMessage.getId();
                LivetexContext.sendCallback("updated");
                break;

            case RECEIVE_FILE:
                LTFileMessage fileMessage = (LTFileMessage) eventMessage.getSerializable();
                showProgress();
                scrollWithMessage(false, fileMessage.getText(), String.valueOf(System.currentTimeMillis()), avatar, name);
                dismissProgress();
                LivetexContext.sendCallback("updated");
                break;
        }

    }

    @Override
    public View getCustomActionBarView(LayoutInflater inflater, int actionBarHeight) {
        View header = inflater.inflate(R.layout.livetex_header_chat1, null);

        ImageView ivGoBack = (ImageView) header.findViewById(R.id.ivGoBack);
        ivGoBack.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                getActivity().onBackPressed();
            }
        });

        return header;
    }

    private boolean isStoragePermissionsGranted() {
        int sdk = android.os.Build.VERSION.SDK_INT;
        if (sdk < 23) return true;
        int i = FragmentEnvironment.fa.checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE);
        return i == PackageManager.PERMISSION_GRANTED;
    }

    @NeedsPermission({Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE})
    void initWithExternalStorage() {
    }

    @NeedsPermission(Manifest.permission.CAMERA)
    void initWithCamera() {
        try {
            takePictureByCam();
        } catch (Exception e) {
            e.printStackTrace();
            dismissProgress();
            Toast.makeText(getContext(), "Unable to take photo", Toast.LENGTH_SHORT).show();
        }
    }

    @Override
    protected void sendFileFromUri(final String path1) {
        if (path1 == null) {
            LivetexUtils.showToast(getContext(), "Файл не доступен для загрузки");
            return;
        }

        final File file = new File(path1);
        showProgress();
        new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    String endpoint = sdk.data.DataKeeper.restoreEndpoint(getContext(), LivetexService.FILE);
                    String response = FileUtils.sendMultipart(file, endpoint);
                    JSONObject jo = new JSONObject(response);
                    String path = jo.getString("path");
                    final String url = endpoint + path;
                    getHandler().post(new Runnable() {
                        @Override
                        public void run() {

                            LivetexContext.sendFileQueue(url, null);
                            scrollWithFile(true, url, String.valueOf(System.currentTimeMillis()), null, null);
                            dismissProgress();
                        }
                    });

                    Log.d(TAG, response);
                } catch (IOException e) {
                    e.printStackTrace();
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
        }).start();

    }

    private void scrollWithMessage(boolean isVisitor, String message, String time, String avatar, String name) {
        adapter.setData(new MessageModel(isVisitor, message, time, conversationId, avatar, name));
        lvChat.setSelection(lvChat.getCount() - 1);
    }

    private void scrollWithFile(boolean isVisitor, String message, String time, String avatar, String name) {
        adapter.setData(new MessageModel(isVisitor, message, time, conversationId, avatar, name));
    }

    @Override
    public void sendMessage(final String message) {
        handler.postDelayed(() -> {
            scrollWithMessage(true, message, String.valueOf(System.currentTimeMillis()), null, null);
        }, 200);

        LivetexContext.sendTextMessage(message, new AHandler<SendMessageResponse>() {
            @Override
            public void onError(String errMsg) {
                Log.d(TAG, "sendTextMessage error:" + errMsg);
            }

            @Override
            public void onResultRecieved(SendMessageResponse result) {
                Log.d(TAG, "sendTextMessage " + result.toString());

                if (result.destination == null) {
                    LivetexContext.getDestinations(new AHandler<ArrayList<Destination>>() {
                        @Override
                        public void onError(String errMsg) {
                        }

                        @Override
                        public void onResultRecieved(final ArrayList<Destination> destinations) {
                            if (destinations != null && destinations.size() != 0) {
                                Destination destination = destinations.get(0);
                                if (destination != null) {
                                    LivetexContext.setDestination(destination, new LTDialogAttributes(new HashMap<String, String>()));
                                    LivetexContext.currentConversation = destination.getTouchPoint().getTouchPointId();
                                }
                            } else {
                                CommonUtils.showToast(getContext(), "Нет доступных операторов");
                            }
                        }
                    });
                }
            }
        });
    }

    private void setHeaderData(@Nullable String avatar, String firstName, String lastName) {
        if (avatar != null && avatar.indexOf("http") == -1) {
            this.avatar = "https://static.livetex.ru/" + avatar;
        } else {
            this.avatar = avatar;
        }

        this.name = firstName + " " + lastName;
    }

    private void sendingMessagesEnabled(boolean enabled) {
        etInputMsg.setEnabled(enabled);
        ivSendMsg.setEnabled(enabled);
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        switch (requestCode) {
            case Const.CODE.FILE_SELECT:
                if (data != null) {
                    Uri uri = data.getData();
                    sendFileFromUri(LivetexUtils.getPath(getContext(), uri));
                }
                break;
            case CHOOSER_DIALOG_REQUEST:
                if (resultCode == AttachChooseDialog.TAKE_FILE) {
                    takeFile();
                } else if (resultCode == AttachChooseDialog.TAKE_PICTURE_BY_CAM) {
                    if (getContext().getPackageManager().hasSystemFeature(PackageManager.FEATURE_CAMERA) && android.os.Environment.getExternalStorageState().equals(android.os.Environment.MEDIA_MOUNTED)) {
                        OnlineChatFragment1PermissionsDispatcher.initWithCameraWithCheck(OnlineChatFragment1.this);
                    } else {
                        Toast.makeText(getContext(), "Taking photos is not available", Toast.LENGTH_SHORT).show();
                    }
                } else if (resultCode == AttachChooseDialog.TAKE_GALLERY_PICTURE) {
                    takeGalleryPicture();
                }
                break;
            case SELECT_PICTURE_REQUEST:
                if (data != null) {
                    Uri uri = data.getData();
                    Uri pathUri = LivetexUtils.getRealPathFromURI(getContext(), uri);
                    if (pathUri != null) {
                        sendFileFromUri(pathUri.toString());
                    } else {
                        LivetexUtils.showToast(getContext(), "Пожалуйста,выберите другой файл");
                    }

                }
                break;
            case CHOOSER_FILE_REQUEST:
                if (resultCode == FileManagerDialog.TAKE_FILE_URI) {
                    if (data != null) {
                        Uri uri = data.getData();
                        sendFileFromUri(LivetexUtils.getPath(getContext(), uri));
                    }
                }
                break;
            case CAPTURE_IMAGE_REQUEST:
                sendFileFromUri(LivetexUtils.getPath(getContext(), mTakenPhotoUri));

                break;
        }

        super.onActivityResult(requestCode, resultCode, data);
    }

    private void updateChatWithFilePath(String path) {
        dismissProgress();
        scrollWithMessage(true, path, String.valueOf(System.currentTimeMillis()), null, null);
    }

    private class DownloadReceiver extends ResultReceiver {
        public DownloadReceiver(Handler handler) {
            super(handler);
        }

        @Override
        protected void onReceiveResult(int resultCode, Bundle resultData) {
            super.onReceiveResult(resultCode, resultData);
            if (resultCode == DownloadService.UPDATE_PROGRESS) {
                int progress = resultData.getInt("progress");
                if (progress == 100) {
                    dismissProgress();
                    lvChat.setSelection(lvChat.getCount() - 1);
                }
            }
        }
    }

}