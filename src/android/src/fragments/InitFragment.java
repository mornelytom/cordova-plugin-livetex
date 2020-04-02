package ru.simdev.livetex.fragments;

import android.view.View;

import ru.simdev.evo.life.R;
import ru.simdev.livetex.fragments.callbacks.InitCallback;
import ru.simdev.livetex.fragments.presenters.InitPresenter;
import ru.simdev.livetex.models.BaseMessage;
import ru.simdev.livetex.models.ErrorMessage1;
import ru.simdev.livetex.models.EventMessage;
import ru.simdev.livetex.utils.CommonUtils;
import com.squareup.otto.Subscribe;

/**
 * Created by user on 28.07.15.
 */
public class InitFragment extends BaseFragment implements InitCallback {

    private InitPresenter presenter;

    @Override
    protected View onCreateView(View v) {
        showProgress();
        presenter = new InitPresenter(this);
        presenter.init("161872");
        return super.onCreateView(v);
    }

    @Override
    protected int getLayoutId() {
        return R.layout.livetex_fragment_init;
    }

    @Subscribe
    public void onEventMessage(EventMessage eventMessage) {
        if(eventMessage.getMessageType() == BaseMessage.TYPE.INIT) {
            onInitComplete(eventMessage.getStringExtra());
        }
    }

    public void onErrorMessage(ErrorMessage1 errorMessage1) {
        if(errorMessage1.getMessageType() == BaseMessage.TYPE.INIT) {

        }
    }

    @Override
    public void onInitComplete(String token) {
        dismissProgress();
        showFragment(new ChooseModeFragment());
    }

    @Override
    public void onClear() {
        CommonUtils.showToast(getContext(), "Cache is clear");
    }


}


















