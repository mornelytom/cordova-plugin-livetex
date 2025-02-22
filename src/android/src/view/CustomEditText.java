package ru.simdev.livetex.view;

import android.content.Context;
import android.graphics.Color;
import android.graphics.PorterDuff;
import android.graphics.Typeface;
import android.util.AttributeSet;
import android.view.View;

import androidx.appcompat.widget.AppCompatEditText;

import ru.simdev.evo.video.R;

/**
 * Created by user on 13.09.15.
 */
public class CustomEditText extends AppCompatEditText {
    public CustomEditText(Context context) {
        super(context);
    }

    public CustomEditText(Context context, AttributeSet attrs) {
        super(context, attrs);
        init(context);
    }

    public CustomEditText(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    private void init(Context context) {
        Typeface myTypeface = Typeface.createFromAsset(context.getAssets(), "www/assets/fonts/FuturaNew/FuturaNewBook-Reg.ttf");
        setTypeface(myTypeface);
        getBackground().setColorFilter(Color.GRAY, PorterDuff.Mode.SRC_ATOP);
        setOnFocusChangeListener(new OnFocusChangeListener() {
            @Override
            public void onFocusChange(View view, boolean b) {
                if(b){
                    getBackground().setColorFilter(getResources().getColor(R.color.new_blue), PorterDuff.Mode.SRC_ATOP);
                } else {
                    getBackground().setColorFilter(Color.GRAY, PorterDuff.Mode.SRC_ATOP);
                }

            }
        });
    }
}
