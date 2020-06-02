package com.yeguli.flutter_janus.impl

import com.github.helloiampau.janus.generated.Plugin
import com.github.helloiampau.janus.generated.PluginFactory
import com.github.helloiampau.janus.generated.Protocol
import com.yeguli.flutter_janus.impl.CustomPlugin

/**
 * Created by Ye_Guli on 2020/4/30.
 */
class CustomPluginFactory : PluginFactory() {
    var plugin: CustomPlugin? = null
    override fun create(handleId: Long, owner: Protocol?): Plugin {
        plugin = CustomPlugin()
        return plugin!!
    }
}
