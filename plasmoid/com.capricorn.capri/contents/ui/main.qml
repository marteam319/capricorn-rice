import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation
    implicitWidth: 176
    implicitHeight: 176
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    readonly property color cBright: "#f2f4c0"
    readonly property color cRed: "#ff2038"
    readonly property color cGreen: "#0dff6e"
    readonly property color cViolet: "#b14cff"
    readonly property color cDim: "#8f5a66"

    property bool glitch: false

    Plasma5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: function (sourceName, data) { exec.disconnectSource(sourceName) }
        function run(cmd) { exec.connectSource(cmd) }
    }

    Timer {
        interval: 4200
        repeat: true
        running: true
        onTriggered: {
            root.glitch = true
            glitchOff.restart()
        }
    }
    Timer {
        id: glitchOff
        interval: 110
        onTriggered: root.glitch = false
    }

    fullRepresentation: Item {
        id: outer
        width: root.width
        height: root.height

        Item {
            id: card
            width: 156
            height: 156
            anchors.horizontalCenter: parent.horizontalCenter
            property real bob: 0
            y: 12 + bob
            scale: hover.containsMouse ? 1.03 : 1.0
            Behavior on scale { NumberAnimation { duration: 130 } }

            SequentialAnimation on bob {
                loops: Animation.Infinite
                NumberAnimation { to: -4; duration: 1900; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0; duration: 1900; easing.type: Easing.InOutSine }
            }

            // green breathing halo
            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                color: "transparent"
                border.color: root.cGreen
                border.width: 1
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.05; duration: 1300 }
                    NumberAnimation { to: 0.40; duration: 1300 }
                }
            }

            Rectangle {
                anchors.fill: parent
                color: "#0a070c"
                border.color: root.cRed
                border.width: 2
            }

            Image {
                anchors.fill: parent
                anchors.margins: 3
                source: "../images/capri.png"
                fillMode: Image.PreserveAspectCrop
                smooth: true
            }

            // glitch ghost copies
            Image {
                x: 6; y: 3; width: parent.width - 6; height: parent.height - 6
                source: "../images/capri.png"
                fillMode: Image.PreserveAspectCrop
                visible: root.glitch
                opacity: 0.35
            }
            Image {
                x: 0; y: 3; width: parent.width - 6; height: parent.height - 6
                source: "../images/capri.png"
                fillMode: Image.PreserveAspectCrop
                visible: root.glitch
                opacity: 0.25
            }
            Rectangle { visible: root.glitch; y: 44; width: parent.width; height: 2; color: root.cGreen; opacity: 0.5 }
            Rectangle { visible: root.glitch; y: 101; width: parent.width; height: 3; color: root.cRed; opacity: 0.4 }

            // PRO badge
            Rectangle {
                x: parent.width - 42
                y: 7
                width: 34
                height: 15
                color: root.cViolet
                Text {
                    anchors.centerIn: parent
                    text: "PRO"
                    color: "#0b0710"
                    font.family: "Chakra Petch"
                    font.pixelSize: 8
                    font.bold: true
                    font.letterSpacing: 1
                }
            }

            // name strip
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 22
                color: "#d2050308"

                Text {
                    x: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: "CAPRI"
                    color: root.cBright
                    font.family: "Chakra Petch"
                    font.pixelSize: 10
                    font.letterSpacing: 3
                }
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: hover.containsMouse ? "NEED SOMETHING?" : "CLICK"
                    color: hover.containsMouse ? root.cGreen : root.cRed
                    font.family: "Rajdhani"
                    font.pixelSize: 8
                    font.letterSpacing: 2
                }
            }

            // corner ticks
            Rectangle { x: -3; y: -3; width: 14; height: 2; color: root.cGreen }
            Rectangle { x: -3; y: -3; width: 2; height: 14; color: root.cGreen }
            Rectangle { x: parent.width - 11; y: parent.height + 1; width: 14; height: 2; color: root.cRed }
            Rectangle { x: parent.width + 1; y: parent.height - 11; width: 2; height: 14; color: root.cRed }

            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: exec.run("/home/marteam/.local/bin/capri-chat-open.sh")
            }
        }
    }
}
