package ru.simdev.livetex.utils;

import android.content.Context;
import android.content.SharedPreferences;

import java.util.HashSet;
import java.util.Set;
import java.util.SortedSet;

/**
 * Created by sergey.so on 02.12.2014.
 *
 */
public class DataKeeper {

    private static final String PREFERENCES = "com.livetex.cordovalivetex.PREFS";
    private static final String APP_ID_KEY = "com.livetex.cordovalivetex.application_id";
    private static final String EMPLOYEE_ID_KEY = "com.livetex.cordovalivetex.employeeId";
    private static final String REG_ID = "livetex.regId";
    private static final String LAST_MESSAGE = "livetex.lastMessage";
    private static final String NAME = "client_name";

    private static final String HH_USER = "livetex.hh.user";
    private static final String UNREAD_MESSAGES_COUNT = "livetex.hh.unreadMessagesCount";

    public static void setClientName(Context context, String name) {
        try {
            SharedPreferences pref = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE);
            pref.edit().putString(NAME, name).commit();
        } catch (NullPointerException e) { }
    }

    public static String getClientName(Context context) {
        try {
            return context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).getString(NAME, "");
        } catch (NullPointerException e) { }

        return "";
    }

    public static String getLastMessage(Context context) {
        try {
            return context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).getString(LAST_MESSAGE, "");
        } catch (NullPointerException e) { }

        return "";
    }

    public static void setHHUserData(Context context, Set<String> userData) {
        try {
            SharedPreferences pref = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE);
            pref.edit().putStringSet(HH_USER, userData).apply();
        } catch (NullPointerException e) { }
    }

    public static Set<String> getUserData(Context context) {
        try {
            SharedPreferences pref = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE);
            return pref.getStringSet(HH_USER, new HashSet<String>());
        } catch (NullPointerException e) { }

        return null;
    }

    public static void saveLastMessage(Context context, String lastMessage) {
        try {
            SharedPreferences pref = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE);
            pref.edit().putString(LAST_MESSAGE, lastMessage).apply();
        } catch (NullPointerException e) { }
    }

    public static void saveAppId(Context context, String appId) {
        try {
            SharedPreferences pref = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE);
            pref.edit()
                    .putString(APP_ID_KEY, appId)
                    .apply();
        } catch (NullPointerException e) { }
    }

    public static String restoreAppId(Context context) {
        try {
            SharedPreferences pref = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE);
         //   LogUtil.log("restoreToken " + pref.getString(APP_ID_KEY, ""));
            return pref.getString(APP_ID_KEY, "");
        } catch (NullPointerException e) { }

        return "";
    }

    public static void saveEmployee(Context context, String employeId) {
        try {
            SharedPreferences pref = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE);
            pref.edit()
                    .putString(EMPLOYEE_ID_KEY, employeId)
                    .apply();
        } catch (NullPointerException e) { }
    }

    public static String restoreEmployee(Context context) {
        try {
            SharedPreferences pref = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE);
            return pref.getString(EMPLOYEE_ID_KEY, "");
        } catch (NullPointerException e) { }

        return "";
    }

    public static void dropEmployeeId(Context context) {
        try {
            context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
                    .edit()
                    .remove(EMPLOYEE_ID_KEY)
                    .commit();
        } catch (NullPointerException e) { }
    }

    public static void dropAll(Context context) {
        try {
            String clientName = getClientName(context);
            context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
                    .edit()
                    .clear()
                    .commit();
            setClientName(context, clientName);
        } catch (NullPointerException e) { }
    }

    public static void saveRegId(Context context, String regId) {
        try {
            context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
                    .edit().putString(REG_ID, regId).commit();
        } catch (NullPointerException e) { }
    }

    public static String restoreRegId(Context context) {
        try {
            return context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).getString(REG_ID, "");
        } catch (NullPointerException e) { }

        return "";
    }

    public synchronized static void incUnreadMessages(Context context) {
        try {
            SharedPreferences prefs = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE);
            int unreadMessagesCount = prefs.getInt(UNREAD_MESSAGES_COUNT, 0);
            prefs.edit().putInt(UNREAD_MESSAGES_COUNT, unreadMessagesCount+1).commit();
        } catch (NullPointerException e) { }
    }

    public synchronized static int getUnreadMessagesCount(Context context) {
        try {
            return context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).getInt(UNREAD_MESSAGES_COUNT, 0);
        } catch (NullPointerException e) { }

        return 0;
    }

    public static void resetUnreadMessagesCount(Context context) {
        try {
            context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).edit().putInt(UNREAD_MESSAGES_COUNT, 0).commit();
        } catch (NullPointerException e) { }
    }
}
