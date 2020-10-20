package ru.simdev.livetex.view;

import android.content.Context;
import android.graphics.Typeface;
import android.util.AttributeSet;

import androidx.appcompat.widget.AppCompatTextView;

public class TextViewRobotoBold extends AppCompatTextView {

    public TextViewRobotoBold(Context context) {
        super(context);
    }

    public TextViewRobotoBold(Context context, AttributeSet attrs) {
        super(context, attrs);
        init(context);
    }

    private void init(Context context) {
        Typeface myTypeface = Typeface.createFromAsset(context.getAssets(), "www/assets/fonts/Montserrat/Montserrat-SemiBold.ttf");
        setTypeface(myTypeface);
    }
}
