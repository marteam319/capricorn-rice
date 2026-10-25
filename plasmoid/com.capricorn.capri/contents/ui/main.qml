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

    readonly property color ink: "#0d0910"
    readonly property color paper: "#f7f0f2"
    readonly property color paper3: "#9a8a93"
    readonly property color red: "#ff4d60"
    readonly property color green: "#0dff6e"
    readonly property color violet: "#8a3cff"

    property bool hovered: false
    property bool baseFace: true

    Plasma5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: function (sourceName, data) { exec.disconnectSource(sourceName) }
        function run(cmd) { exec.connectSource(cmd) }
    }

    fullRepresentation: Item {
        id: outer
        width: root.width
        height: root.height

        Item {
            id: card
            width: 160
            height: 160
            scale: Math.min(outer.width / 160, outer.height / 160)
            transformOrigin: Item.TopLeft
            x: (outer.width - 160 * scale) / 2
            y: (outer.height - 160 * scale) / 2

            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    function plate(dx, dy, fill) {
                        ctx.beginPath()
                        ctx.moveTo(dx, 12 + dy)
                        ctx.lineTo(12 + dx, dy)
                        ctx.lineTo(96 + dx, dy)
                        ctx.lineTo(99 + dx, 5 + dy)
                        ctx.lineTo(102 + dx, dy)
                        ctx.lineTo(142 + dx, dy)
                        ctx.lineTo(160 + dx, 18 + dy)
                        ctx.lineTo(160 + dx, 160 + dy)
                        ctx.lineTo(22 + dx, 160 + dy)
                        ctx.lineTo(dx, 138 + dy)
                        ctx.closePath()
                        ctx.fillStyle = fill
                        ctx.fill()
                    }
                    plate(5, 5, root.violet)
                    plate(0, 0, root.ink)
                }
            }

            // face well: violet misregistration under the portrait
            Rectangle {
                x: 27; y: 19; width: 124; height: 124
                color: root.violet
            }
            Image {
                id: face
                x: 24; y: 16; width: 124; height: 124
                source: root.baseFace ? "../images/base.png" : "../images/smug.png"
                fillMode: Image.PreserveAspectCrop
                smooth: true
            }
            Rectangle {
                x: 24; y: 16; width: 124; height: 124
                color: "transparent"
                border.color: root.ink
                border.width: 1
            }

            SequentialAnimation {
                id: faceSwap
                NumberAnimation { target: face; property: "x"; to: 30; duration: 35 }
                NumberAnimation { target: face; property: "x"; to: 18; duration: 35 }
                NumberAnimation { target: face; property: "x"; to: 24; duration: 45 }
            }

            // portrait strip
            Rectangle {
                x: 24; y: 114; width: 124; height: 26
                color: "#e60d0910"
                Text {
                    x: 8; y: 6
                    text: "CAPRI"
                    color: root.paper
                    font.family: "Chakra Petch"
                    font.pixelSize: 10
                    font.letterSpacing: 2
                }
                Rectangle {
                    x: 70; y: 11; width: 5; height: 5; radius: 2.5
                    color: root.green
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.25; duration: 700 }
                        NumberAnimation { to: 1.0; duration: 700 }
                    }
                }
                Text {
                    x: 80; y: 8
                    text: "ONLINE"
                    color: root.green
                    font.family: "JetBrains Mono"
                    font.pixelSize: 7
                    font.letterSpacing: 1
                }
            }

            // lower strip
            Text {
                x: 14; y: 147
                text: "PROJECT CAPRICORN"
                color: root.paper3
                font.family: "JetBrains Mono"
                font.pixelSize: 7
                font.letterSpacing: 1
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 12
                y: 145
                text: root.hovered ? "TALK  >" : "TAP"
                color: root.hovered ? root.red : root.paper3
                font.family: "Chakra Petch"
                font.pixelSize: 8
                font.letterSpacing: 1
            }

            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                    root.hovered = true
                    if (root.baseFace) {
                        root.baseFace = false
                        faceSwap.restart()
                    }
                }
                onExited: {
                    root.hovered = false
                    root.baseFace = true
                    faceSwap.restart()
                }
                onClicked: exec.run("/home/marteam/.local/bin/capri-chat-open.sh")
            }
        }
    }
}
