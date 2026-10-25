import QtQuick
import QtQuick.Window
import org.kde.plasma.plasma5support as Plasma5Support

Window {
    id: root

    width: 480
    height: 680
    visible: true
    color: "transparent"
    title: "Capri // Transmission"
    flags: Qt.FramelessWindowHint | Qt.Tool | Qt.WindowStaysOnTopHint

    readonly property color ink: "#0d0910"
    readonly property color ink2: "#1a1320"
    readonly property color paper: "#f7f0f2"
    readonly property color paper2: "#d8c9cf"
    readonly property color paper3: "#9a8a93"
    readonly property color red: "#ff4d60"
    readonly property color green: "#0dff6e"
    readonly property color violet: "#8a3cff"

    property bool busy: false
    property bool online: false
    property string status: "LINKING"
    property string faceFile: "face-smug.png"
    property int dots: 0
    property string agentUrl: "http://127.0.0.1:8787"

    readonly property string assetDir: "file:///home/marteam/.local/share/capricorn/assets/"
    readonly property color accent: busy ? violet : (online ? green : red)

    Plasma5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: function (sourceName, data) { exec.disconnectSource(sourceName) }
        function run(cmd) { exec.connectSource(cmd) }
    }

    ListModel { id: chat }

    Shortcut {
        sequence: "Escape"
        onActivated: Qt.quit()
    }

    // ── conversation ────────────────────────────────────────────────
    function addMsg(kind, text) {
        chat.append({ kind: kind, text: text })
        Qt.callLater(function () { convo.positionViewAtEnd() })
    }

    function setFace(name) {
        if (faceFile === name) return
        faceFile = name
        faceGlitch.restart()
    }

    function faceFor(text) {
        var t = (text || "").toLowerCase()
        if (t.indexOf("error") >= 0 || t.indexOf("failed") >= 0 || t.indexOf("can't") >= 0)
            return "face-wide.png"
        if (t.indexOf("?") >= 0) return "face-look.png"
        if (t.length < 90) return "face-smug.png"
        if (t.length > 420) return "face-calm.png"
        return "face-calm.png"
    }

    function checkAgent() {
        var x = new XMLHttpRequest()
        x.open("GET", agentUrl + "/health")
        x.timeout = 4000
        x.onreadystatechange = function () {
            if (x.readyState !== XMLHttpRequest.DONE) return
            online = (x.status === 200)
            status = busy ? "THINKING" : (online ? "LINKED" : "OFFLINE")
        }
        x.send()
    }

    function send() {
        var text = input.text.trim()
        if (text.length === 0 || busy) return
        addMsg("user", text)
        input.text = ""
        busy = true
        status = "THINKING"
        dots = 0
        thinkTimer.restart()
        setFace("face-aside.png")

        var x = new XMLHttpRequest()
        x.open("POST", agentUrl + "/chat")
        x.setRequestHeader("Content-Type", "application/json")
        x.timeout = 320000
        x.onreadystatechange = function () {
            if (x.readyState !== XMLHttpRequest.DONE) return
            busy = false
            thinkTimer.stop()
            dots = 0
            if (x.status === 200) {
                online = true
                try {
                    var data = JSON.parse(x.responseText)
                    if (data.reply) {
                        addMsg("capri", data.reply)
                        setFace(faceFor(data.reply))
                    } else {
                        addMsg("error", "AGENT // " + (data.error || "empty reply"))
                        setFace("face-wide.png")
                    }
                } catch (e) {
                    addMsg("error", "AGENT // malformed reply")
                    setFace("face-wide.png")
                }
            } else {
                online = false
                addMsg("error", "AGENT OFFLINE // start it with: systemctl --user start capri-agent")
                setFace("face-wide.png")
            }
            status = online ? "LINKED" : "OFFLINE"
        }
        x.ontimeout = function () {
            busy = false
            thinkTimer.stop()
            dots = 0
            addMsg("error", "AGENT TIMEOUT // still busy, try again in a moment")
            setFace("face-wide.png")
            status = online ? "LINKED" : "OFFLINE"
        }
        x.send(JSON.stringify({ message: text }))
    }

    function quickAction(cmd) {
        exec.run(cmd)
    }

    function startAgent() {
        exec.run("systemctl --user start capri-agent.service")
        status = "LINKING"
        healthTimer.restart()
    }

    Timer {
        id: healthTimer
        interval: 1800
        onTriggered: root.checkAgent()
    }

    Timer {
        id: thinkTimer
        interval: 380
        repeat: true
        running: false
        onTriggered: root.dots = (root.dots + 1) % 4
    }

    Component.onCompleted: {
        addMsg("sys", "SESSION LINKED // NIGHT CITY")
        addMsg("capri", "Hey. Capri here.\nTuned in. What are we doing?")
        setFace("face-smug.png")
        checkAgent()
        input.forceActiveFocus()
    }

    // ── panel plate ─────────────────────────────────────────────────
    Canvas {
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var x = 14, y = 14, w = 452, h = 652

            function plate(dx, dy, fill) {
                ctx.beginPath()
                ctx.moveTo(x + dx, y + 14 + dy)
                ctx.lineTo(x + 14 + dx, y + dy)
                ctx.lineTo(x + w * 0.61 + dx, y + dy)
                ctx.lineTo(x + w * 0.63 + dx, y + 7 + dy)
                ctx.lineTo(x + w * 0.655 + dx, y + dy)
                ctx.lineTo(x + w - 30 + dx, y + dy)
                ctx.lineTo(x + w + dx, y + 30 + dy)
                ctx.lineTo(x + w + dx, y + h + dy)
                ctx.lineTo(x + 22 + dx, y + h + dy)
                ctx.lineTo(x + dx, y + h - 22 + dy)
                ctx.closePath()
                ctx.fillStyle = fill
                ctx.fill()
            }

            plate(7, 7, root.violet)
            plate(0, 0, root.ink)
        }
    }

    // ── header ──────────────────────────────────────────────────────
    Rectangle {
        x: 32; y: 28; width: 64; height: 64
        color: root.violet
    }
    Image {
        id: face
        x: 28; y: 24; width: 64; height: 64
        source: root.assetDir + root.faceFile
        fillMode: Image.PreserveAspectCrop
        smooth: true
    }
    Rectangle {
        x: 28; y: 24; width: 64; height: 64
        color: "transparent"
        border.color: root.ink
        border.width: 1
    }
    SequentialAnimation {
        id: faceGlitch
        NumberAnimation { target: face; property: "x"; to: 34; duration: 35 }
        NumberAnimation { target: face; property: "y"; to: 20; duration: 35 }
        NumberAnimation { target: face; property: "x"; to: 24; duration: 35 }
        NumberAnimation { target: face; property: "y"; to: 26; duration: 35 }
        NumberAnimation { target: face; property: "x"; to: 28; duration: 45 }
        NumberAnimation { target: face; property: "y"; to: 24; duration: 45 }
    }

    Text {
        x: 106; y: 20
        text: "CAPRI"
        color: root.paper
        font.family: "Chakra Petch"
        font.pixelSize: 22
        font.letterSpacing: 3
    }
    Text {
        x: 106; y: 48
        text: "TRANSMISSION  /  PROJECT CAPRICORN"
        color: root.paper3
        font.family: "JetBrains Mono"
        font.pixelSize: 8
        font.letterSpacing: 1
    }
    Text {
        x: 106; y: 64
        text: root.busy ? "CAPRI IS THINKING" + ".".repeat(root.dots + 1)
                       : (root.online ? "AGENT LINKED // 127.0.0.1:8787"
                                      : "AGENT OFFLINE // CLICK AGENT TO START")
        color: root.busy ? root.violet : (root.online ? root.green : root.red)
        font.family: "JetBrains Mono"
        font.pixelSize: 8
    }

    Rectangle {
        x: 384; y: 24; width: 70; height: 18
        color: root.accent
        Text {
            anchors.centerIn: parent
            text: root.busy ? "THINKING" : (root.online ? "LINKED" : "OFFLINE")
            color: root.ink
            font.family: "JetBrains Mono"
            font.pixelSize: 7
            font.bold: true
            font.letterSpacing: 1
        }
    }

    Item {
        x: 438; y: 18; width: 26; height: 26
        Text {
            anchors.centerIn: parent
            text: "✕"
            color: closeHover.containsMouse ? root.paper : root.paper3
            font.family: "DejaVu Sans"
            font.pixelSize: 14
        }
        MouseArea {
            id: closeHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Qt.quit()
        }
    }

    MouseArea {
        x: 20; y: 18; width: 412; height: 80
        onPressed: root.startSystemMove()
    }

    Rectangle {
        x: 28; y: 102; width: 424; height: 1
        color: "#2a1e33"
    }

    // ── conversation ────────────────────────────────────────────────
    ListView {
        id: convo
        x: 28; y: 112; width: 424; height: 408
        clip: true
        spacing: 10
        model: chat
        boundsBehavior: Flickable.StopAtBounds

        delegate: Item {
            width: ListView.view.width
            height: model.kind === "sys" || model.kind === "error"
                    ? txt.implicitHeight + 8
                    : txt.implicitHeight + 26

            Rectangle {
                visible: model.kind === "capri"
                x: 0; y: 0; width: 2; height: parent.height - 6
                color: root.violet
            }
            Rectangle {
                visible: model.kind === "user"
                x: parent.width - txt.width - 24
                y: 0
                width: txt.width + 24
                height: txt.implicitHeight + 16
                color: root.ink2
                border.color: "#2e2138"
                border.width: 1
            }

            Text {
                id: txt
                x: model.kind === "user" ? parent.width - width - 12 : 12
                y: model.kind === "user" ? 8 : (model.kind === "capri" ? 2 : 2)
                width: model.kind === "user" ? Math.min(340, parent.width - 60) : parent.width - 20
                text: model.text
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                color: model.kind === "error" ? root.red
                     : model.kind === "sys" ? root.green
                     : model.kind === "user" ? root.paper
                     : root.paper2
                font.family: (model.kind === "capri" && model.text.length < 140)
                             ? "Chakra Petch" : "JetBrains Mono"
                font.pixelSize: model.kind === "sys" || model.kind === "error" ? 8.5
                              : (model.kind === "user" ? 10 : (model.text.length < 140 ? 13 : 10.5))
                lineHeight: 1.35
            }
        }

        onCountChanged: Qt.callLater(function () { positionViewAtEnd() })
    }

    // ── quick actions ───────────────────────────────────────────────
    Row {
        x: 28; y: 532; spacing: 8
        Repeater {
            model: [
                { label: "BREACH", cmd: "/home/marteam/.local/bin/capricorn-breach-open.sh" },
                { label: "SESSION", cmd: "/home/marteam/.local/bin/capri-session.sh" },
                { label: "OPENCODE", cmd: "/home/marteam/.local/bin/capri-opencode.sh" },
                { label: "AGENT", cmd: "agent" }
            ]
            Rectangle {
                required property var modelData
                width: 96; height: 28
                color: qHover.containsMouse ? root.violet : root.ink2
                border.color: qHover.containsMouse ? root.paper : "#3a2a44"
                border.width: 1
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: modelData.label
                    color: qHover.containsMouse ? root.ink : root.paper2
                    font.family: "Chakra Petch"
                    font.pixelSize: 8
                    font.letterSpacing: 1
                }
                MouseArea {
                    id: qHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.cmd === "agent" ? root.startAgent() : root.quickAction(modelData.cmd)
                }
            }
        }
    }

    // ── input ───────────────────────────────────────────────────────
    Rectangle {
        x: 28; y: 574; width: 344; height: 40
        color: root.ink2
        border.color: input.activeFocus ? root.violet : "#3a2a44"
        border.width: 1
        opacity: root.busy ? 0.55 : 1

        Rectangle {
            x: 0; y: 0; width: 2; height: parent.height
            color: root.accent
        }

        Text {
            x: 12; y: 12
            visible: input.text.length === 0
            text: root.busy ? "waiting for Capri..." : "Tell Capri what to do..."
            color: root.paper3
            font.family: "JetBrains Mono"
            font.pixelSize: 10
        }

        TextInput {
            id: input
            x: 12; y: 10
            width: parent.width - 24
            height: 22
            color: root.paper
            selectionColor: root.violet
            selectedTextColor: root.paper
            font.family: "JetBrains Mono"
            font.pixelSize: 11
            clip: true
            enabled: !root.busy
            onAccepted: root.send()
            Keys.onPressed: function (event) {
                if (event.key === Qt.Key_Escape) Qt.quit()
            }
        }
    }

    Rectangle {
        x: 380; y: 574; width: 72; height: 40
        color: root.busy ? root.ink2 : root.red
        border.color: root.busy ? "#3a2a44" : root.red
        border.width: 1
        opacity: root.busy ? 0.5 : 1

        Text {
            anchors.centerIn: parent
            text: "▶ SEND"
            color: root.busy ? root.paper3 : root.ink
            font.family: "Chakra Petch"
            font.pixelSize: 9
            font.letterSpacing: 1
        }
        MouseArea {
            anchors.fill: parent
            enabled: !root.busy
            cursorShape: Qt.PointingHandCursor
            onClicked: root.send()
        }
    }

    // ── footer ──────────────────────────────────────────────────────
    Text {
        x: 28; y: 640
        text: "CAPRI // DESKTOP CONSTRUCT"
        color: root.paper3
        font.family: "JetBrains Mono"
        font.pixelSize: 7
        font.letterSpacing: 1
    }
    Text {
        anchors.right: parent.right
        anchors.rightMargin: 28
        y: 640
        text: "ESC // CLOSE"
        color: root.paper3
        font.family: "JetBrains Mono"
        font.pixelSize: 7
        font.letterSpacing: 1
    }
}
