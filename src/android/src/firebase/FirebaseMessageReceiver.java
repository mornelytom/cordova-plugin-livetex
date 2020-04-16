package ru.simdev.livetex.firebase;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;

import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;

import ru.simdev.evo.life.R;
import ru.simdev.livetex.FragmentEnvironment;
import ru.simdev.livetex.utils.DataKeeper;

public class FirebaseMessageReceiver extends FirebaseMessagingService {
    private static final String TAG = "Livetex";

    public static final int iconColor = 0xFF4A47EC;
    public static final String CHANNEL_ID = "EvolifeChatService";
    public static boolean channelInited = false;

    @Override
    public void onMessageReceived(RemoteMessage remoteMessage) {
        Log.d(TAG, remoteMessage.getFrom());
        sendNotification(remoteMessage);
    }

    @Override
    public void onNewToken(@NonNull String newToken) {
        // This token will start working on next Livetex init (app restart for now)
        DataKeeper.saveRegId(this, newToken);
    }

    private void sendNotification(RemoteMessage remoteMessage) {
        Log.d(TAG, "new push " + remoteMessage.getNotification().getBody());

        if (remoteMessage.getNotification() == null) {
            return;
        }

        Intent intent = new Intent(this.getApplicationContext(), FragmentEnvironment.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP | Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS);
        PendingIntent pendingIntent = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_ONE_SHOT);

        String messageTitle = remoteMessage.getNotification().getTitle();
        String messageText = remoteMessage.getNotification().getBody();

        Notification.Builder notificationBuilder = new Notification.Builder(this)
                        .setSmallIcon(R.drawable.icon)
                        .setContentTitle(messageTitle)
                        .setContentText(messageText)
                        .setAutoCancel(true)
                        .setContentIntent(pendingIntent);

        if (Build.VERSION.SDK_INT >= 21) {
            notificationBuilder.setColor(iconColor);
        }

        if (Build.VERSION.SDK_INT >= 26) {
            createNotificationChannel();
            notificationBuilder.setChannelId(CHANNEL_ID);
        }

        NotificationManager notificationManager =
                (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);

        notificationManager.notify(0 /* ID of notification */, notificationBuilder.build());
    }

    private void createNotificationChannel() {
        if (!channelInited && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationManager manager = this.getSystemService(NotificationManager.class);

            NotificationChannel callChannel = new NotificationChannel(
                    CHANNEL_ID,
                    "Evo Life Call Channel",
                    NotificationManager.IMPORTANCE_HIGH
            );
            manager.createNotificationChannel(callChannel);
        }
    }

}
