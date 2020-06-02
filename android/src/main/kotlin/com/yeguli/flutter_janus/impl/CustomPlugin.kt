package com.yeguli.flutter_janus.impl

import com.github.helloiampau.janus.generated.Bundle
import com.github.helloiampau.janus.generated.JanusEvent
import com.github.helloiampau.janus.generated.Plugin

/**
 * Created by Ye_Guli on 2020/4/30.
 */
class CustomPlugin : Plugin() {
    override fun onEvent(event: JanusEvent?, context: Bundle?) {}
    override fun onHangup(sender: Long, reason: String?) {}
    override fun onClose() {}
    override fun command(command: String?, payload: Bundle?) {}
    override fun onOffer(sdp: String?, context: Bundle?) {}
    override fun onAnswer(sdp: String?, context: Bundle?) {}
}