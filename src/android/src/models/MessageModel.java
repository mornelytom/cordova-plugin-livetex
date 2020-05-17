package ru.simdev.livetex.models;

import sdk.models.LTTextMessage;

/**
 * Created by dev on 02.06.16.
 */
public class MessageModel {

    private String id;
    private boolean isVisitorMessage;
    private String text;
    private String date;
    private String conversationId;
    private String httpLink = "";
    private String avatar;
    private String name;

    public MessageModel(boolean isVisitorMessage, String text, String date, String conversationId, String avatar, String name) {
        this.isVisitorMessage = isVisitorMessage;
        this.text = text;
        this.date = date;
        this.conversationId = conversationId;
        this.avatar = avatar;
        this.name = name;
    }

    public MessageModel(LTTextMessage message) {
        this.isVisitorMessage = false;
        this.text = message.getText();
        this.date = message.getTimestamp();
        this.conversationId = message.getSender();
        this.avatar = null;
        this.name = null;
    }

    public String getId() {
        return id;
    }

    public boolean isVisitorMessage() {
        return isVisitorMessage;
    }

    public String getText() {
        return text;
    }

    public String getDate() {
        return date;
    }

    public String getConversationId() {
        return conversationId;
    }

    public String getHttpLink() {
        return httpLink;
    }

    public void setHttpLink(String httpLink) {
        this.httpLink = httpLink;
    }

    public String getAvatar() { return avatar; }

    public String getName() { return name; }
}
