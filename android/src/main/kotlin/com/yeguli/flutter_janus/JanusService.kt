package com.yeguli.flutter_janus

import android.app.Activity
import com.github.helloiampau.janus.generated.*
import com.yeguli.flutter_janus.impl.CustomPlugin
import com.yeguli.flutter_janus.impl.CustomPluginFactory
import com.yeguli.flutter_janus.impl.JanusConfImpl
import com.yeguli.flutter_janus.impl.PeerImpl
import io.flutter.plugin.common.EventChannel

/**
 * Created by Ye_Guli on 2020/4/30.
 */
class JanusService// adding an useless plugin
(activity: Activity?, conf: JanusConfImpl?, private val delegate: ServiceDelegate?, peerDelegate: PeerImpl.PeerDelegate?) : ProtocolDelegate() {
    var status: Int = STATUS_CLOSE
    private var janus: Janus? = null
    private var janusPlugin: CustomPlugin? = null

    init {
        status = STATUS_OFF
        val pluginFactory = CustomPluginFactory()
        janusPlugin = pluginFactory.plugin
        val factory = JanusFactory()
        factory.pluginFactory("my.yolo.plugin", pluginFactory)
        janus = factory.create(conf, this, peerDelegate, activity?.applicationContext)
    }

    companion object {
        const val STATUS_CLOSE = 0X011
        const val STATUS_OFF = 0X012
        const val STATUS_READY = 0X013
    }

    fun start() {
        janus?.init()
    }

    fun stop() {
        janus?.close()
    }

    fun hangup() {
        janus?.hangup()
    }

    fun dispatch(command: String?, payload: Bundle?) {
        janus?.dispatch(command, payload)
    }

    override fun onReady() {
        status = STATUS_READY
        delegate?.onJanusReady()
    }

    override fun onHangup(reason: String?) {
        status = STATUS_READY
        delegate?.onJanusHangup(reason)
    }

    override fun onClose() {
        status = STATUS_CLOSE
        delegate?.onJanusClose()
    }

    override fun onEvent(event: JanusEvent?, context: Bundle?) {
        delegate?.onJanusEvent(event, context)
    }

    override fun onError(error: JanusError?, context: Bundle?) {
        delegate?.onJanusError(error, context)
    }
}

interface ServiceDelegate {
    fun onJanusEvent(event: JanusEvent?, payload: Bundle?)
    fun onJanusError(error: JanusError?, payload: Bundle?)
    fun onJanusReady()
    fun onJanusHangup(reason: String?)
    fun onJanusClose()
}