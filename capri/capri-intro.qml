import QtQuick
import QtQuick.Window

Window {
    id: intro
    width: 680
    height: 460
    x: 60
    y: 60
    visible: true
    color: "transparent"
    title: "CAPRI // INTRO"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnBottomHint | Qt.Tool

    readonly property string assets: "file:///home/marteam/.local/share/capricorn/assets/"
    readonly property color ink: "#0d0910"
    readonly property color paper: "#f7f0f2"
    readonly property color paper3: "#9a8a93"
    readonly property color violet: "#8a3cff"
    readonly property color green: "#0dff6e"
    readonly property color red: "#ff4d60"

    property int frame: 0
    property var frames: [
        "intro-grab.png",
        "intro-happy.png",
        "intro-mouth1.png",
        "intro-mouth2.png",
        "intro-mouth3.png",
        "intro-happy.png",
        "intro-wave1.png",
        "intro-wave2.png",
        "intro-wave3.png",
        "intro-smear.png"
    ]
    property var lines: [
        "incoming.",
        "hi.",
        "hi.",
        "hi.",
        "hi.",
        "you're back.",
        "you're back.",
        "you're back.",
        "you're back.",
        "let's go."
    ]

    Component.onCompleted: {
        frameTimer.start()
        closeTimer.start()
    }

    Rectangle {
        x: 26; y: 26; width: 640; height: 360
        color: intro.violet
        opacity: 0.85
    }

    Rectangle {
        x: 20; y: 20; width: 640; height: 360
        color: intro.ink
        border.color: "#3a2a44"
        border.width: 1
        clip: true

        Item {
            id: cam
            anchors.fill: parent
            scale: 1.0
            NumberAnimation on scale {
                from: 1.0
                to: 1.05
                duration: 3300
                easing.type: Easing.InOutSine
            }

            Repeater {
                model: intro.frames
                Image {
                    anchors.fill: parent
                    source: intro.assets + modelData
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: false
                    cache: true
                    opacity: index === intro.frame ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 60 } }
                }
            }

            Canvas {
                anchors.fill: parent
                opacity: 0.22
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    ctx.fillStyle = "#000000"
                    for (var y = 0; y < height; y += 4)
                        ctx.fillRect(0, y, width, 1)
                }
            }

            Rectangle {
                width: parent.width
                height: 8
                color: intro.green
                opacity: 0.22
                y: 100
                SequentialAnimation on y {
                    loops: Animation.Infinite
                    NumberAnimation { to: 300; duration: 2100; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 70; duration: 2500; easing.type: Easing.InOutSine }
                }
            }

            Rectangle {
                x: 0; y: 0
                width: parent.width / 2
                height: parent.height
                color: intro.ink
                SequentialAnimation on x {
                    running: true
                    PauseAnimation { duration: 120 }
                    NumberAnimation { to: -parent.width / 2 - 10; duration: 360; easing.type: Easing.OutCubic }
                }
            }
            Rectangle {
                x: parent.width / 2; y: 0
                width: parent.width / 2
                height: parent.height
                color: intro.ink
                SequentialAnimation on x {
                    running: true
                    PauseAnimation { duration: 120 }
                    NumberAnimation { to: parent.width + 10; duration: 360; easing.type: Easing.OutCubic }
                }
            }

            Rectangle {
                anchors.fill: parent
                color: intro.paper
                opacity: 0
                z: 20
                SequentialAnimation on opacity {
                    running: true
                    PauseAnimation { duration: 140 }
                    NumberAnimation { to: 0.85; duration: 80 }
                    NumberAnimation { to: 0; duration: 260 }
                }
            }

            Rectangle {
                x: 14; y: 306
                width: 210; height: 40
                color: intro.ink
                border.color: intro.violet
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: intro.lines[Math.min(intro.frame, intro.lines.length - 1)]
                    color: intro.paper
                    font.family: "Chakra Petch"
                    font.pixelSize: 24
                    font.letterSpacing: 1
                }
            }

            Text {
                x: 18; y: 18
                text: "CAPRI // INCOMING"
                color: intro.green
                font.family: "JetBrains Mono"
                font.pixelSize: 8
                font.letterSpacing: 1
            }
        }
    }

    Text {
        x: 20; y: 390
        text: "PROJECT CAPRICORN"
        color: intro.paper
        font.family: "Chakra Petch"
        font.pixelSize: 16
        font.letterSpacing: 2
    }
    Text {
        x: 20; y: 414
        text: "SHE GRABS THE SCREEN // INCOMING TRANSMISSION"
        color: intro.paper3
        font.family: "JetBrains Mono"
        font.pixelSize: 7
        font.letterSpacing: 1
    }
    Rectangle {
        x: 20; y: 438
        width: 250; height: 2
        color: intro.green
    }
    Text {
        x: 278; y: 432
        text: "◆ 00:0" + Math.min(intro.frame + 1, 9)
        color: intro.green
        font.family: "JetBrains Mono"
        font.pixelSize: 8
        font.letterSpacing: 1
    }

    Timer {
        id: frameTimer
        interval: 170
        repeat: true
        running: false
        onTriggered: if (intro.frame < intro.frames.length - 1) intro.frame++
    }

    Timer {
        id: closeTimer
        interval: 3400
        onTriggered: Qt.quit()
    }
}
