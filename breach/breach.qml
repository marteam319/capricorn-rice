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

    // required upload sequence (3 codes, always reachable through the line rule)
    property var target: []

    property var buffer: []
    property string state: "playing"      // playing | won | lost

    // line rule: first pick is a COLUMN pick (column 0), then alternate ROW/COLUMN
    property string pickMode: "column"    // which line the next pick must be on
    property int lastRow: -1
    property int lastCol: 0
    property int lastPicked: -1
    property int rev: 0                   // bumped on every pick to refresh bindings

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

        // build a guaranteed-valid path: column 0 -> same row -> same column
        var r0 = Math.floor(Math.random() * 6)
        var c1 = Math.floor(Math.random() * 6)
        var r2 = Math.floor(Math.random() * 6)
        target = [ m[r0 * 6], m[r0 * 6 + c1], m[r2 * 6 + c1] ]

        buffer = []
        state = "playing"
        pickMode = "column"
        lastRow = -1
        lastCol = 0
        lastPicked = -1
        rev++
        timeLeft = 40
        tick.start()
        scene.forceActiveFocus()
    }

    // is cell index selectable under the current line rule?
    function isAllowed(index) {
        if (state !== "playing") return false
        var r = Math.floor(index / 6)
        var c = index % 6
        if (pickMode === "column") return c === lastCol
        return r === lastRow
    }

    function pick(index) {
        if (!isAllowed(index)) return

        var r = Math.floor(index / 6)
        var c = index % 6

        lastPicked = index
        lastRow = r
        lastCol = c
        pickMode = (pickMode === "column") ? "row" : "column"

        var next = buffer.slice()
        next.push(matrix[index])
        buffer = next
        rev++

        if (next.length >= target.length &&
            next.slice(next.length - target.length).join(",") === target.join(",")) {
            state = "won"
            tick.stop()
            return
        }
        if (next.length >= 4) {
            state = "lost"
            tick.stop()
        }
    }

    // how many codes of the required sequence are already matched, in order
    function matchedCount() {
        var m = 0
        for (var i = 0; i < buffer.length && m < target.length; i++) {
            if (buffer[i] === target[m]) m++
        }
        return m
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

        // sweeping scanline
        Rectangle {
            width: scene.width
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
            MouseArea {
                anchors.fill: parent
                anchors.margins: -8
                cursorShape: Qt.PointingHandCursor
                onClicked: Qt.quit()
            }
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

        // ── code matrix ──────────────────────────────────────────────
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
                    readonly property bool allowed: (root.rev, root.isAllowed(index))
                    readonly property bool picked: index === root.lastPicked

                    width: 92
                    height: 56
                    color: picked ? "#2a0a14"
                         : hover.containsMouse && allowed ? "#220812"
                         : allowed ? "#140910" : "#08050a"
                    border.color: picked ? "#0dff6e"
                                : allowed ? "#ff2038" : "#1a0c14"
                    border.width: allowed ? 1 : 1
                    opacity: allowed ? 1.0 : 0.38

                    Text {
                        anchors.centerIn: parent
                        text: root.matrix[index]
                        color: picked ? "#0dff6e" : "#e2d0d6"
                        font.family: chakra.name
                        font.pixelSize: 22
                        font.letterSpacing: 2
                    }

                    MouseArea {
                        id: hover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: parent.allowed ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.pick(index)
                    }
                }
            }
        }

        // line-rule hint
        Text {
            anchors.left: parent.left
            anchors.top: grid.bottom
            anchors.leftMargin: 46
            anchors.topMargin: 14
            text: root.state !== "playing" ? " "
                : root.pickMode === "column" ? "LINE RULE // SELECT FROM COLUMN " + (root.lastCol + 1)
                : "LINE RULE // SELECT FROM ROW " + (root.lastRow + 1)
            color: "#b14cff"
            font.family: raj.name
            font.pixelSize: 14
            font.letterSpacing: 3
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
                        readonly property bool done: (root.rev, root.matchedCount() > index)
                        width: 76
                        height: 56
                        color: done ? "#08240f" : "#12080f"
                        border.color: done ? "#0dff6e"
                                    : root.state === "won" ? "#0dff6e" : "#ff2038"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: root.target.length > index ? root.target[index] : "--"
                            color: parent.done ? "#0dff6e" : "#f4eff1"
                            font.family: chakra.name
                            font.pixelSize: 22
                        }
                    }
                }
            }

            Text {
                text: "BUFFER  " + root.buffer.length + " / 4"
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
                        readonly property bool used: root.buffer.length > index
                        width: 76
                        height: 56
                        color: used ? "#140910" : "#0d0710"
                        border.color: used ? "#3a1a26" : "#2a1220"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: used ? root.buffer[index] : ""
                            color: "#0dff6e"
                            font.family: chakra.name
                            font.pixelSize: 22
                        }
                    }
                }
            }

            Text {
                text: root.state === "playing" ? "SELECT CODES IN LINE"
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
                color: root.state === "won" ? "#0dff6e" : "#ff2038"
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
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.newGame()
                }
            }

            Text {
                text: "ROW → COLUMN → ROW → COLUMN"
                color: "#4a3640"
                font.family: raj.name
                font.pixelSize: 12
                font.letterSpacing: 3
            }
        }
    }
}
