import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation
    implicitWidth: 560
    implicitHeight: 460
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    property int timeLeft: 40
    property var matrix: []
    property var target: []
    property var buffer: []
    property string state: "ready"        // ready | playing | won | lost
    property string pickMode: "column"    // next pick line: column | row
    property int lastRow: -1
    property int lastCol: 0
    property int lastPicked: -1
    property int rev: 0
    property int barTick: 0

    FontLoader { id: chakra; source: "../fonts/ChakraPetch-Bold.ttf" }
    FontLoader { id: raj; source: "../fonts/Rajdhani-SemiBold.ttf" }

    function randHex() {
        var h = ["1C","55","7A","BD","E9","03","F1","2B","77","C4","90","6E"]
        return h[Math.floor(Math.random() * h.length)]
    }

    function newGame() {
        var m = []
        for (var i = 0; i < 36; i++) m.push(randHex())
        matrix = m

        // guaranteed-solvable path: column 1 -> same row -> same column
        var r0 = Math.floor(Math.random() * 6)
        var c1 = Math.floor(Math.random() * 6)
        var r2 = Math.floor(Math.random() * 6)
        target = [ m[r0 * 6], m[r0 * 6 + c1], m[r2 * 6 + c1] ]

        buffer = []
        state = "ready"
        pickMode = "column"
        lastRow = -1
        lastCol = 0
        lastPicked = -1
        timeLeft = 40
        rev++
        tick.stop()
    }

    function isAllowed(index) {
        if (state !== "playing" && state !== "ready") return false
        var r = Math.floor(index / 6)
        var c = index % 6
        if (pickMode === "column") return c === lastCol
        return r === lastRow
    }

    function pick(index) {
        if (!isAllowed(index)) return

        if (state === "ready") {
            state = "playing"
            tick.start()
        }

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
        repeat: true
        running: false
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

    Timer {
        interval: 900
        running: true
        repeat: true
        onTriggered: root.barTick++
    }

    fullRepresentation: Item {
        id: container
        width: 560
        height: 460
        readonly property real s: Math.min(width / 560, height / 460)

        Item {
            id: board
            width: 560
            height: 460
            scale: container.s
            transformOrigin: Item.TopLeft
            x: (container.width - 560 * container.s) / 2
            y: (container.height - 460 * container.s) / 2
            clip: true

            // ── panel ────────────────────────────────────────────────
            Rectangle {
                anchors.fill: parent
                border.color: "#ff2038"
                border.width: 1
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#d00d0710" }
                    GradientStop { position: 1.0; color: "#c008050a" }
                }
            }
            Rectangle {
                width: parent.width - 2
                height: 2
                x: 1
                y: 1
                color: "#ff2038"
                opacity: 0.9
            }

            // corner ticks
            Rectangle { x: 6; y: 6; width: 26; height: 2; color: "#0dff6e" }
            Rectangle { x: 6; y: 6; width: 2; height: 26; color: "#0dff6e" }
            Rectangle { x: parent.width - 32; y: parent.height - 8; width: 26; height: 2; color: "#ff2038" }
            Rectangle { x: parent.width - 8; y: parent.height - 32; width: 2; height: 26; color: "#ff2038" }

            // scanline
            Rectangle {
                width: parent.width
                height: 1
                color: "#ff2038"
                opacity: 0.10
                NumberAnimation on y {
                    from: 0
                    to: board.height
                    duration: 6500
                    loops: Animation.Infinite
                }
            }

            // ── header ───────────────────────────────────────────────
            Text {
                x: 16
                y: 12
                text: "BREACH PROTOCOL"
                color: "#ff2038"
                font.family: chakra.name
                font.pixelSize: 17
                font.letterSpacing: 5
            }
            Text {
                x: 16
                y: 38
                text: "ACCESS POINT // 0x7F4A"
                color: "#b9a0a8"
                font.family: raj.name
                font.pixelSize: 9
                font.letterSpacing: 3
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 16
                y: 14
                text: "ICE: ACTIVE"
                color: "#0dff6e"
                font.family: raj.name
                font.pixelSize: 9
                font.letterSpacing: 2
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 16
                y: 32
                text: "↻"
                color: "#b14cff"
                font.family: raj.name
                font.pixelSize: 15

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.newGame()
                }
            }

            // ── timer ────────────────────────────────────────────────
            Text {
                x: 16
                y: 64
                text: "TIME REMAINING"
                color: "#0dff6e"
                font.family: raj.name
                font.pixelSize: 9
                font.letterSpacing: 3
            }
            Text {
                x: 16
                y: 76
                text: root.timeLeft
                color: (root.state === "playing" && root.timeLeft <= 10) ? "#ff2038" : "#f4eff1"
                font.family: chakra.name
                font.pixelSize: 30
            }
            Item {
                x: 76
                y: 92
                width: 220
                height: 6
                Rectangle { anchors.fill: parent; color: "#1c0d14" }
                Rectangle {
                    height: parent.height
                    width: parent.width * (root.timeLeft / 40)
                    color: (root.state === "playing" && root.timeLeft <= 10) ? "#ff2038" : "#0dff6e"
                }
            }

            // ── code matrix ──────────────────────────────────────────
            Grid {
                id: grid
                x: 16
                y: 146
                columns: 6
                spacing: 6

                Repeater {
                    model: 36

                    Rectangle {
                        required property int index
                        readonly property bool allowed: (root.rev, root.isAllowed(index))
                        readonly property bool picked: index === root.lastPicked

                        width: 62
                        height: 36
                        color: picked ? "#2a0a14"
                             : (hover.containsMouse && allowed) ? "#220812"
                             : allowed ? "#140910" : "#08050a"
                        border.color: picked ? "#0dff6e"
                                    : allowed ? "#ff2038" : "#1a0c14"
                        border.width: 1
                        opacity: allowed ? 1.0 : 0.36

                        Text {
                            anchors.centerIn: parent
                            text: root.matrix[index]
                            color: picked ? "#0dff6e" : "#e2d0d6"
                            font.family: chakra.name
                            font.pixelSize: 16
                            font.letterSpacing: 1
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

            // ── line rule hint ───────────────────────────────────────
            Text {
                x: 16
                y: 400
                text: root.state === "won" || root.state === "lost" ? " "
                    : root.state === "ready" ? "COLUMN 1 START // TIMER STARTS ON FIRST PICK"
                    : root.pickMode === "column" ? "LINE RULE // SELECT FROM COLUMN " + (root.lastCol + 1)
                    : "LINE RULE // SELECT FROM ROW " + (root.lastRow + 1)
                color: "#b14cff"
                font.family: raj.name
                font.pixelSize: 9
                font.letterSpacing: 2
            }
            Text {
                x: 16
                y: 422
                text: "DATAMINE_V1 // TRACE " + (12 + (root.barTick % 40)) + "%"
                color: "#5c4a54"
                font.family: raj.name
                font.pixelSize: 9
                font.letterSpacing: 2
            }

            // ── right column ─────────────────────────────────────────
            Column {
                x: 430
                y: 146
                width: 114
                spacing: 0

                Text {
                    text: "SEQUENCE"
                    color: "#b9a0a8"
                    font.family: raj.name
                    font.pixelSize: 8
                    font.letterSpacing: 2
                    height: 12
                }
                Row {
                    spacing: 4
                    Repeater {
                        model: 3
                        Rectangle {
                            required property int index
                            readonly property bool done: (root.rev, root.matchedCount() > index)
                            width: 34
                            height: 30
                            color: done ? "#08240f" : "#12080f"
                            border.color: done ? "#0dff6e"
                                        : root.state === "won" ? "#0dff6e" : "#ff2038"
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: root.target.length > index ? root.target[index] : "--"
                                color: parent.done ? "#0dff6e" : "#f4eff1"
                                font.family: chakra.name
                                font.pixelSize: 13
                            }
                        }
                    }
                }
                Item { width: 1; height: 8 }
                Text {
                    text: "BUFFER " + root.buffer.length + "/4"
                    color: "#b9a0a8"
                    font.family: raj.name
                    font.pixelSize: 8
                    font.letterSpacing: 2
                    height: 12
                }
                Grid {
                    columns: 2
                    spacing: 4
                    Repeater {
                        model: 4
                        Rectangle {
                            required property int index
                            readonly property bool used: root.buffer.length > index
                            width: 54
                            height: 30
                            color: used ? "#140910" : "#0d0710"
                            border.color: used ? "#3a1a26" : "#2a1220"
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: used ? root.buffer[index] : ""
                                color: "#0dff6e"
                                font.family: chakra.name
                                font.pixelSize: 13
                            }
                        }
                    }
                }
                Item { width: 1; height: 10 }
                Text {
                    width: 114
                    height: 42
                    text: root.state === "ready" ? "STANDBY // AWAITING INTRUSION"
                        : root.state === "playing" ? "SELECT CODES IN LINE"
                        : root.state === "won" ? "UPLOAD COMPLETE // DAEMON INJECTED"
                        : "TRACE COMPLETE // CONNECTION LOST"
                    color: root.state === "won" ? "#0dff6e"
                        : root.state === "lost" ? "#ff2038" : "#b14cff"
                    font.family: chakra.name
                    font.pixelSize: 9
                    font.letterSpacing: 1
                    wrapMode: Text.WordWrap
                }
                Item { width: 1; height: 4 }
                Rectangle {
                    width: 112
                    height: 28
                    visible: root.state === "won" || root.state === "lost"
                    color: root.state === "won" ? "#0dff6e" : "#ff2038"
                    Text {
                        anchors.centerIn: parent
                        text: "RE-BREACH"
                        color: "#0b0710"
                        font.family: chakra.name
                        font.pixelSize: 10
                        font.letterSpacing: 2
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.newGame()
                    }
                }
            }
        }
    }
}
