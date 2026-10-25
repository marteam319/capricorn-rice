import QtQuick
import QtQuick.Window

Window {
    id: intro
    width: 400
    height: 440
    visible: true
    color: "transparent"
    title: "CAPRI // INTRO"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnBottomHint | Qt.Tool

    readonly property string assets: "file:///home/marteam/.local/share/capricorn/assets/"
    readonly property color ink: "#0d0910"
    readonly property color paper: "#f7f0f2"
    readonly property color violet: "#8a3cff"
    readonly property color green: "#0dff6e"

    property int frame: 0

    Component.onCompleted: {
        intro.x = Math.round(Screen.width - intro.width - 30)
        intro.y = 30
        frameTimer.start()
        closeTimer.start()
    }

    Rectangle { x: 24; y: 24; width: 360; height: 400; color: intro.violet }
    Rectangle {
        x: 20; y: 20; width: 360; height: 400
        color: intro.ink
        border.color: "#3a2a44"
        border.width: 1
        clip: true

        Item {
            anchors.fill: parent
            clip: true
            Image {
                width: 3600; height: 400
                x: -intro.frame * 360
                source: intro.assets + "intro-face.webp"
                fillMode: Image.PreserveAspectFit
            }
        }

        // shutter opening
        Rectangle {
            id: shutterL
            x: 0; y: 0; width: parent.width / 2; height: parent.height
            color: intro.ink
            SequentialAnimation on x {
                running: true
                PauseAnimation { duration: 150 }
                NumberAnimation { to: -parent.width / 2 - 10; duration: 320; easing.type: Easing.OutCubic }
            }
        }
        Rectangle {
            id: shutterR
            x: parent.width / 2; y: 0; width: parent.width / 2; height: parent.height
            color: intro.ink
            SequentialAnimation on x {
                running: true
                PauseAnimation { duration: 150 }
                NumberAnimation { to: parent.width + 10; duration: 320; easing.type: Easing.OutCubic }
            }
        }
    }

    Text {
        x: 20; y: 426
        text: "PROJECT CAPRICORN // INITIALISING"
        color: intro.green
        font.family: "JetBrains Mono"
        font.pixelSize: 8
        font.letterSpacing: 1
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 300
        text: "hi"
        color: intro.paper
        font.family: "Chakra Petch"
        font.pixelSize: 34
        font.letterSpacing: 2
        opacity: intro.frame >= 7 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    Timer {
        id: frameTimer
        interval: 110
        repeat: true
        running: false
        onTriggered: if (intro.frame < 9) intro.frame++
    }
    Timer {
        id: closeTimer
        interval: 2550
        onTriggered: Qt.quit()
    }
}
