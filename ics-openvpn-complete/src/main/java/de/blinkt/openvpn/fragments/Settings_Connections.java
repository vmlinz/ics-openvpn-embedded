/*
 * Copyright (c) 2012-2014 Arne Schwabe
 * Distributed under the GNU GPL v2 with additional terms. For full terms see the file doc/LICENSE.txt
 */

package de.blinkt.openvpn.fragments;

import android.app.Fragment;
import android.os.Build;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Checkable;
import android.widget.ImageButton;
import android.widget.TextView;

import de.blinkt.openvpn.R;
import de.blinkt.openvpn.VpnProfile;
import de.blinkt.openvpn.core.ProfileManager;

public class Settings_Connections extends Settings_Fragment implements View.OnClickListener {
    private ConnectionsAdapter mConnectionsAdapter;
    private TextView mWarning;
    private Checkable mUseRandomRemote;
    private RecyclerView mRecyclerView;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);


        setHasOptionsMenu(true);
    }

    @Override
    public void onCreateOptionsMenu(Menu menu, MenuInflater inflater) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP)
            inflater.inflate(R.menu.openvpn_connections, menu);
        super.onCreateOptionsMenu(menu, inflater);
    }

    @Nullable
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View v = inflater.inflate(R.layout.openvpn_connections, container, false);

        mWarning = (TextView) v.findViewById(R.id.openvpn_noserver_active_warning);
        mRecyclerView = (RecyclerView) v.findViewById(R.id.openvpn_connection_recycler_view);

        int dpwidth = (int) (container.getWidth()/getResources().getDisplayMetrics().density);
        int columns = dpwidth/290;
        columns = Math.max(1, columns);

        mConnectionsAdapter = new ConnectionsAdapter(getActivity(), this, mProfile);

        //mRecyclerView.setLayoutManager(new StaggeredGridLayoutManager(columns, StaggeredGridLayoutManager.VERTICAL));
        mRecyclerView.setHasFixedSize(true);
        mRecyclerView.setLayoutManager(new LinearLayoutManager(getActivity(),LinearLayoutManager.VERTICAL,false));
        mRecyclerView.setAdapter(mConnectionsAdapter);


        ImageButton fab_button = (ImageButton) v.findViewById(R.id.openvpn_add_new_remote);
        if(fab_button!=null)
                fab_button.setOnClickListener(this);

        mUseRandomRemote = (Checkable) v.findViewById(R.id.openvpn_remote_random);
        mUseRandomRemote.setChecked(mProfile.mRemoteRandom);


        mConnectionsAdapter.displayWarningifNoneEnabled();

        return v;
    }

    @Override
    public void onClick(View v) {
        if (v.getId() == R.id.openvpn_add_new_remote) {
            mConnectionsAdapter.addRemote();
        }
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId()==R.id.openvpn_add_new_remote)
            mConnectionsAdapter.addRemote();
        return super.onOptionsItemSelected(item);
    }

    @Override
    protected void savePreferences() {
        mConnectionsAdapter.saveProfile();
        mProfile.mRemoteRandom = mUseRandomRemote.isChecked();
    }

    public void setWarningVisible(int showWarning) {
        mWarning.setVisibility(showWarning);
    }
}
