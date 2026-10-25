import QtQuick
import QtQuick.Window

Window {
    id: root
    visible: true
    visibility: Window.FullScreen
    color: "#050308"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    title: "BREACH PROTOCOL"

    property int timeLeft: 40
    property var matrix: []
    property var target: []
    property var buffer: []
    property string state: "playing"
    property int lastPicked: -1

    FontLoader { id: chakra; source: "file:///home/marteam/.local/share/fonts/cyberpunk/ChakraPetch-Bold.ttf" }
    FontLoader { id: raj; source: "file:///home/marteam/.local/share/fonts/cyberpunk/Rajdhani-SemiBold.ttf" }

    function randHex() {
        var h = ["1C","55","7A","BD","E9","03","F1","2B","77","C4","90","6E"]
        return h[Math.floor(Math.random() * h.length)]
    }

    function newGame() {
        var m = []
        for (var i = 0; i < 36; i++) m.push(randHex())
        matrix = m
        var t = []
        for (var j = 0; j < 3; j++) t.push(m[Math.floor(Math.random() * 36)])
        target = t
        buffer = []
        lastPicked = -1
        timeLeft = 40
        state = "playing"
        tick.start()
    }

    function pick(index) {
        if (state !== "playing") return
        lastPicked = index
        var next = buffer.slice()
        next.push(matrix[index])
        buffer = next
        if (next.length >= target.length &&
            next.slice(next.length - target.length).join(",") === target.join(",")) {
            state = "won"
            tick.stop()
        } else if (next.length >= 4) {
            state = "lost"
            tick.stop()
        }
    }

    Component.onCompleted: newGame()

    Timer {
        id: tick
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (root.state !== "playing") return
            root.timeLeft--
            if (root.timeLeft <= 0) {
                root.timeLeft = 0
                root.state = "lost"
                tick.stop()
            }
        }
    }

    Item {
        id: scene
        anchors.fill: parent
        focus: true
        Keys.onPressed: function (event) {
            if (event.key === Qt.Key_Escape) Qt.quit()
        }

        // backdrop
        Rectangle { anchors.fill: parent; color: "#050308" }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#1a0006" }
                GradientStop { position: 0.5; color: "#070509" }
                GradientStop { position: 1.0; color: "#14020c" }
            }
            opacity: 0.9
        }
        Rectangle {
            width: parent.width
            height: 2
            color: "#ff2038"
            opacity: 0.08
            y: -10
            NumberAnimation on y {
                from: -10
                to: scene.height
                duration: 2600
                loops: Animation.Infinite
            }
        }

        // ── header ───────────────────────────────────────────────────
        Column {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 46
            spacing: 4
            Text {
                text: "BREACH PROTOCOL"
                color: "#ff2038"
                font.family: chakra.name
                font.pixelSize: 30
                font.letterSpacing: 8
            }
            Text {
                text: "ACCESS POINT // 0x7F4A // ICE: ACTIVE"
                color: "#b9a0a8"
                font.family: raj.name
                font.pixelSize: 15
                font.letterSpacing: 4
            }
        }
        Text {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 46
            text: "ESC // DISCONNECT"
            color: "#5c4a54"
            font.family: raj.name
            font.pixelSize: 14
            font.letterSpacing: 3
        }

        // ── timer ────────────────────────────────────────────────────
        Column {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: 46
            anchors.topMargin: 130
            spacing: 8
            Text {
                text: "BREACH TIME REMAINING"
                color: "#0dff6e"
                font.family: raj.name
                font.pixelSize: 16
                font.letterSpacing: 4
            }
            Row {
                spacing: 18
                Text {
                    text: root.timeLeft.toFixed(0)
                    color: root.timeLeft <= 10 ? "#ff2038" : "#f4eff1"
                    font.family: chakra.name
                    font.pixelSize: 64
                }
                Item {
                    width: 420
                    height: 8
                    anchors.verticalCenter: parent.verticalCenter
                    Rectangle { anchors.fill: parent; color: "#1c0d14" }
                    Rectangle {
                        height: parent.height
                        width: parent.width * (root.timeLeft / 40)
                        color: root.timeLeft <= 10 ? "#ff2038" : "#0dff6e"
                    }
                }
            }
        }

        // ── matrix ───────────────────────────────────────────────────
        Grid {
            id: grid
            columns: 6
            spacing: 10
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: 46
            anchors.topMargin: 300

            Repeater {
                model: 36
                Rectangle {
                    required property int index
                    width: 92
                    height: 56
                    color: hover.containsMouse ? "#2a0a14" : "#0d0710"
                    border.color: index === root.lastPicked ? "#0dff6e" : "#2a1220"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: root.matrix[index]
                        color: "#e2d0d6"
                        font.family: chakra.name
                        font.pixelSize: 22
                        font.letterSpacing: 2
                    }

                    MouseArea {
                        id: hover
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.pick(index)
                    }
                }
            }
        }

        // ── right column ─────────────────────────────────────────────
        Column {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 46
            anchors.topMargin: 300
            spacing: 22

            Text {
                text: "SEQUENCE REQUIRED TO UPLOAD"
                color: "#b9a0a8"
                font.family: raj.name
                font.pixelSize: 15
                font.letterSpacing: 4
            }
            Row {
                spacing: 12
                Repeater {
                    model: 3
                    Rectangle {
                        required property int index
                        width: 76
                        height: 56
                        color: "#12080f"
                        border.color: root.state === "won" ? "#0dff6e" : "#ff2038"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: root.target.length > index ? root.target[index] : "--"
                            color: "#f4eff1"
                            font.family: chakra.name
                            font.pixelSize: 22
                        }
                    }
                }
            }

            Text {
                text: "BUFFER"
                color: "#b9a0a8"
                font.family: raj.name
                font.pixelSize: 15
                font.letterSpacing: 4
            }
            Row {
                spacing: 12
                Repeater {
                    model: 4
                    Rectangle {
                        required property int index
                        width: 76
                        height: 56
                        color: "#0d0710"
                        border.color: "#2a1220"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: root.buffer.length > index ? root.buffer[index] : ""
                            color: "#0dff6e"
                            font.family: chakra.name
                            font.pixelSize: 22
                        }
                    }
                }
            }

            Text {
                text: root.state === "playing" ? "SELECT CODES"
                    : root.state === "won" ? "UPLOAD COMPLETE // DAEMON INJECTED"
                    : "TRACE COMPLETE // CONNECTION LOST"
                color: root.state === "won" ? "#0dff6e"
                    : root.state === "lost" ? "#ff2038" : "#b14cff"
                font.family: chakra.name
                font.pixelSize: 20
                font.letterSpacing: 4
            }

            Rectangle {
                width: 220
                height: 44
                color: "#ff2038"
                visible: root.state !== "playing"
                Text {
                    anchors.centerIn: parent
                    text: "RE-BREACH"
                    color: "#0b0710"
                    font.family: chakra.name
                    font.pixelSize: 18
                    font.letterSpacing: 4
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.newGame()
                }
            }
        }

    }
}
