package ru.simdev.livetex.firebase;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.Build;

import androidx.annotation.NonNull;

import com.google.firebase.messaging.RemoteMessage;

import ru.simdev.evo.video.R;
import ru.simdev.livetex.FragmentEnvironment;
import ru.simdev.livetex.utils.DataKeeper;

public class FirebaseMessageReceiver {
    private static final String TAG = "Livetex";

    public static final int iconColor = 0xFF4A47EC;
    public static final String CHANNEL_ID = "EvolifeChatService";
    public static boolean channelInited = false;

    public static void saveToken(Context context, @NonNull String newToken) {
        // This token will start working on next Livetex init (app restart for now)
        DataKeeper.saveRegId(context, newToken);
    }

    public static void sendNotification(Context context, RemoteMessage remoteMessage) {
        if (remoteMessage.getNotification() == null) {
            return;
        }

        Intent intent = new Intent(context.getApplicationContext(), FragmentEnvironment.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP | Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS);
        PendingIntent pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_ONE_SHOT);

        String messageTitle = remoteMessage.getNotification().getTitle();
        String messageText = remoteMessage.getNotification().getBody();

        Notification.Builder notificationBuilder = new Notification.Builder(context)
                        .setSmallIcon(R.drawable.icon)
                        .setContentTitle(messageTitle)
                        .setContentText(messageText)
                        .setAutoCancel(true)
                        .setContentIntent(pendingIntent);

        if (Build.VERSION.SDK_INT >= 21) {
            notificationBuilder.setColor(iconColor);
        }

        if (Build.VERSION.SDK_INT >= 26) {
            createNotificationChannel(context);
            notificationBuilder.setChannelId(CHANNEL_ID);
        }

        NotificationManager notificationManager =
                (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);

        notificationManager.notify(0 /* ID of notification */, notificationBuilder.build());
    }

    public static void createNotificationChannel(Context context) {
        if (!channelInited && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationManager manager = context.getSystemService(NotificationManager.class);

            NotificationChannel callChannel = new NotificationChannel(
                    CHANNEL_ID,
                    "Evo Life Call Channel",
                    NotificationManager.IMPORTANCE_HIGH
            );
            manager.createNotificationChannel(callChannel);
        }
    }

}
