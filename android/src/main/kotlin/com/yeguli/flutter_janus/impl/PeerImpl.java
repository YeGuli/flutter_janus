package com.yeguli.flutter_janus.impl;

import android.content.Context;

import com.github.helloiampau.janus.generated.Bundle;
import com.github.helloiampau.janus.generated.Constraints;
import com.github.helloiampau.janus.generated.JanusConf;
import com.github.helloiampau.janus.generated.Peer;
import com.github.helloiampau.janus.generated.Protocol;
import com.github.helloiampau.janus.generated.ProtocolDelegate;
import com.github.helloiampau.janus.generated.SdpType;

public class PeerImpl extends Peer {
    private final String TAG = "PeerImpl";
    private Context _appContext;
    private Protocol _owner;
    private ProtocolDelegate _delegate;
    private PeerDelegate _peerDelegate;

    private long _id;
    private String _publisherId;

    public PeerImpl(long id, String publisherId, JanusConf conf, Protocol owner, ProtocolDelegate delegate, PeerDelegate peerDelegate, Context appContext) {
        this._id = id;
        this._publisherId = publisherId;

        this._appContext = appContext;
        this._owner = owner;
        this._delegate = delegate;
        this._peerDelegate = peerDelegate;

        this._peerDelegate.onInitProtocol(id, _publisherId, owner);
    }

    @Override
    public void createOffer(Constraints constraints, Bundle context) {
        if (_peerDelegate != null) {
            _peerDelegate.onCreateOffer(_id, _publisherId, constraints, context);
        }
    }

    @Override
    public void createAnswer(Constraints constraints, Bundle context) {
        if (_peerDelegate != null) {
            _peerDelegate.onCreateAnswer(_id, _publisherId, constraints, context);
        }
    }

    @Override
    public void setLocalDescription(SdpType type, String sdp) {
        if (_peerDelegate != null) {
            _peerDelegate.onSetLocalDescription(_id, _publisherId, type, sdp);
        }
    }

    @Override
    public void setRemoteDescription(SdpType type, String sdp) {
        if (_peerDelegate != null) {
            _peerDelegate.onSetRemoteDescription(_id, _publisherId, type, sdp);
        }
    }

    @Override
    public void addIceCandidate(String mid, int index, String sdp) {
        if (_peerDelegate != null) {
            _peerDelegate.onAddIceCandidate(_id, _publisherId, mid, index, sdp);
        }
    }

    @Override
    public void close() {
        if (_peerDelegate != null) {
            _peerDelegate.onPeerClose(_id, _publisherId);
        }
    }

    public interface PeerDelegate {
        void onInitProtocol(long id, String publisherId, Protocol owner);

        void onCreateOffer(long id, String publisherId, Constraints constraints, Bundle context);

        void onCreateAnswer(long id, String publisherId, Constraints constraints, Bundle context);

        void onSetLocalDescription(long id, String publisherId, SdpType type, String sdp);

        void onSetRemoteDescription(long id, String publisherId, SdpType type, String sdp);

        void onAddIceCandidate(long id, String publisherId, String mid, int index, String sdp);

        void onPeerClose(long id, String publisherId);
    }
}
