import QtQuick

QtObject {
    id: registry

    property var modules: ({})  //模块对应id
    property var leftActive: []
    property var rightActive: []

    signal moduleActivated(string moduleId, var event)
    signal moduleDeactivated(string moduleId)
    signal layoutChanged()
    signal debugChanged()

    function register(moduleId, side, component, options) {
        var opts = options || {}
        modules[moduleId] = {
            side: side,
            component: component,
            idleWidth: opts.idleWidth || 40,
            expandedWidth: opts.expandedWidth || 140,
            persistent: opts.persistent || false,
            active: false
        }
        if (modules[moduleId].persistent) {
            modules[moduleId].active = true
            if (side === "left") leftActive.push(moduleId)
            else rightActive.push(moduleId)
        }
        layoutChanged()
    }
    
    function activate(moduleId, event) {
        var mod = modules[moduleId]
        if (!mod || mod.active) return
        mod.active = true
        if (mod.side === "left") leftActive.push(moduleId)
        else rightActive.push(moduleId)
        moduleActivated(moduleId, event)
        layoutChanged()
    }

    function deactivate(moduleId) {
        var mod = modules[moduleId]
        if (!mod || !mod.active || mod.persistent) return
        mod.active = false
        var list = mod.side === "left" ? leftActive : rightActive
        var idx = list.indexOf(moduleId)
        if (idx >= 0) list.splice(idx, 1)
        moduleDeactivated(moduleId)
        layoutChanged()
    }

    function getTotalWidth(side) {
        var list = side === "left" ? leftActive : rightActive
        var total = 0
        for (var i = 0; i < list.length; i++) {
            var mod = modules[list[i]]
            total += (mod.component ? (mod.component.width || mod.idleWidth) : mod.idleWidth)
        }
        return total
    }
}