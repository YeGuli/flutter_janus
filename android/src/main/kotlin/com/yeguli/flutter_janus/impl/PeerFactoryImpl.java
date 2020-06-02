package com.yeguli.flutter_janus.impl;

import android.content.Context;

import com.github.helloiampau.janus.generated.JanusConf;
import com.github.helloiampau.janus.generated.Peer;
import com.github.helloiampau.janus.generated.PeerFactory;
import com.github.helloiampau.janus.generated.Protocol;
import com.github.helloiampau.janus.generated.ProtocolDelegate;

public class PeerFactoryImpl extends PeerFactory {

    private JanusConf _conf;
    private ProtocolDelegate _delegate;
    private Context _appContext;
    private PeerImpl.PeerDelegate _peerDelegate;

    public PeerFactoryImpl(JanusConf conf, ProtocolDelegate delegate, Context appContext, PeerImpl.PeerDelegate peerDelegate) {
        this._conf = conf;
        this._delegate = delegate;
        this._appContext = appContext;
        this._peerDelegate = peerDelegate;
    }

    @Override
    public Peer create(long id, String publisher, Protocol owner) {
        return new PeerImpl(id, publisher, this._conf, owner, this._delegate, this._peerDelegate, this._appContext);
    }

}
