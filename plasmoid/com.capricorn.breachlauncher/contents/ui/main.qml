import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation
    implicitWidth: 192
    implicitHeight: 64
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    readonly property color cBright: "#f2f4c0"
    readonly property color cLine: "#d6d84e"
    readonly property color cDim: "#8f8f4a"
    readonly property color cRed: "#ff2038"


    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) { executable.disconnectSource(sourceName) }
        function run(cmd) { connectSource(cmd) }
    }

    fullRepresentation: Item {
        id: container
        width: 192
        height: 64
        implicitWidth: 192
        implicitHeight: 64

        Rectangle {
            anchors.fill: parent
            color: hover.containsMouse ? "#f2120a12" : "#ec0b0b06"
            border.color: root.cRed
            border.width: 1
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        // pulsing outer bracket
        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            color: "transparent"
            border.color: root.cRed
            border.width: 1
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0.10; duration: 1100 }
                NumberAnimation { to: 0.55; duration: 1100 }
            }
        }

        // corner brackets
        Rectangle { x: 5; y: 5; width: 18; height: 2; color: root.cLine }
        Rectangle { x: 5; y: 5; width: 2; height: 18; color: root.cLine }
        Rectangle { x: parent.width - 23; y: parent.height - 7; width: 18; height: 2; color: root.cRed }
        Rectangle { x: parent.width - 7; y: parent.height - 23; width: 2; height: 18; color: root.cRed }

        Text {
            x: 14
            y: 4
            text: "BREACH"
            color: root.cBright
            font.family: "Chakra Petch"
            font.pixelSize: 21
            font.letterSpacing: 6
        }
        Text {
            x: 14
            y: 29
            text: "ACCESS POINT // 0x7F4A"
            color: root.cDim
            font.family: "Rajdhani"
            font.pixelSize: 8
            font.letterSpacing: 2
        }
        Row {
            x: 14
            y: 45
            spacing: 10
            Text {
                text: "▶ PLAY"
                color: root.cRed
                font.family: "Chakra Petch"
                font.pixelSize: 12
                font.letterSpacing: 2
            }
            Text {
                text: "LINK READY"
                color: root.cDim
                font.family: "Rajdhani"
                font.pixelSize: 8
                font.letterSpacing: 2
            }
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: executable.run("/home/marteam/.local/bin/capricorn-breach-open.sh")
        }
    }
}
