import QtQuick
import QtQuick.Window
import QtQuick.Effects
import org.kde.plasma.plasma5support as Plasma5Support

Window {
    id: win

    width: 300
    height: 540
    visible: true
    color: "transparent"
    title: "CAPRI // PROJECT CAPRICORN"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool

    readonly property string assets: "file:///home/marteam/.local/share/capricorn/assets/"
    readonly property color ink: "#0d0910"
    readonly property color paper: "#f7f0f2"
    readonly property color paper3: "#9a8a93"
    readonly property color red: "#ff4d60"
    readonly property color green: "#0dff6e"
    readonly property color violet: "#8a3cff"

    property bool asleep: false
    property bool hovered: false
    property bool glitching: false
    property bool peeking: false
    property bool menuOpen: false
    property bool roaming: true
    property bool bubbleVisible: true
    property string bubbleText: "hey."
    property string bubbleFace: "face-smug.png"

    property int frame: 0
    property real bob: 0
    property real tilt: 0
    property real baseY: 90
    property bool busyMoving: false
    property bool dragging: false
    property bool moved: false
    property real dragStartX: 0
    property real dragStartY: 0
    property real dragWinX: 0
    property real dragWinY: 0
    property var lastActivity: Date.now()
    property var shards: []

    Plasma5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: function (sourceName, data) { exec.disconnectSource(sourceName) }
        function run(cmd) { exec.connectSource(cmd) }
    }

    // ── screen geometry ─────────────────────────────────────────────
    function bounds() {
        var vx = 0, vy = 0
        try {
            if (typeof Screen.virtualX === "number") vx = Screen.virtualX
            if (typeof Screen.virtualY === "number") vy = Screen.virtualY
        } catch (e) {}
        return {
            x0: vx + 8,
            x1: vx + Screen.width - win.width - 8,
            y0: vy + 8,
            y1: vy + Screen.height - win.height - 8
        }
    }

    function goHome() {
        var b = bounds()
        win.x = Math.round(b.x0 + (b.x1 - b.x0) * 0.66)
        win.y = Math.round(b.y0 + 40)
    }

    // ── speech / ticker ─────────────────────────────────────────────
    function showBubble(text, face, ms) {
        bubbleText = text
        bubbleFace = face || "face-smug.png"
        bubbleVisible = true
        bubbleTimer.interval = ms || 2800
        bubbleTimer.restart()
    }

    function idleLine() {
        var lines = [
            ["hey.", "face-smug.png"],
            ["psst.", "face-look.png"],
            ["need something?", "face-aside.png"],
            ["i'm bored.", "face-aside.png"],
            ["let's break something.", "face-smug.png"],
            ["night city never sleeps.", "face-calm.png"],
            ["watching you.", "face-look.png"],
            ["click me.", "face-smug.png"]
        ]
        var l = lines[Math.floor(Math.random() * lines.length)]
        showBubble(l[0], l[1], 3000)
    }

    // ── movement ────────────────────────────────────────────────────
    function randomSpot() {
        var b = bounds()
        return {
            x: Math.round(b.x0 + Math.random() * Math.max(1, b.x1 - b.x0)),
            y: Math.round(b.y0 + Math.random() * Math.max(1, b.y1 - b.y0))
        }
    }

    function teleportTo(x, y, line) {
        if (dragging) return
        busyMoving = true
        glitchNow(true)
        spawnShards(7, body.x + body.width / 2, body.y + 150)
        body.opacity = 0
        tpX = x
        tpY = y
        tpTimer.restart()
        if (line) showBubble(line, "face-smug.png", 1800)
    }

    property real tpX: 0
    property real tpY: 0

    Timer {
        id: tpTimer
        interval: 120
        onTriggered: {
            win.x = Math.round(tpX)
            win.y = Math.round(tpY)
            body.opacity = 1
            busyMoving = false
            spawnShards(5, body.x + body.width / 2, body.y + 180)
        }
    }

    function driftTo(x, y) {
        if (dragging) return
        busyMoving = true
        driftX.to = x
        driftY.to = y
        driftAnim.restart()
    }

    ParallelAnimation {
        id: driftAnim
        NumberAnimation { id: driftX; target: win; property: "x"; duration: 1900; easing.type: Easing.InOutQuad }
        NumberAnimation { id: driftY; target: win; property: "y"; duration: 1900; easing.type: Easing.InOutQuad }
        onFinished: win.busyMoving = false
    }

    function wanderStep() {
        if (!roaming || asleep || peeking || menuOpen || dragging || busyMoving) return
        var r = Math.random()
        if (r < 0.55) {
            var s = randomSpot()
            teleportTo(s.x, s.y, "over here.")
        } else if (r < 0.82) {
            peek()
        } else {
            glitchNow(true)
            showBubble(pickTaunt(), "face-smug.png", 2400)
        }
    }

    function pickTaunt() {
        var t = ["ta-da.", "miss me?", "catch me.", "boo.", "slow.", "heh."]
        return t[Math.floor(Math.random() * t.length)]
    }

    Timer {
        id: wanderTimer
        interval: 22000
        repeat: true
        running: !win.asleep
        onTriggered: {
            win.wanderStep()
            interval = 18000 + Math.random() * 26000
        }
    }

    Timer {
        id: peekTimer
        interval: 6200
        onTriggered: {
            win.peeking = false
            win.tilt = 0
            var s = win.randomSpot()
            win.teleportTo(s.x, s.y, "back.")
        }
    }

    function peek() {
        var b = bounds()
        peeking = true
        var side = Math.random() < 0.5 ? "left" : "right"
        var x = side === "left" ? b.x0 - 150 : b.x1 + 150
        var y = Math.round(b.y0 + Math.random() * Math.max(1, b.y1 - b.y0))
        teleportTo(x, y, "…")
        tilt = side === "left" ? 6 : -6
        showBubble("…", "face-aside.png", 4000)
        peekTimer.restart()
    }

    // ── glitch / shards ─────────────────────────────────────────────
    function glitchNow(big) {
        glitching = true
        glitchOff.restart()
        if (big) spawnShards(4, body.x + 80 + Math.random() * 120, body.y + 80 + Math.random() * 160)
    }

    Timer {
        id: glitchOff
        interval: 120
        onTriggered: win.glitching = false
    }

    function spawnShards(n, cx, cy) {
        var arr = shards.slice()
        for (var k = 0; k < n; k++) {
            var i = -1
            for (var j = 0; j < arr.length; j++) {
                if (!arr[j] || arr[j].life <= 0) { i = j; break }
            }
            var s = {
                x: cx + (Math.random() - 0.5) * 90,
                y: cy + (Math.random() - 0.5) * 140,
                vx: (Math.random() - 0.5) * 2.2,
                vy: -0.5 - Math.random() * 2.2,
                life: 1.0,
                size: 2 + Math.random() * 5,
                color: Math.random() < 0.25 ? "#f7f0f2" : (Math.random() < 0.5 ? "#ff4d60" : "#8a3cff")
            }
            if (i >= 0) arr[i] = s
            else if (arr.length < 24) arr.push(s)
        }
        shards = arr
    }

    function stepShards() {
        var arr = shards
        var changed = false
        for (var i = 0; i < arr.length; i++) {
            var s = arr[i]
            if (!s || s.life <= 0) continue
            s.x += s.vx
            s.y += s.vy
            s.vy += 0.03
            s.life -= 0.018
            changed = true
        }
        if (changed) { shards = arr; shardCanvas.requestPaint() }
    }

    // ── idle animation (12 fps, cel-style) ─────────────────────────
    Timer {
        interval: 83
        repeat: true
        running: true
        onTriggered: {
            win.frame = (win.frame + 1) % 24
            var bobs = [0,0,0,0,0,0,-2,-2,-2,-2,-4,-4,-4,-4,-4,-4,-2,-2,-2,-2,0,0,0,0]
            var tilts = [0,0,0,0,0,0,0.4,0.7,0.5,0.2,0,-0.4,-0.7,-0.5,-0.2,0,0.3,0.5,0.3,0,0,0,0,0]
            if (!win.peeking && !win.dragging) {
                win.bob = bobs[win.frame]
                if (!win.asleep) win.tilt = tilts[win.frame]
            }
            win.stepShards()
        }
    }

    // ── sleep / wake ───────────────────────────────────────────────
    function sleep() {
        if (asleep) return
        asleep = true
        showBubble("zZz…", "face-smug.png", 999999)
        body.opacity = 0.55
    }

    function wake() {
        if (!asleep) return
        asleep = false
        body.opacity = 1
        showBubble("i'm up.", "face-look.png", 2200)
        lastActivity = Date.now()
    }

    Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: {
            if (!win.asleep && Date.now() - win.lastActivity > 180000) win.sleep()
        }
    }

    Timer {
        id: bubbleTimer
        interval: 2800
        onTriggered: if (!win.asleep) win.bubbleVisible = false
    }

    Timer {
        interval: 26000
        repeat: true
        running: !win.asleep
        onTriggered: if (!win.hovered && !win.menuOpen && !win.peeking && Math.random() < 0.7) win.idleLine()
    }

    // ── body ────────────────────────────────────────────────────────
    Item {
        id: body
        x: 40
        y: win.baseY + win.bob
        width: 220
        height: 420
        transformOrigin: Item.Bottom
        rotation: win.tilt
        scale: win.asleep ? 0.9 : (win.hovered ? 1.02 : 1.0)
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        opacity: 1
        Behavior on opacity { NumberAnimation { duration: 220 } }

        // violet misregistration
        MultiEffect {
            x: 6; y: 5
            width: body.width; height: body.height
            source: sprite
            colorization: 1.0
            colorizationColor: win.violet
            opacity: 0.8
        }

        Image {
            id: sprite
            anchors.fill: parent
            source: win.assets + "capri-cutout.png"
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        // glitch ghosts
        MultiEffect {
            x: 9; y: 2
            width: body.width; height: body.height
            source: sprite
            colorization: 1.0
            colorizationColor: win.green
            opacity: 0.45
            visible: win.glitching
        }
        MultiEffect {
            x: -8; y: 3
            width: body.width; height: body.height
            source: sprite
            colorization: 1.0
            colorizationColor: win.red
            opacity: 0.35
            visible: win.glitching
        }
        Rectangle { visible: win.glitching; x: 0; y: 120; width: body.width; height: 3; color: win.green; opacity: 0.55 }
        Rectangle { visible: win.glitching; x: 0; y: 250; width: body.width; height: 2; color: win.red; opacity: 0.5 }

        MouseArea {
            id: bodyMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor

            onEntered: {
                win.hovered = true
                win.lastActivity = Date.now()
                win.wake()
                win.showBubble("hey.", "face-look.png", 2200)
            }
            onExited: win.hovered = false

            onPressed: function (mouse) {
                if (mouse.button !== Qt.LeftButton) return
                win.dragging = true
                win.moved = false
                win.dragStartX = win.x + body.x + mouse.x
                win.dragStartY = win.y + body.y + mouse.y
                win.dragWinX = win.x
                win.dragWinY = win.y
                win.lastActivity = Date.now()
            }

            onPositionChanged: function (mouse) {
                if (!win.dragging || !(mouse.buttons & Qt.LeftButton)) return
                var gx = win.x + body.x + mouse.x
                var gy = win.y + body.y + mouse.y
                var dx = gx - win.dragStartX
                var dy = gy - win.dragStartY
                if (Math.abs(dx) + Math.abs(dy) > 4) win.moved = true
                win.x = Math.round(win.dragWinX + dx)
                win.y = Math.round(win.dragWinY + dy)
            }

            onReleased: function (mouse) {
                if (mouse.button !== Qt.LeftButton) return
                win.dragging = false
                win.lastActivity = Date.now()
                if (!win.moved) {
                    win.glitchNow(false)
                    win.showBubble("on my way.", "face-smug.png", 1200)
                    exec.run("/home/marteam/.local/bin/capri-chat-open.sh")
                }
            }

            onClicked: function (mouse) {
                if (mouse.button === Qt.RightButton) {
                    win.menuOpen = !win.menuOpen
                    win.lastActivity = Date.now()
                }
            }
        }
    }

    // ── shards ──────────────────────────────────────────────────────
    Canvas {
        id: shardCanvas
        anchors.fill: parent
        z: 15
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            for (var i = 0; i < win.shards.length; i++) {
                var s = win.shards[i]
                if (!s || s.life <= 0) continue
                ctx.globalAlpha = Math.max(0, Math.min(1, s.life))
                ctx.fillStyle = s.color
                ctx.save()
                ctx.translate(s.x, s.y)
                ctx.rotate(s.life * 6)
                ctx.beginPath()
                ctx.moveTo(0, -s.size)
                ctx.lineTo(s.size * 0.8, s.size * 0.7)
                ctx.lineTo(-s.size * 0.8, s.size * 0.5)
                ctx.closePath()
                ctx.fill()
                ctx.restore()
            }
            ctx.globalAlpha = 1
        }
    }

    // ── speech plate ────────────────────────────────────────────────
    Item {
        id: bubble
        x: 16
        y: 4
        width: 268
        height: 66
        visible: win.bubbleVisible
        z: 30

        Rectangle {
            x: 4; y: 4
            width: parent.width; height: 58
            color: win.violet
        }
        Rectangle {
            width: parent.width; height: 58
            color: win.ink
            border.color: "#2e2138"
            border.width: 1
        }
        Image {
            x: 7; y: 7
            width: 42; height: 42
            source: win.assets + win.bubbleFace
            fillMode: Image.PreserveAspectCrop
        }
        Rectangle {
            x: 7; y: 7
            width: 42; height: 42
            color: "transparent"
            border.color: win.ink
            border.width: 1
        }
        Rectangle {
            x: 56; y: 12
            width: 5; height: 5; radius: 2.5
            color: win.asleep ? win.violet : win.green
        }
        Text {
            x: 66; y: 8
            width: parent.width - 78
            text: win.bubbleText
            color: win.asleep ? win.paper3 : win.paper
            font.family: "JetBrains Mono"
            font.pixelSize: 9
            wrapMode: Text.WordWrap
        }
        Text {
            x: 66; y: 36
            text: win.asleep ? "SLEEP MODE" : (win.peeking ? "PEEKING" : "PROJECT CAPRICORN")
            color: win.asleep ? win.violet : win.paper3
            font.family: "JetBrains Mono"
            font.pixelSize: 7
            font.letterSpacing: 1
        }
    }

    // ── right-click menu ────────────────────────────────────────────
    Column {
        id: menu
        x: 150
        y: 84
        width: 136
        spacing: 4
        visible: win.menuOpen
        z: 40

        Repeater {
            model: [
                { label: "SLEEP / WAKE", act: "sleep" },
                { label: "WANDER", act: "wander" },
                { label: "GLITCH", act: "glitch" },
                { label: "CLOSE", act: "close" }
            ]
            Rectangle {
                required property var modelData
                width: 136; height: 28
                color: mHover.containsMouse ? win.violet : win.ink
                border.color: mHover.containsMouse ? win.paper : "#3a2a44"
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: modelData.label
                    color: mHover.containsMouse ? win.ink : win.paper
                    font.family: "JetBrains Mono"
                    font.pixelSize: 8
                    font.letterSpacing: 1
                }
                MouseArea {
                    id: mHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        win.menuOpen = false
                        if (modelData.act === "sleep") { if (win.asleep) win.wake(); else win.sleep() }
                        else if (modelData.act === "wander") { win.roaming = !win.roaming; win.showBubble(win.roaming ? "wandering." : "staying put.", "face-calm.png", 2000) }
                        else if (modelData.act === "glitch") { win.glitchNow(true); win.showBubble(win.pickTaunt(), "face-smug.png", 1800) }
                        else if (modelData.act === "close") Qt.quit()
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        var arr = []
        for (var i = 0; i < 18; i++) arr.push({ x: 0, y: 0, vx: 0, vy: 0, life: 0, size: 3, color: "#ff4d60" })
        shards = arr
        goHome()
        showBubble("hey.", "face-smug.png", 3200)
    }
}
