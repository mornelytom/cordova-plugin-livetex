package ru.simdev.livetex.fragments;

import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;
import android.widget.Button;

import java.util.ArrayList;
import java.util.List;

import livetex.queue_service.Destination;
import ru.simdev.livetex.LivetexContext;
import ru.simdev.evo.life.R;
import ru.simdev.livetex.fragments.callbacks.ClientFormCallback;
import ru.simdev.livetex.fragments.presenters.ClientFormPresenter;
import ru.simdev.livetex.utils.DataKeeper;
import sdk.handler.AHandler;
import sdk.models.LTDepartment;
import sdk.models.LTEmployee;

/**
 * Created by user on 28.07.15.
 */
public class ChooseModeFragment extends BaseFragment implements ClientFormCallback, View.OnClickListener {

    Button btnOnlineMode;

    ArrayList<Destination> destinations;

    @Override
    protected int getLayoutId() {
        return R.layout.livetex_choose_mode;
    }

    private void init(View v) {
        btnOnlineMode = (Button) v.findViewById(R.id.btnOnlineMode);
        btnOnlineMode.setOnClickListener(this);
    }

    @Override
    public void onClick(View view) {
        switch (view.getId()) {
            case R.id.btnOnlineMode:
                if(TextUtils.isEmpty(DataKeeper.getClientName(getContext()))) {
                    showFragment(new nit.livetex.cordovalivetex.fragments.ClientFormFragment(), true);
                } else {
                    showProgress();
                    if(destinations != null && !destinations.isEmpty()) {
                        Destination destination = destinations.get(0);
                        ClientFormPresenter.sendToDestination(getContext(), destination, DataKeeper.getClientName(getContext()), this);
                    }
                }

                break;
        }
    }

    @Override
    protected View onCreateView(View v) {
        init(v);
        btnOnlineMode.setBackground(getContext().getResources().getDrawable(R.drawable.livetex_gray_btn));

        LivetexContext.getDestinations(new AHandler<ArrayList<Destination>>() {
            @Override
            public void onError(String errMsg) {

            }

            @Override
            public void onResultRecieved(ArrayList<Destination> destinations) {
                if(destinations != null && destinations.size() != 0) {
                    ChooseModeFragment.this.destinations = destinations;
                    btnOnlineMode.setEnabled(true);
                    btnOnlineMode.setBackground(getContext().getResources().getDrawable(R.drawable.livetex_blue_btn));
                }
            }
        });


        return super.onCreateView(v);
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
        showFragment(new nit.livetex.cordovalivetex.fragments.OnlineChatFragment1(), bundle);
    }

    @Override
    public void onEmployeesEmpty() {

    }

    @Override
    public void onDepartmentsEmpty() {

    }
}





















