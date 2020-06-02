package com.yeguli.flutter_janus;

import android.content.Context;

import com.github.helloiampau.janus.generated.Janus;
import com.github.helloiampau.janus.generated.JanusConf;
import com.github.helloiampau.janus.generated.PeerFactory;
import com.github.helloiampau.janus.generated.Platform;
import com.github.helloiampau.janus.generated.PluginFactory;
import com.github.helloiampau.janus.generated.Protocol;
import com.github.helloiampau.janus.generated.ProtocolDelegate;
import com.yeguli.flutter_janus.impl.PeerFactoryImpl;
import com.yeguli.flutter_janus.impl.PeerImpl;

import java.util.HashMap;
import java.util.Map;

public class JanusFactory {

    static {
        System.loadLibrary("janus-android-sdk");
    }

    private Protocol _protocol;
    private Map<String, PluginFactory> _plugins = new HashMap<>();

    public void protocol(Protocol protocol) {
        this._protocol = protocol;
    }

    public void pluginFactory(String id, PluginFactory factory) {
        this._plugins.put(id, factory);
    }

    public Janus create(JanusConf conf, ProtocolDelegate delegate, PeerImpl.PeerDelegate peerDelegate, Context appContext) {
        PeerFactory factory = new PeerFactoryImpl(conf, delegate, appContext, peerDelegate);
        Platform platform = Platform.create(factory);

        if (this._protocol != null) {
            platform.protocol(this._protocol);
        }

        for (String id : this._plugins.keySet()) {
            platform.pluginFactory(id, this._plugins.get(id));
        }

        return Janus.create(conf, platform, delegate);
    }

}
