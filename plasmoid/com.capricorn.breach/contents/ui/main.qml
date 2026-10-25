import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation
    implicitWidth: 720
    implicitHeight: 620
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // ── Cyberpunk 2077 palette ───────────────────────────────────────
    readonly property color cBright: "#f2f4c0"
    readonly property color cLine: "#d6d84e"
    readonly property color cDim: "#8f8f4a"
    readonly property color cFaint: "#3d3d1e"
    readonly property color cDanger: "#ff3b30"
    readonly property color cGreen: "#b8ff6a"

    readonly property var hexPool: ["1C","55","7A","BD","E9","03","F1","2B","77","C4","90","6E"]

    // ── game state ───────────────────────────────────────────────────
    property string phase: "boot"        // boot | ready | playing | upload | result
    property int timeLeft: 30
    property var matrix: []
    property var buffer: []
    property var daemons: []
    property var results: []
    property string pickMode: "row"      // row | column
    property int lastRow: 0
    property int lastCol: -1
    property int lastPicked: -1
    property int hoverIndex: -1
    property string highlightHex: ""
    property int rev: 0
    property int decryptIndex: 0
    property int scramble: 0
    property int rejectIndex: -1
    property string toast: ""
    property int trace: 8
    property bool blink: false
    property bool glitch: false
    property int glitchY: 0
    property string logText: ""
    property int logSeq: 0
    property real uploadProgress: 0
    property bool won: false
    property int shakeX: 0

    signal sweepRequested()

    FontLoader { id: chakra; source: "../fonts/ChakraPetch-Bold.ttf" }
    FontLoader { id: raj; source: "../fonts/Rajdhani-SemiBold.ttf" }

    // ── logic ────────────────────────────────────────────────────────
    function randHex() {
        return hexPool[Math.floor(Math.random() * hexPool.length)]
    }

    function newGame() {
        var m = []
        for (var i = 0; i < 36; i++) m.push(randHex())
        matrix = m

        daemons = []
        results = []
        buffer = []
        phase = "boot"
        pickMode = "row"
        lastRow = 0
        lastCol = -1
        lastPicked = -1
        hoverIndex = -1
        highlightHex = ""
        timeLeft = 30
        trace = 8
        won = false
        uploadProgress = 0
        toast = ""
        rejectIndex = -1
        decryptIndex = 0
        scramble = 0
        blink = false
        rev++
        tick.stop()
        bootTimer.restart()
        uploadAnim.stop()
        logText = ""
        logSeq = 0
        appendLog("breach protocol v2.77 // link ready")
        appendLog("access point 0x7F4A // NIGHT CITY")
    }

    function isAllowed(index) {
        if (phase === "choosing") return true
        if (phase !== "playing") return false
        if (buffer.length === 0) return true
        var r = Math.floor(index / 6)
        var c = index % 6
        if (pickMode === "row") return r === lastRow
        return c === lastCol
    }

    function beginHack() {
        if (phase !== "ready") return
        phase = "choosing"
        blink = false
        appendLog("breach armed // choose start node")
        sweepRequested()
    }

    // build guaranteed-solvable daemons from the node the player starts on
    function armDaemons(index) {
        var sc = index % 6
        var r1 = Math.floor(Math.random() * 6)
        var c2 = Math.floor(Math.random() * 6)
        var r3 = Math.floor(Math.random() * 6)
        var p0 = matrix[index]
        var p1 = matrix[r1 * 6 + sc]
        var p2 = matrix[r1 * 6 + c2]
        var p3 = matrix[r3 * 6 + c2]
        daemons = [
            { name: "DATAMINE_V1", seq: [p0, p1, p2] },
            { name: "ICEPICK",     seq: [p1, p2, p3] }
        ]
    }

    function pick(index) {
        if (phase === "choosing") {
            var sr = Math.floor(index / 6)
            var sc = index % 6
            lastPicked = index
            lastRow = sr
            lastCol = sc
            pickMode = "column"
            buffer = [matrix[index]]
            armDaemons(index)
            phase = "playing"
            trace = Math.min(99, trace + 2)
            rev++
            tick.start()
            appendLog("start node " + matrix[index] + " // link established")
            sweepRequested()
            return
        }
        if (phase !== "playing") return

        if (!isAllowed(index)) {
            rejectIndex = index
            rejectTimer.restart()
            toast = "INVALID NODE // LINE LOCKED"
            toastTimer.restart()
            shakeAnim.restart()
            return
        }

        var r = Math.floor(index / 6)
        var c = index % 6

        lastPicked = index
        lastRow = r
        lastCol = c
        pickMode = (pickMode === "row") ? "column" : "row"

        buffer = buffer.concat([matrix[index]])
        rev++
        trace = Math.min(99, trace + 2 + Math.floor(Math.random() * 3))
        appendLog("node " + matrix[index] + " acquired // buffer " + buffer.length + "/4")

        if (buffer.length >= 4 || allMatched()) endBreach()
    }

    function allMatched() {
        for (var i = 0; i < daemons.length; i++)
            if (!hasSequence(daemons[i].seq)) return false
        return daemons.length > 0
    }

    function hasSequence(seq) {
        if (buffer.length < seq.length) return false
        for (var i = 0; i + seq.length <= buffer.length; i++) {
            var ok = true
            for (var j = 0; j < seq.length; j++) {
                if (buffer[i + j] !== seq[j]) { ok = false; break }
            }
            if (ok) return true
        }
        return false
    }

    function daemonProgress(seq) {
        if (hasSequence(seq)) return seq.length
        for (var len = Math.min(seq.length, buffer.length); len > 0; len--) {
            var start = buffer.length - len
            var ok = true
            for (var j = 0; j < len; j++) {
                if (buffer[start + j] !== seq[j]) { ok = false; break }
            }
            if (ok) return len
        }
        return 0
    }

    function daemonStatus(seq) {
        if (hasSequence(seq)) return (phase === "result") ? "UPLOADED" : "READY"
        var p = daemonProgress(seq)
        return (p > 0) ? "MATCH " + p + "/" + seq.length : "LOCKED"
    }

    function endBreach() {
        if (phase !== "playing") return
        phase = "upload"
        tick.stop()
        uploadProgress = 0
        appendLog("buffer flush // uploading daemons")
        uploadAnim.restart()
    }

    function finishBreach() {
        var res = []
        var any = false
        for (var i = 0; i < daemons.length; i++) {
            var ok = hasSequence(daemons[i].seq)
            res.push({ name: daemons[i].name, ok: ok })
            if (ok) any = true
        }
        results = res
        won = any
        phase = "result"
        appendLog(any ? "daemon injected // ACCESS GRANTED" : "upload failed // TRACE COMPLETE")
    }

    function appendLog(line) {
        logSeq++
        var n = logSeq % 100
        var stamp = (n < 10 ? "0" : "") + n
        var lines = logText.length > 0 ? logText.split("\n") : []
        lines.push("> " + stamp + " " + line)
        while (lines.length > 9) lines.shift()
        logText = lines.join("\n")
    }

    function ambientLine() {
        var lines = [
            "spoofing MAC // ok",
            "netwatch ping blocked",
            "ICE probe detected",
            "route scrubbed // 0x2B",
            "packet loss 0.02%",
            "daemon buffer allocated",
            "shard decrypt in progress",
            "proxy chain stable",
            "trace obfuscation active"
        ]
        return lines[Math.floor(Math.random() * lines.length)]
    }

    function statusFor(d) {
        if (phase === "upload") return hasSequence(d.seq) ? "READY" : "PENDING"
        return d.ok ? "UPLOADED" : "FAILED"
    }

    function statusColor(d) {
        if (phase === "upload") return hasSequence(d.seq) ? cLine : cDim
        return d.ok ? cGreen : cDanger
    }

    Component.onCompleted: newGame()

    // ── timers ───────────────────────────────────────────────────────
    Timer {
        id: tick
        interval: 1000
        repeat: true
        running: false
        onTriggered: {
            if (root.phase !== "playing") return
            root.timeLeft = Math.max(0, root.timeLeft - 1)
            root.trace = Math.min(99, root.trace + 1)
            if (root.timeLeft <= 0) root.endBreach()
        }
    }

    Timer {
        id: bootTimer
        interval: 28
        repeat: true
        running: false
        onTriggered: {
            root.decryptIndex++
            root.scramble++
            if (root.decryptIndex >= 36) {
                bootTimer.stop()
                root.phase = "ready"
                root.appendLog("code matrix decrypted // 36 nodes")
            }
        }
    }

    Timer {
        id: blinkTimer
        interval: 430
        repeat: true
        running: root.phase === "playing" && root.timeLeft <= 10
        onTriggered: root.blink = !root.blink
    }

    Timer {
        id: toastTimer
        interval: 1400
        onTriggered: root.toast = ""
    }

    Timer {
        id: rejectTimer
        interval: 500
        onTriggered: root.rejectIndex = -1
    }

    Timer {
        interval: 2900
        repeat: true
        running: true
        onTriggered: {
            root.glitchY = Math.floor(Math.random() * 480) + 60
            root.glitch = true
            glitchOff.restart()
            if (root.phase === "playing") root.appendLog(root.ambientLine())
        }
    }

    Timer {
        id: glitchOff
        interval: 100
        onTriggered: root.glitch = false
    }

    Timer {
        interval: 4200
        repeat: true
        running: root.phase === "playing"
        onTriggered: root.appendLog(root.ambientLine())
    }

    NumberAnimation {
        id: uploadAnim
        target: root
        property: "uploadProgress"
        from: 0
        to: 1
        duration: 2200
        onFinished: root.finishBreach()
    }

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: root; property: "shakeX"; to: -5; duration: 45 }
        NumberAnimation { target: root; property: "shakeX"; to: 5; duration: 45 }
        NumberAnimation { target: root; property: "shakeX"; to: -3; duration: 45 }
        NumberAnimation { target: root; property: "shakeX"; to: 0; duration: 45 }
    }

    // ── view ─────────────────────────────────────────────────────────
    fullRepresentation: Item {
        id: container
        width: 720
        height: 620
        implicitWidth: 720
        implicitHeight: 620
        readonly property real s: Math.min(width / 720, height / 620)
        readonly property real ox: (width - 720 * s) / 2
        readonly property real oy: (height - 620 * s) / 2

        Item {
            id: board
            width: 720
            height: 620
            x: container.ox
            y: container.oy
            scale: container.s
            transformOrigin: Item.TopLeft
            clip: true

            // panel
            Rectangle {
                anchors.fill: parent
                border.color: "#8f8f3a"
                border.width: 1
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#ef0d0d07" }
                    GradientStop { position: 0.5; color: "#e60a0a05" }
                    GradientStop { position: 1.0; color: "#ef0c0c06" }
                }
            }

            // scanlines
            Canvas {
                anchors.fill: parent
                opacity: 0.55
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    ctx.strokeStyle = "rgba(214,216,78,0.07)"
                    ctx.lineWidth = 1
                    for (var yy = 0; yy < height; yy += 4) {
                        ctx.beginPath()
                        ctx.moveTo(0, yy + 0.5)
                        ctx.lineTo(width, yy + 0.5)
                        ctx.stroke()
                    }
                }
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
            }

            // top / bottom vignette
            Rectangle {
                width: parent.width
                height: 74
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#b0000000" }
                    GradientStop { position: 1.0; color: "#00000000" }
                }
            }
            Rectangle {
                width: parent.width
                height: 74
                y: parent.height - height
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#00000000" }
                    GradientStop { position: 1.0; color: "#b0000000" }
                }
            }

            // corner brackets + frame accents
            Rectangle { x: 8; y: 8; width: 28; height: 2; color: root.cLine }
            Rectangle { x: 8; y: 8; width: 2; height: 28; color: root.cLine }
            Rectangle { x: parent.width - 36; y: parent.height - 10; width: 28; height: 2; color: root.cLine }
            Rectangle { x: parent.width - 10; y: parent.height - 36; width: 2; height: 28; color: root.cLine }
            Rectangle { x: 1; y: 1; width: parent.width - 2; height: 2; color: root.cLine; opacity: 0.35 }
            Rectangle { x: 20; y: 58; width: parent.width - 40; height: 1; color: root.cFaint }
            Rectangle { x: 20; y: 576; width: parent.width - 40; height: 1; color: root.cFaint }

            // ── click anywhere ─────────────────────────────────────
            MouseArea {
                anchors.fill: parent
                cursorShape: (root.phase === "choosing" || root.phase === "playing") ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (root.phase === "ready") {
                        root.toast = "PRESS START HACKING // LINK LOCKED"
                        toastTimer.restart()
                    } else if (root.phase === "choosing") {
                        root.toast = "CHOOSE A START NODE IN THE MATRIX"
                        toastTimer.restart()
                    } else if (root.phase === "playing") {
                        root.appendLog("manual scan pulse // no anomaly")
                        linkSweep.restart()
                        clickFlashAnim.restart()
                    }
                }
            }

            Rectangle {
                id: clickFlash
                anchors.fill: parent
                color: root.cLine
                opacity: 0
            }
            SequentialAnimation {
                id: clickFlashAnim
                NumberAnimation { target: clickFlash; property: "opacity"; from: 0.10; to: 0; duration: 280 }
            }

            // ── header ─────────────────────────────────────────────
            Text {
                x: 20
                y: 10
                text: "BREACH PROTOCOL"
                color: root.cBright
                font.family: chakra.name
                font.pixelSize: 23
                font.letterSpacing: 7
            }
            Text {
                x: 20
                y: 42
                text: "ACCESS POINT // 0x7F4A // NIGHT CITY GRID"
                color: root.cDim
                font.family: raj.name
                font.pixelSize: 9
                font.letterSpacing: 3
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 20
                y: 12
                text: "NETWATCH // ICE ACTIVE"
                color: root.cLine
                font.family: raj.name
                font.pixelSize: 9
                font.letterSpacing: 2
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 20
                y: 30
                text: root.phase === "boot" ? "DECRYPTING..."
                    : root.phase === "ready" ? "LINK STANDBY"
                    : root.phase === "choosing" ? "AWAITING NODE"
                    : root.phase === "upload" ? "UPLOADING"
                    : root.phase === "result" ? "SESSION CLOSED"
                    : "LINK OPEN"
                color: root.phase === "boot" ? root.cLine : root.cDim
                font.family: raj.name
                font.pixelSize: 8
                font.letterSpacing: 2
            }

            // ── timer ──────────────────────────────────────────────
            Text {
                x: 20
                y: 68
                text: "BREACH TIME REMAINING"
                color: root.cLine
                font.family: raj.name
                font.pixelSize: 9
                font.letterSpacing: 3
            }
            Text {
                x: 20
                y: 80
                text: root.timeLeft
                color: (root.phase === "playing" && root.timeLeft <= 10)
                       ? (root.blink ? root.cDanger : root.cBright) : root.cBright
                font.family: chakra.name
                font.pixelSize: 34
            }
            Row {
                x: 80
                y: 99
                spacing: 3
                Repeater {
                    model: 30
                    Rectangle {
                        required property int index
                        width: 5
                        height: 9
                        color: index < root.timeLeft
                               ? ((root.phase === "playing" && root.timeLeft <= 10) ? root.cDanger : root.cLine)
                               : root.cFaint
                        opacity: index < root.timeLeft ? 1 : 0.35
                    }
                }
            }
            Text {
                x: 350
                y: 99
                text: "TRACE " + root.trace + "%"
                color: root.trace > 70 ? root.cDanger : root.cDim
                font.family: raj.name
                font.pixelSize: 9
                font.letterSpacing: 2
            }

            // ── buffer ─────────────────────────────────────────────
            Text {
                x: 20
                y: 124
                text: "BUFFER " + root.buffer.length + "/4"
                color: root.cLine
                font.family: raj.name
                font.pixelSize: 9
                font.letterSpacing: 3
            }
            Row {
                x: 20
                y: 138
                spacing: 6
                Repeater {
                    model: 4
                    Rectangle {
                        id: slot
                        required property int index
                        readonly property bool used: root.buffer.length > index

                        width: 54
                        height: 38
                        color: used ? "#242006" : "#0d0b04"
                        border.width: 1
                        border.color: used ? root.cLine : root.cFaint
                        scale: used ? 1.0 : 0.94
                        Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutBack } }
                        Behavior on color { ColorAnimation { duration: 180 } }

                        Text {
                            anchors.centerIn: parent
                            text: used ? root.buffer[index] : ""
                            color: root.cBright
                            font.family: "DejaVu Sans Mono"
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Rectangle {
                            id: slotFlash
                            anchors.fill: parent
                            color: root.cBright
                            opacity: 0
                        }
                        SequentialAnimation {
                            id: slotPop
                            NumberAnimation { target: slotFlash; property: "opacity"; from: 0.55; to: 0; duration: 380 }
                        }
                        onUsedChanged: if (used) slotPop.restart()

                        // newest-slot brackets
                        Rectangle { visible: slot.index === root.buffer.length - 1 && slot.used; x: -3; y: -3; width: 10; height: 2; color: root.cBright }
                        Rectangle { visible: slot.index === root.buffer.length - 1 && slot.used; x: -3; y: -3; width: 2; height: 10; color: root.cBright }
                        Rectangle { visible: slot.index === root.buffer.length - 1 && slot.used; x: parent.width - 7; y: parent.height + 1; width: 10; height: 2; color: root.cBright }
                        Rectangle { visible: slot.index === root.buffer.length - 1 && slot.used; x: parent.width + 1; y: parent.height - 7; width: 2; height: 10; color: root.cBright }
                    }
                }
            }

            // ── code matrix ────────────────────────────────────────
            Text {
                x: 20
                y: 188
                text: "CODE MATRIX"
                color: root.cLine
                font.family: raj.name
                font.pixelSize: 9
                font.letterSpacing: 3
            }

            Item {
                id: matrixBox
                x: 20 + root.shakeX
                y: 202
                width: 397
                height: 277
                clip: true

                // active line glow
                Rectangle {
                    x: 0
                    y: root.lastRow * 47
                    width: matrixBox.width
                    height: 42
                    color: root.cLine
                    z: 5
                    opacity: 0.085
                    visible: (root.phase === "playing" || root.phase === "ready") && root.pickMode === "row"
                }
                Rectangle {
                    x: root.lastCol * 67
                    y: 0
                    width: 62
                    height: matrixBox.height
                    color: root.cLine
                    z: 5
                    opacity: 0.085
                    visible: root.phase === "playing" && root.pickMode === "column"
                }

                Grid {
                    id: grid
                    columns: 6
                    spacing: 5

                    Repeater {
                        model: 36
                        Rectangle {
                            id: cell
                            required property int index

                            readonly property bool legal: (root.rev, root.isAllowed(index))
                            readonly property bool picked: index === root.lastPicked
                            readonly property bool rejected: index === root.rejectIndex
                            readonly property bool hexHit: root.highlightHex !== "" && root.matrix[index] === root.highlightHex

                            width: 62
                            height: 42
                            radius: 1

                            color: picked ? "#2e2808"
                                 : (root.hoverIndex === index && legal) ? "#221d06"
                                 : legal ? "#151205" : "#0b0903"
                            border.width: 1
                            border.color: rejected ? root.cDanger
                                        : picked ? root.cBright
                                        : hexHit ? root.cBright
                                        : legal ? root.cLine : root.cFaint
                            opacity: (legal || picked) ? 1.0 : 0.48

                            Behavior on color { ColorAnimation { duration: 110 } }
                            scale: root.hoverIndex === index ? 1.055 : 1.0
                            Behavior on scale { NumberAnimation { duration: 90 } }

                            Text {
                                anchors.centerIn: parent
                                text: (root.phase === "boot" && index >= root.decryptIndex)
                                      ? root.hexPool[(index + root.scramble) % root.hexPool.length]
                                      : root.matrix[index]
                                color: (root.phase === "boot" && index >= root.decryptIndex) ? root.cDim
                                     : picked ? root.cBright : legal ? root.cBright : root.cDim
                                font.family: "DejaVu Sans Mono"
                                font.pixelSize: 17
                                font.bold: true
                            }

                            // hover / pick brackets
                            Rectangle { visible: root.hoverIndex === cell.index || cell.picked; x: -3; y: -3; width: 9; height: 2; color: root.cBright }
                            Rectangle { visible: root.hoverIndex === cell.index || cell.picked; x: -3; y: -3; width: 2; height: 9; color: root.cBright }
                            Rectangle { visible: root.hoverIndex === cell.index || cell.picked; x: parent.width - 6; y: parent.height + 1; width: 9; height: 2; color: root.cBright }
                            Rectangle { visible: root.hoverIndex === cell.index || cell.picked; x: parent.width + 1; y: parent.height - 6; width: 2; height: 9; color: root.cBright }

                            // sequence hover highlight
                            Rectangle {
                                anchors.fill: parent
                                color: root.cBright
                                opacity: cell.hexHit ? 0.10 : 0
                                Behavior on opacity { NumberAnimation { duration: 120 } }
                            }

                            // rejected flash
                            Rectangle {
                                anchors.fill: parent
                                color: root.cDanger
                                opacity: cell.rejected ? 0.32 : 0
                                Behavior on opacity { NumberAnimation { duration: 220 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: (root.phase === "playing" || root.phase === "choosing") ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onEntered: root.hoverIndex = cell.index
                                onExited: if (root.hoverIndex === cell.index) root.hoverIndex = -1
                                onClicked: root.pick(cell.index)
                            }
                        }
                    }
                }

                // CRT sweep on link
                Rectangle {
                    id: linkFlash
                    width: matrixBox.width
                    height: 34
                    y: 0
                    opacity: 0
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#00d6d84e" }
                        GradientStop { position: 0.5; color: "#88d6d84e" }
                        GradientStop { position: 1.0; color: "#00d6d84e" }
                    }
                }
                Connections {
                    target: root
                    function onSweepRequested() { linkSweep.restart() }
                }
                SequentialAnimation {
                    id: linkSweep
                    PropertyAction { target: linkFlash; property: "opacity"; value: 0.9 }
                    NumberAnimation {
                        target: linkFlash
                        property: "y"
                        from: 0
                        to: matrixBox.height - 34
                        duration: 620
                        easing.type: Easing.OutCubic
                    }
                    PropertyAction { target: linkFlash; property: "opacity"; value: 0 }
                }

                // idle scanline
                Rectangle {
                    width: matrixBox.width
                    height: 22
                    y: -24
                    opacity: 0.12
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#00d6d84e" }
                        GradientStop { position: 0.5; color: "#66d6d84e" }
                        GradientStop { position: 1.0; color: "#00d6d84e" }
                    }
                    SequentialAnimation on y {
                        loops: Animation.Infinite
                        PauseAnimation { duration: 5200 }
                        NumberAnimation { from: -24; to: matrixBox.height; duration: 3200 }
                    }
                }

                // boot frontier
                Rectangle {
                    visible: root.phase === "boot"
                    width: matrixBox.width
                    height: 2
                    x: 0
                    y: Math.min(matrixBox.height - 2, Math.floor(root.decryptIndex / 6) * 47 + 42)
                    color: root.cBright
                    opacity: 0.65
                }
            }

            // ── start hacking ──────────────────────────────────────
            Item {
                id: startOverlay
                x: 20
                y: 202
                width: 397
                height: 277
                z: 20
                visible: root.phase === "ready"

                Rectangle { anchors.fill: parent; color: "#d2060603" }
                Rectangle { anchors.fill: parent; color: "transparent"; border.color: root.cFaint; border.width: 1 }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.toast = "PRESS START HACKING"
                        toastTimer.restart()
                    }
                }

                Rectangle {
                    id: startBtn
                    anchors.centerIn: parent
                    width: 330
                    height: 78
                    color: startMouse.containsMouse ? "#35300c" : "#1e1a07"
                    border.color: root.cLine
                    border.width: 2
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -7
                        color: "transparent"
                        border.color: root.cLine
                        border.width: 1
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.15; duration: 900 }
                            NumberAnimation { to: 0.65; duration: 900 }
                        }
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 12
                        spacing: 12

                        Item {
                            width: 14
                            height: 27
                            Text {
                                anchors.centerIn: parent
                                text: "▶"
                                color: root.cLine
                                font.family: "DejaVu Sans"
                                font.pixelSize: 16
                            }
                        }
                        Text {
                            height: 27
                            verticalAlignment: Text.AlignVCenter
                            text: "START HACKING"
                            color: root.cBright
                            font.family: chakra.name
                            font.pixelSize: 20
                            font.letterSpacing: 4
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 9
                        text: "JACK INTO ACCESS POINT 0x7F4A"
                        color: root.cDim
                        font.family: raj.name
                        font.pixelSize: 8
                        font.letterSpacing: 2
                    }

                    MouseArea {
                        id: startMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.beginHack()
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 20
                    text: "ICE LOCKED // BUFFER OFFLINE"
                    color: root.cDim
                    font.family: raj.name
                    font.pixelSize: 8
                    font.letterSpacing: 3
                }
            }

            // ── line rule / toast ──────────────────────────────────
            Text {
                x: 20
                y: 492
                text: root.phase === "ready" ? "PRESS START HACKING TO ARM THE BREACH"
                    : root.phase === "choosing" ? "CHOOSE START NODE // ANY CELL IN THE MATRIX"
                    : root.phase === "playing" ? "LINE LOCKED // " + (root.pickMode === "row"
                        ? "ROW " + (root.lastRow + 1) : "COLUMN " + (root.lastCol + 1))
                    : root.phase === "upload" ? "FLUSHING BUFFER // UPLOADING"
                    : "CLICK ANYWHERE TO RE-BREACH"
                color: root.cLine
                font.family: raj.name
                font.pixelSize: 9
                font.letterSpacing: 2
            }
            Text {
                x: 20
                y: 510
                text: root.toast
                color: root.cDanger
                font.family: raj.name
                font.pixelSize: 9
                font.letterSpacing: 2
                visible: root.toast !== ""
            }

            // ── daemons ────────────────────────────────────────────
            Text {
                x: 434
                y: 68
                text: "SEQUENCE REQUIRED TO UPLOAD"
                color: root.cLine
                font.family: raj.name
                font.pixelSize: 9
                font.letterSpacing: 2
            }
            Text {
                x: 434
                y: 88
                width: 266
                height: 40
                visible: root.daemons.length === 0
                text: root.phase === "choosing" ? "AWAITING START NODE // SELECT ANY CELL"
                    : "NO ACTIVE SEQUENCE // PRESS START HACKING"
                color: root.cDim
                font.family: raj.name
                font.pixelSize: 8
                font.letterSpacing: 2
                wrapMode: Text.WordWrap
            }
            Column {
                x: 434
                y: 88
                width: 266
                spacing: 16

                Repeater {
                    model: root.daemons
                    Item {
                        id: daemonBlock
                        required property int index
                        required property var modelData

                        width: 266
                        height: 62

                        Text {
                            x: 0
                            y: 0
                            text: daemonBlock.modelData.name
                            color: root.cBright
                            font.family: chakra.name
                            font.pixelSize: 11
                            font.letterSpacing: 2
                        }
                        Text {
                            anchors.right: parent.right
                            y: 0
                            text: root.daemonStatus(daemonBlock.modelData.seq)
                            color: root.hasSequence(daemonBlock.modelData.seq) ? root.cGreen : root.cDim
                            font.family: raj.name
                            font.pixelSize: 8
                            font.letterSpacing: 2
                        }
                        Row {
                            x: 0
                            y: 17
                            spacing: 6
                            Repeater {
                                model: daemonBlock.modelData.seq.length
                                Rectangle {
                                    required property int index
                                    readonly property bool hit: root.daemonProgress(daemonBlock.modelData.seq) > index

                                    width: 42
                                    height: 31
                                    color: hit ? "#2c2608" : "#0e0c04"
                                    border.width: 1
                                    border.color: hit ? root.cLine : root.cFaint
                                    Behavior on color { ColorAnimation { duration: 140 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: daemonBlock.modelData.seq[index]
                                        color: hit ? root.cBright : root.cDim
                                        font.family: "DejaVu Sans Mono"
                                        font.pixelSize: 13
                                        font.bold: true
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: root.highlightHex = daemonBlock.modelData.seq[index]
                                        onExited: if (root.highlightHex === daemonBlock.modelData.seq[index]) root.highlightHex = ""
                                    }
                                }
                            }
                        }
                        Item {
                            x: 0
                            y: 54
                            width: 138
                            height: 2
                            Rectangle { anchors.fill: parent; color: root.cFaint }
                            Rectangle {
                                height: parent.height
                                width: parent.width * (root.daemonProgress(daemonBlock.modelData.seq) / daemonBlock.modelData.seq.length)
                                color: root.cLine
                                Behavior on width { NumberAnimation { duration: 160 } }
                            }
                        }
                    }
                }
            }

            // ── upload link ────────────────────────────────────────
            Text {
                x: 434
                y: 236
                text: "UPLOAD LINK"
                color: root.cLine
                font.family: raj.name
                font.pixelSize: 9
                font.letterSpacing: 3
            }
            Item {
                x: 434
                y: 250
                width: 266
                height: 8
                Rectangle { anchors.fill: parent; color: "#1a1806" }
                Rectangle {
                    height: parent.height
                    width: parent.width * (root.phase === "upload" ? root.uploadProgress
                                         : root.phase === "result" ? (root.won ? 1 : 0)
                                         : root.buffer.length / 4)
                    color: root.phase === "result" && !root.won ? root.cDanger
                         : root.phase === "result" && root.won ? root.cGreen : root.cLine
                    Behavior on width { NumberAnimation { duration: 200 } }
                }
            }
            Text {
                x: 434
                y: 264
                text: root.phase === "upload" ? "UPLOADING " + Math.round(root.uploadProgress * 100) + "%"
                    : root.phase === "result" ? (root.won ? "DAEMON INJECTED" : "TRACE LOCKED")
                    : "BUFFER " + root.buffer.length + "/4 // STANDBY"
                color: root.phase === "result" ? (root.won ? root.cGreen : root.cDanger) : root.cDim
                font.family: raj.name
                font.pixelSize: 8
                font.letterSpacing: 2
            }

            // ── net log ────────────────────────────────────────────
            Text {
                x: 434
                y: 300
                text: "NET LOG // LIVE"
                color: root.cLine
                font.family: raj.name
                font.pixelSize: 9
                font.letterSpacing: 3
            }
            Text {
                x: 434
                y: 314
                width: 266
                height: 156
                text: root.logText
                color: root.cDim
                font.family: "DejaVu Sans Mono"
                font.pixelSize: 8
                lineHeight: 1.25
                wrapMode: Text.WordWrap
                clip: true
            }
            Rectangle {
                x: 434
                y: 474
                width: 6
                height: 10
                color: root.cLine
                visible: root.phase === "playing" || root.phase === "ready"
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { to: 0; duration: 420 }
                    NumberAnimation { to: 1; duration: 420 }
                }
            }
            Text {
                x: 448
                y: 474
                text: "SYS OK // 0x7F4A"
                color: root.cDim
                font.family: raj.name
                font.pixelSize: 8
                font.letterSpacing: 2
            }

            // ── footer ─────────────────────────────────────────────
            Text {
                x: 20
                y: 586
                text: "ROW → COLUMN → ROW → COLUMN"
                color: root.cDim
                font.family: raj.name
                font.pixelSize: 8
                font.letterSpacing: 2
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 20
                y: 586
                text: "NETWATCH TRACE " + root.trace + "%"
                color: root.trace > 70 ? root.cDanger : root.cDim
                font.family: raj.name
                font.pixelSize: 8
                font.letterSpacing: 2
            }

            // ── glitch ─────────────────────────────────────────────
            Rectangle {
                visible: root.glitch
                x: 0
                y: root.glitchY
                width: parent.width
                height: 2
                color: root.cLine
                opacity: 0.55
            }
            Rectangle {
                visible: root.glitch
                x: 34
                y: root.glitchY + 7
                width: parent.width - 90
                height: 5
                color: root.cDanger
                opacity: 0.20
            }

            // ── upload / result overlay ────────────────────────────
            Rectangle {
                anchors.fill: parent
                color: "#e60a0a04"
                visible: root.phase === "upload" || root.phase === "result"
                z: 50

                Rectangle { x: 40; y: 40; width: 34; height: 2; color: root.cLine }
                Rectangle { x: 40; y: 40; width: 2; height: 34; color: root.cLine }
                Rectangle { x: parent.width - 74; y: parent.height - 42; width: 34; height: 2; color: root.cLine }
                Rectangle { x: parent.width - 42; y: parent.height - 74; width: 2; height: 34; color: root.cLine }

                Column {
                    anchors.centerIn: parent
                    width: 500
                    spacing: 12

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.phase === "upload" ? "UPLOADING DAEMON"
                            : root.won ? "ACCESS GRANTED" : "TRACE COMPLETE"
                        color: root.phase === "upload" ? root.cBright
                             : root.won ? root.cGreen : root.cDanger
                        font.family: chakra.name
                        font.pixelSize: 32
                        font.letterSpacing: 9
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.phase === "upload" ? "BUFFER FLUSH // DO NOT DISCONNECT"
                            : root.won ? "DAEMON INJECTED INTO NETWORK"
                            : "ICE COUNTERMEASURE TRIGGERED"
                        color: root.cDim
                        font.family: raj.name
                        font.pixelSize: 11
                        font.letterSpacing: 3
                    }

                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 5
                        Repeater {
                            model: root.phase === "upload" ? root.daemons : root.results
                            Row {
                                spacing: 14
                                Text {
                                    text: modelData.name
                                    color: root.cBright
                                    font.family: "DejaVu Sans Mono"
                                    font.pixelSize: 13
                                }
                                Text {
                                    text: root.statusFor(modelData)
                                    color: root.statusColor(modelData)
                                    font.family: raj.name
                                    font.pixelSize: 12
                                    font.letterSpacing: 2
                                }
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: 10
                        Rectangle { anchors.fill: parent; color: "#1a1806" }
                        Rectangle {
                            height: parent.height
                            width: parent.width * (root.phase === "upload" ? root.uploadProgress : 1)
                            color: root.phase === "upload" ? root.cLine : (root.won ? root.cGreen : root.cDanger)
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.phase === "upload" ? Math.round(root.uploadProgress * 100) + "%"
                            : root.won ? "UPLOAD COMPLETE" : "UPLOAD FAILED"
                        color: root.phase === "upload" ? root.cLine
                             : root.won ? root.cGreen : root.cDanger
                        font.family: chakra.name
                        font.pixelSize: 11
                        font.letterSpacing: 3
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.phase === "result"
                        text: "CLICK ANYWHERE TO RE-BREACH"
                        color: root.cDim
                        font.family: raj.name
                        font.pixelSize: 10
                        font.letterSpacing: 3
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.35; duration: 800 }
                            NumberAnimation { to: 1.0; duration: 800 }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.phase === "result"
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.newGame()
                }
            }
        }
    }
}
