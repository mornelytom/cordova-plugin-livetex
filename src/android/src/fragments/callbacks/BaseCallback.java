package ru.simdev.livetex.fragments.callbacks;

import android.content.Context;

import ru.simdev.livetex.FragmentEnvironment;

/**
 * Created by user on 28.07.15.
 */
public interface BaseCallback {
    public Context getContext();
    public FragmentEnvironment getFragmentEnvironment();
}
