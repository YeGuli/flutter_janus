package com.yeguli.flutter_janus

import android.app.Activity
import android.app.Application
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull
import com.github.helloiampau.janus.generated.*
import com.yeguli.flutter_janus.impl.JanusConfImpl
import com.yeguli.flutter_janus.impl.PeerImpl
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import org.json.JSONObject
import java.lang.ref.WeakReference


/** FlutterJanusPlugin */
class FlutterJanusPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, EventChannel.StreamHandler, ServiceDelegate, PeerImpl.PeerDelegate {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var mApplication: Application

    private var service: JanusService? = null
    private var eventHandler: Handler? = null
    private var eventSink: EventChannel.EventSink? = null
    private var mActivity: WeakReference<Activity>? = null
    private var eventSinkMap: HashMap<Any?, EventChannel.EventSink?> = HashMap()

    companion object {
        const val TAG = "[FlutterJanusPlugin]"
        const val METHOD_CHANNEL = "flutter_janus_method_channel"
        const val EVENT_CHANNEL = "flutter_janus_event_channel"

        const val METHOD_CONNECT = "connect"
        const val METHOD_DISCONNECT = "disconnect"
        const val METHOD_GET_ROOM_LIST = "getRoomList"
        const val METHOD_JOIN = "join"
        const val METHOD_LEAVE = "leave"
        const val METHOD_PUBLISH = "publish"
        const val METHOD_UNPUBLISH = "unPublish"
        const val METHOD_SUBSCRIBE = "subscribe"
        const val METHOD_UNSUBSCRIBE = "unSubscribe"
        const val METHOD_GET_PARTICIPANTS_LIST = "getParticipantsList"
        const val METHOD_ON_PEER_ICE_CANDIDATE = "onPeerIceCandidate"
        const val METHOD_ON_ICE_GATHERING_CHANGE = "onIceGatheringChange"

        const val EVENT_PUBLISHER_IN = "publisherIn"
        const val EVENT_PUBLISHER_OUT = "publisherOut"

        const val EVENT_CREATE_OFFER = "onCreateOffer"
        const val EVENT_CREATE_ANSWER = "onCreateAnswer"
        const val EVENT_ADD_ICE_CANDIDATE = "onAddIceCandidate"
        const val EVENT_SET_LOCAL_DESCRIPTION = "onSetLocalDescription"
        const val EVENT_SET_REMOTE_DESCRIPTION = "onSetRemoteDescription"
        const val EVENT_PEER_CLOSE = "onPeerClose"

        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), METHOD_CHANNEL)
            val event = EventChannel(registrar.messenger(), EVENT_CHANNEL)
            channel.setMethodCallHandler(FlutterJanusPlugin().initPluginMethodChannel(channel, registrar))
            event.setStreamHandler(FlutterJanusPlugin().initPluginEventChannel(event))
        }
    }

    fun initPluginMethodChannel(methodChannel: MethodChannel, registrar: Registrar): FlutterJanusPlugin? {
        this.methodChannel = methodChannel
        mApplication = registrar.context().applicationContext as Application
        mActivity = WeakReference(registrar.activity())
        return this
    }

    fun initPluginEventChannel(eventChannel: EventChannel): FlutterJanusPlugin? {
        this.eventChannel = eventChannel
        return this
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL)
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, EVENT_CHANNEL)
        mApplication = flutterPluginBinding.applicationContext as Application
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        eventSinkMap.clear()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        mActivity = WeakReference(binding.activity)
    }

    override fun onDetachedFromActivity() {
        mActivity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    }

    override fun onDetachedFromActivityForConfigChanges() {
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSinkMap[arguments] = events
        eventSink = events
        eventHandler = Handler(Looper.getMainLooper())
    }

    override fun onCancel(arguments: Any?) {
        eventSinkMap.remove(arguments)
        eventSink = null
        eventHandler = null
    }

    private fun sendEventSuccess(data: Any?) {
        eventHandler?.post {
            eventSink?.success(data)
        }
    }

    private fun sendEventError(errorMsg: String?, errorDetail: Any?) {
        eventHandler?.post {
            eventSink?.error("500", errorMsg, errorDetail)
        }
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        Log.d(TAG, "onMethodCall, method = ${call.method}")

        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            METHOD_CONNECT -> {
                val host = call.argument<String>("host")
                initJanus(result, host)
            }
            METHOD_DISCONNECT -> {
                unInitJanus(result)
            }
            METHOD_GET_ROOM_LIST -> {
                getRoomList(result)
            }
            METHOD_JOIN -> {
                val roomId = call.argument<String>("roomId")
                val id = call.argument<String>("id")
                joinRoom(result, roomId, id)
            }
            METHOD_LEAVE -> {
                leaveRoom(result)
            }
            METHOD_PUBLISH -> {
                publish(result)
            }
            METHOD_UNPUBLISH -> {
                unPublish(result)
            }
            METHOD_SUBSCRIBE -> {
                val roomId = call.argument<String>("roomId")
                val publisherId = call.argument<String>("publisherId")
                subscribe(result, roomId, publisherId)
            }
            METHOD_UNSUBSCRIBE -> {
                val publisherId = call.argument<String>("publisherId")
                unSubscribe(result, publisherId)
            }
            METHOD_GET_PARTICIPANTS_LIST -> {
                val roomId = call.argument<String>("roomId")
                getParticipantsList(result, roomId)
            }
            METHOD_ON_PEER_ICE_CANDIDATE -> {
                val id = call.argument<Long>("id")
                val sdpMid = call.argument<String>("sdpMid")
                val sdpMLineIndex = call.argument<Int>("sdpMLineIndex")
                val sdp = call.argument<String>("sdp")
                onPeerIceCandidate(id, sdpMid, sdpMLineIndex, sdp)
            }
            METHOD_ON_ICE_GATHERING_CHANGE -> {
                val id = call.argument<Long>("id")
                val status = call.argument<String>("status")
                onIceGatheringChange(id, status)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun initJanus(result: Result, host: String?) {
        if (host.isNullOrBlank()) {
            val errorMsg = "initJanus(): host is null or blank"
            Log.e(TAG, errorMsg)
            result.error("initJanus", errorMsg, null)
            return
        }
        val conf = JanusConfImpl()
        conf.url(host)
        conf.plugin(JanusPlugins.VIDEOROOM)
        service = JanusService(mActivity?.get(), conf, this, this)
        service?.start()
        result.success("")
    }

    private fun unInitJanus(result: Result) {
        if (service == null) {
            val errorMsg = "unInitJanus(): janus not init"
            Log.e(TAG, errorMsg)
            result.error("unInitJanus", errorMsg, null)
            return
        }
        service?.stop()
        service = null
        result.success("")
    }

    private fun getRoomList(result: Result) {
        if (service == null || service?.status != JanusService.STATUS_READY) {
            val errorMsg = "getRoomList(): janus not ready"
            Log.e(TAG, errorMsg)
            result.error("getRoomList", errorMsg, null)
            return
        }

        val context = Bundle.create()
        service!!.dispatch(JanusCommands.LIST, context)
        result.success("")
    }

    private fun joinRoom(result: Result, roomId: String?, id: String?) {
        if (service == null || service?.status != JanusService.STATUS_READY) {
            val errorMsg = "joinRoom(): janus not ready"
            Log.e(TAG, errorMsg)
            result.error("joinRoom", errorMsg, null)
            return
        }
        if (roomId.isNullOrBlank()) {
            val errorMsg = "joinRoom(): roomId is null or blank"
            Log.e(TAG, errorMsg)
            result.error("joinRoom", errorMsg, null)
            return
        }
        val context = Bundle.create()
        context.setString("room", roomId)
        context.setString("id", id ?: "")
        context.setString("display", id ?: "")
        service!!.dispatch(JanusCommands.JOIN, context)
        result.success("")
    }

    private fun leaveRoom(result: Result) {
        if (service == null || service?.status != JanusService.STATUS_READY) {
            val errorMsg = "leaveRoom(): janus not ready"
            Log.e(TAG, errorMsg)
            result.error("leaveRoom", errorMsg, null)
            return
        }

        val context = Bundle.create()
        service!!.dispatch(JanusCommands.LEAVE, context)
        result.success("")
    }

    private fun publish(result: Result) {
        if (service == null || service?.status != JanusService.STATUS_READY) {
            val errorMsg = "publish(): janus not ready"
            Log.e(TAG, errorMsg)
            result.error("publish", errorMsg, null)
            return
        }

        val context = Bundle.create()
        context.setBool("audio", true)
        context.setBool("video", true)
        context.setBool("data", true)
        service!!.dispatch(JanusCommands.PUBLISH, context)
        result.success("")
    }

    private fun unPublish(result: Result) {
        if (service == null || service?.status != JanusService.STATUS_READY) {
            val errorMsg = "unPublish(): janus not ready"
            Log.e(TAG, errorMsg)
            result.error("unPublish", errorMsg, null)
            return
        }

        val context = Bundle.create()
        service!!.dispatch(JanusCommands.UNPUBLISH, context)
        result.success("")
    }

    private fun subscribe(result: Result, roomId: String?, publisherId: String?) {
        if (service == null || service?.status != JanusService.STATUS_READY) {
            val errorMsg = "subscribe(): janus not ready"
            Log.e(TAG, errorMsg)
            result.error("subscribe", errorMsg, null)
            return
        }
        if (roomId.isNullOrBlank()) {
            val errorMsg = "subscribe(): roomId is null or blank"
            Log.e(TAG, errorMsg)
            result.error("subscribe", errorMsg, null)
            return
        }
        if (publisherId.isNullOrBlank()) {
            val errorMsg = "subscribe(): publisherId is null or blank"
            Log.e(TAG, errorMsg)
            result.error("subscribe", errorMsg, null)
            return
        }

        val context = Bundle.create()
        context.setString("room", roomId)
        context.setString("feed", publisherId)
        service!!.dispatch(JanusCommands.SUBSCRIBE, context)
        result.success("")
    }

    private fun unSubscribe(result: Result, publisherId: String?) {
        if (service == null || service?.status != JanusService.STATUS_READY) {
            val errorMsg = "unSubscribe(): janus not ready"
            Log.e(TAG, errorMsg)
            result.error("unSubscribe", errorMsg, null)
            return
        }
        if (publisherId.isNullOrBlank()) {
            val errorMsg = "unSubscribe(): publisherId is null or blank"
            Log.e(TAG, errorMsg)
            result.error("unSubscribe", errorMsg, null)
            return
        }
        val context = Bundle.create()
        context.setString("feed", publisherId)
        service!!.dispatch(JanusCommands.UNSUBSCRIBE, context)
        result.success("")
    }

    private fun getParticipantsList(result: Result, roomId: String?) {
        if (service == null || service?.status != JanusService.STATUS_READY) {
            val errorMsg = "getParticipantsList(): janus not ready"
            Log.e(TAG, errorMsg)
            result.error("getParticipantsList", errorMsg, null)
            return
        }
        if (roomId.isNullOrBlank()) {
            val errorMsg = "getParticipantsList(): roomId is null or blank"
            Log.e(TAG, errorMsg)
            result.error("getParticipantsList", errorMsg, null)
            return
        }

        val context = Bundle.create()
        context.setString("room", roomId)
        service!!.dispatch(JanusCommands.LISTPARTICIPANTS, context)
        result.success("")
    }

    private fun onPeerIceCandidate(id: Long?, sdpMid: String?, sdpMLineIndex: Int?, sdp: String?) {
        janusProtocolMap[id]?.onIceCandidate(sdpMid, sdpMLineIndex ?: 0, sdp, id ?: 0)
    }

    private fun onIceGatheringChange(id: Long?, status: String?) {
        if (status != "completed") {
            return
        }
        janusProtocolMap[id]?.onIceCompleted(id ?: 0)
    }

    override fun onJanusEvent(event: JanusEvent?, payload: Bundle?) {
        if (event == null || payload == null) {
            return
        }
        val data = event.data()
        val cmd = payload.getString("command", "")
        val status = data.getString("janus", "")
        Log.d(TAG, "onJanusEvent, cmd = $cmd, status = $status, data = $data")

        if (status == "success" && cmd == JanusCommands.LIST) {
            val list = data.getObject("plugindata").getObject("data").getList("list")
            val roomList = list.mapTo(ArrayList<String>()) { it.getString("room", "") }

            sendEventSuccess(HashMap<String, Any>().apply {
                this["action"] = METHOD_GET_ROOM_LIST
                this["roomList"] = roomList
            })
            return
        }

        if (cmd == JanusCommands.LISTPARTICIPANTS) {
            val info = data.getObject("plugindata").getObject("data")
            val list = info.getList("participants")
            val roomId = info.getString("room", "")

            val participantsList = list.mapTo(ArrayList<Map<String, Any>>()) {
                val map = HashMap<String, Any>()
                map["id"] = it.getString("id", "")
                map["name"] = it.getString("display", "")
                return@mapTo map
            }

            sendEventSuccess(HashMap<String, Any>().apply {
                this["action"] = METHOD_GET_PARTICIPANTS_LIST
                this["roomId"] = roomId
                this["participantsList"] = participantsList
            })
            return
        }

        if (cmd == JanusCommands.LEAVE) {
            sendEventSuccess(HashMap<String, Any>().apply {
                this["action"] = METHOD_LEAVE
            })
            return
        }

        val room = data.getString("room", "")
        val roomValue = data.getString("videoroom", "")

        if (roomValue == "joined") {
            sendEventSuccess(HashMap<String, Any>().apply {
                this["action"] = METHOD_JOIN
                this["roomId"] = data.getString("room", "")
            })
        }

        val publishers = data.getList("publishers")
        if (publishers.size > 0 && room.isNotEmpty()) {
            val publisherList = publishers.mapTo(ArrayList<Map<String, Any>>()) {
                val map = HashMap<String, Any>()
                map["id"] = it.getString("id", "")
                map["name"] = it.getString("display", "")
                return@mapTo map
            }
            sendEventSuccess(HashMap<String, Any>().apply {
                this["action"] = EVENT_PUBLISHER_IN
                this["roomId"] = room
                this["publisherList"] = publisherList
            })
            return
        }

        val unPublisher = data.getString("unpublished", "")
        if (unPublisher.isNotBlank()) {
            sendEventSuccess(HashMap<String, Any>().apply {
                this["action"] = EVENT_PUBLISHER_OUT
                this["roomId"] = room
                this["publisherId"] = unPublisher
            })
            return
        }
    }

    override fun onJanusError(error: JanusError?, payload: Bundle?) {
        Log.e(TAG, "onJanusError, error = $error, payload = $payload")
        when (payload?.getString("command", "") ?: "") {
            JanusCommands.LIST -> {
                sendEventError("", HashMap<String, Any>().apply {
                    this["action"] = METHOD_GET_ROOM_LIST
                    this["error"] = error?.message ?: ""
                })
            }
            JanusCommands.JOIN -> {
                sendEventError("", HashMap<String, Any>().apply {
                    this["action"] = METHOD_JOIN
                    this["error"] = error?.message ?: ""
                })
            }
            JanusCommands.LEAVE -> {
                sendEventError("", HashMap<String, Any>().apply {
                    this["action"] = METHOD_LEAVE
                    this["error"] = error?.message ?: ""
                })
            }
            JanusCommands.PUBLISH -> {
                sendEventError("", HashMap<String, Any>().apply {
                    this["action"] = METHOD_PUBLISH
                    this["error"] = error?.message ?: ""
                })
            }
            JanusCommands.UNPUBLISH -> {
                sendEventError("", HashMap<String, Any>().apply {
                    this["action"] = METHOD_UNPUBLISH
                    this["error"] = error?.message ?: ""
                })
            }
            JanusCommands.SUBSCRIBE -> {
                sendEventError("", HashMap<String, Any>().apply {
                    this["action"] = METHOD_SUBSCRIBE
                    this["error"] = error?.message ?: ""
                })
            }
            JanusCommands.UNSUBSCRIBE -> {
                sendEventError("", HashMap<String, Any>().apply {
                    this["action"] = METHOD_UNSUBSCRIBE
                    this["error"] = error?.message ?: ""
                })
            }
            JanusCommands.LISTPARTICIPANTS -> {
                sendEventError("", HashMap<String, Any>().apply {
                    this["action"] = METHOD_GET_PARTICIPANTS_LIST
                    this["error"] = error?.message ?: ""
                })
            }
        }
    }

    override fun onJanusReady() {
        Log.d(TAG, "onJanusReady")
        sendEventSuccess(HashMap<String, Any>().apply {
            this["action"] = METHOD_CONNECT
            this["event"] = "onJanusReady"
        })
    }

    override fun onJanusHangup(reason: String?) {
        Log.d(TAG, "onJanusHangup, reason = $reason")
        sendEventSuccess(HashMap<String, Any>().apply {
            this["action"] = METHOD_CONNECT
            this["event"] = "onJanusHangup"
            this["reason"] = reason ?: ""
        })
    }

    override fun onJanusClose() {
        Log.d(TAG, "onJanusClose")
        sendEventSuccess(HashMap<String, Any>().apply {
            this["action"] = METHOD_CONNECT
            this["event"] = "onJanusClose"
        })
    }

    private var janusProtocolMap = HashMap<Long, Protocol?>()

    override fun onInitProtocol(id: Long, publisherId: String?, owner: Protocol?) {
        Log.d(TAG, "onInitProtocol, id = $id, publisherId = $publisherId")
        janusProtocolMap[id] = owner
    }

    override fun onCreateOffer(id: Long, publisherId: String?, constraints: Constraints?, context: Bundle?) {
        Log.d(TAG, "onCreateOffer, id = $id, publisherId = $publisherId")

        eventHandler?.post {
            methodChannel.invokeMethod(EVENT_CREATE_OFFER, HashMap<String, Any>().apply {
                this["id"] = id
                this["publisherId"] = publisherId ?: ""
                this["constraints"] = constraints.toString()
                this["sdpConstraints"] = constraints?.sdp?.toString() ?: ""
                this["videoConstraints"] = constraints?.video?.toString() ?: ""
                this["sendVideo"] = constraints?.sdp?.sendVideo ?: false
                this["sendAudio"] = constraints?.sdp?.sendAudio ?: false
                this["receiveVideo"] = constraints?.sdp?.receiveVideo ?: false
                this["receiveAudio"] = constraints?.sdp?.receiveAudio ?: false
                this["dataChannel"] = constraints?.sdp?.datachannel ?: false
                this["width"] = constraints?.video?.width ?: 0
                this["height"] = constraints?.video?.height ?: 0
                this["fps"] = constraints?.video?.fps ?: 0
                this["camera"] = constraints?.video?.camera ?: ""
            }, object : MethodChannel.Result {
                override fun notImplemented() {
                }

                override fun error(errorCode: String?, errorMessage: String?, errorDetails: Any?) {
                    Log.d(TAG, "onCreateOfferError, id = $id, publisherId = $publisherId, errorMessage = $errorMessage")
                }

                override fun success(result: Any?) {
                    Log.d(TAG, "onCreateOfferSuccess, id = $id, publisherId = $publisherId")
                    val pId = result.argument<Long>("id") ?: 0
                    val sdp = result.argument<String>("sdp") ?: ""
                    janusProtocolMap[pId]?.onOffer(sdp, context)
                }
            })
        }

    }

    override fun onCreateAnswer(id: Long, publisherId: String?, constraints: Constraints?, context: Bundle?) {
        Log.d(TAG, "onCreateAnswer, id = $id, publisherId = $publisherId")
        eventHandler?.post {
            methodChannel.invokeMethod(EVENT_CREATE_ANSWER, HashMap<String, Any>().apply {
                this["id"] = id
                this["publisherId"] = publisherId ?: ""
                this["constraints"] = constraints.toString()
                this["sdpConstraints"] = constraints?.sdp?.toString() ?: ""
                this["videoConstraints"] = constraints?.video?.toString() ?: ""
                this["sendVideo"] = constraints?.sdp?.sendVideo ?: false
                this["sendAudio"] = constraints?.sdp?.sendAudio ?: false
                this["receiveVideo"] = constraints?.sdp?.receiveVideo ?: false
                this["receiveAudio"] = constraints?.sdp?.receiveAudio ?: false
                this["dataChannel"] = constraints?.sdp?.datachannel ?: false
                this["width"] = constraints?.video?.width ?: 0
                this["height"] = constraints?.video?.height ?: 0
                this["fps"] = constraints?.video?.fps ?: 0
                this["camera"] = constraints?.video?.camera ?: ""
            }, object : MethodChannel.Result {
                override fun notImplemented() {
                }

                override fun error(errorCode: String?, errorMessage: String?, errorDetails: Any?) {
                    Log.d(TAG, "onCreateAnswerError, id = $id, publisherId = $publisherId,  errorMessage = $errorMessage")
                }

                override fun success(result: Any?) {
                    Log.d(TAG, "onCreateAnswerSuccess, id = $id, publisherId = $publisherId")
                    val pId = result.argument<Long>("id") ?: 0
                    val sdp = result.argument<String>("sdp") ?: ""
                    janusProtocolMap[pId]?.onAnswer(sdp, context)
                }
            })
        }
    }

    override fun onAddIceCandidate(id: Long, publisherId: String?, mid: String?, index: Int, sdp: String?) {
        Log.d(TAG, "onAddIceCandidate, id = $id, publisherId = $publisherId")
        eventHandler?.post {
            methodChannel.invokeMethod(EVENT_ADD_ICE_CANDIDATE, HashMap<String, Any>().apply {
                this["id"] = id
                this["publisherId"] = publisherId ?: ""
                this["mid"] = mid ?: ""
                this["index"] = index
                this["sdp"] = sdp ?: ""
            })
        }
    }

    override fun onSetLocalDescription(id: Long, publisherId: String?, type: SdpType?, sdp: String?) {
        Log.d(TAG, "setLocalDescription, id = $id, publisherId = $publisherId")
        eventHandler?.post {
            methodChannel.invokeMethod(EVENT_SET_LOCAL_DESCRIPTION, HashMap<String, Any>().apply {
                this["id"] = id
                this["publisherId"] = publisherId ?: ""
                this["isOffer"] = type == SdpType.OFFER
                this["sdp"] = sdp ?: ""
            })
        }
    }

    override fun onSetRemoteDescription(id: Long, publisherId: String?, type: SdpType?, sdp: String?) {
        Log.d(TAG, "setRemoteDescription, id = $id, publisherId = $publisherId")
        eventHandler?.post {
            methodChannel.invokeMethod(EVENT_SET_REMOTE_DESCRIPTION, HashMap<String, Any>().apply {
                this["id"] = id
                this["publisherId"] = publisherId ?: ""
                this["isOffer"] = type == SdpType.OFFER
                this["sdp"] = sdp ?: ""
            })
        }
    }

    override fun onPeerClose(id: Long, publisherId: String?) {
        Log.d(TAG, "onPeerClose, id = $id, publisherId = $publisherId")
        eventHandler?.post {
            methodChannel.invokeMethod(EVENT_PEER_CLOSE, HashMap<String, Any>().apply {
                this["id"] = id
                this["publisherId"] = publisherId ?: ""
            })
        }
    }

    private fun <T> Any?.argument(key: String?): T? {
        return when {
            this == null -> {
                null
            }
            this is Map<*, *> -> {
                this[key] as T?
            }
            this is JSONObject -> {
                this.opt(key) as T?
            }
            else -> {
                throw ClassCastException()
            }
        }
    }
}
