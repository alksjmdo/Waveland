//@ pragma UseQApplication
import Quickshell
import Quickshell.Wayland
import QtQuick
import "modules"
PanelWindow {
    id: root
    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 500
    color: "transparent"
    mask: Region { item: inputRegion }
    exclusiveZone: 48
    ModuleRegistry {
        id: moduleRegistry
    }
    EventBus {
        id: eventBus
    }
    IslandContainer {
        id: islandContainer
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 0

        IslandLayout {
            id: islandLayout
            registry: moduleRegistry
            eventBus: eventBus
            hovered: islandContainer.hovered
            shellWindow: root
        }

        island.width: islandLayout.implicitWidth
        island.height: islandLayout.implicitHeight
        pillRadius: islandLayout.pillRadius
    }
    Item {
        id: inputRegion
        anchors.fill: islandContainer
    }
    // 模块注册
    Component.onCompleted: {
        moduleRegistry.register("workspace", "left", islandLayout.workspaceModule, {
            idleWidth: 80,
            expandedWidth: 180,
            persistent: true
        })
        moduleRegistry.register("tray", "right", islandLayout.trayModule, {
            idleWidth: 40,
            expandedWidth: 120,
            persistent: true
        })
        moduleRegistry.register("music", "left", islandLayout.musicModule, {
            idleWidth: 0,
            expandedWidth: 0,
            persistent: true
        })
    }
}