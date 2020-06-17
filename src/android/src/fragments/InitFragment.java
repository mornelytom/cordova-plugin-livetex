package ru.simdev.livetex.fragments;

import android.os.Bundle;
import android.util.Log;
import android.view.View;

import java.util.ArrayList;
import java.util.List;

import livetex.queue_service.Destination;
import ru.simdev.evo.video.R;
import ru.simdev.livetex.LivetexContext;
import ru.simdev.livetex.fragments.callbacks.ClientFormCallback;
import ru.simdev.livetex.fragments.presenters.ClientFormPresenter;
import ru.simdev.livetex.fragments.presenters.InitPresenter;
import ru.simdev.livetex.utils.DataKeeper;
import sdk.handler.AHandler;
import sdk.models.LTDepartment;
import sdk.models.LTEmployee;

/**
 * Created by user on 28.07.15.
 */
public class InitFragment extends BaseFragment implements ClientFormCallback {

    private InitPresenter presenter;

    @Override
    protected View onCreateView(View v) {
        showProgress();

        LivetexContext.getDestinations(new AHandler<ArrayList<Destination>>() {
            @Override
            public void onError(String errMsg) {
                Log.e("Livetext", "error " + errMsg);
            }

            @Override
            public void onResultRecieved(ArrayList<Destination> destinations) {
                if (destinations != null && !destinations.isEmpty()) {
                    Destination destination = destinations.get(0);
                    ClientFormPresenter.sendToDestination(getContext(), destination, DataKeeper.getClientName(getContext()), InitFragment.this);
                }
            }
        });

        return super.onCreateView(v);
    }

    @Override
    protected int getLayoutId() {
        return R.layout.livetex_fragment_init;
    }

    @Override
    public void onEmployeesReceived(List<LTEmployee> operators) {

    }

    @Override
    public void onDepartmentsReceived(List<LTDepartment> departments) {

    }

    @Override
    public void onDestinationsReceived(List<Destination> destinations) {

    }

    @Override
    public void createChat(String conversationId, String avatar, String firstName) {

    }

    @Override
    public void createChat() {
        dismissProgress();
        Bundle bundle = new Bundle();
        showFragment(new OnlineChatFragment1(), bundle);
    }

    @Override
    public void onEmployeesEmpty() {

    }

    @Override
    public void onDepartmentsEmpty() {

    }

}


















