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
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnBottomHint | Qt.Tool

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
    property string bridge: "http://127.0.0.1:8787"
    property real summonSince: Date.now() / 1000
    property real statusSince: Date.now() / 1000
    property bool popping: false
    property real popScale: 1.0
    property real popRot: 0
    property bool sitting: false
    property real warpSquash: 1.0
    property var lastActive: null

    Plasma5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: function (sourceName, data) { exec.disconnectSource(sourceName) }
        function run(cmd) { exec.connectSource(cmd) }
    }


    Plasma5Support.DataSource {
        id: kwin
        engine: "executable"
        connectedSources: []
        onNewData: function (sourceName, data) {
            kwin.disconnectSource(sourceName)
            var out = data ? (data["stdout"] || "") : ""
            if (out) win.parseWindow(String(out))
        }
        function run(cmd) { kwin.connectSource(cmd) }
    }

    Timer {
        interval: 350
        repeat: true
        running: true
        onTriggered: win.pollSummon()
    }

    Timer {
        interval: 900
        repeat: true
        running: true
        onTriggered: kwin.run("/home/marteam/.local/share/capricorn/capri-active-window.sh")
    }

    Timer {
        id: popupHide
        interval: 6500
        onTriggered: popup.visible = false
    }

    Timer {
        interval: 1100
        repeat: true
        running: true
        onTriggered: win.pollStatus()
    }


    Timer {
        id: popStay
        interval: 4400
        onTriggered: {
            var s = win.randomSpot()
            win.teleportTo(s.x, s.y, "over here.")
        }
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
        glitchNow(true, 260)
        spawnShards(7, body.x + body.width / 2, body.y + 150)
        warpSquash = 1.0
        warpLine.y = body.y
        warpLine.opacity = 0.9
        warpAnim.restart()
        warpFade.restart()
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
        if (!roaming || asleep || peeking || sitting || menuOpen || dragging || busyMoving) return
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

    // ── transmission popup ──────────────────────────────────────────
    function placePopup() {
        var b = win.bounds()
        var baseX = win.sitting ? perch.x + 150 : win.x
        var baseY = win.sitting ? perch.y + 140 : win.y
        var left = b.x0
        var right = b.x1 + win.width + 8 - popup.width
        var px = baseX - popup.width + 70
        if (px < left) px = baseX + win.width - 70
        px = Math.max(left, Math.min(px, right))
        var bottom = b.y1 + win.height + 8 - popup.height
        var py = Math.max(b.y0, Math.min(baseY - 10, bottom))
        popup.x = Math.round(px)
        popup.y = Math.round(py)
    }

    function showPopup(title, state, reply, actions, duration, accent) {
        popup.titleText = title
        popup.stateText = state
        popup.replyText = reply
        popup.actionCount = actions
        popup.elapsed = duration
        popup.accent = accent || win.green
        popup.visible = false
        placePopup()
        popup.visible = true
        popupHide.restart()
    }

    function pollStatus() {
        var x = new XMLHttpRequest()
        x.open("GET", win.bridge + "/status?since=" + win.statusSince)
        x.timeout = 900
        x.onreadystatechange = function () {
            if (x.readyState !== XMLHttpRequest.DONE) return
            if (x.status !== 200) return
            try {
                var d = JSON.parse(x.responseText)
                if (d.id > win.statusSince) {
                    win.statusSince = d.id
                    var ok = d.state === "done"
                    win.showPopup(ok ? "MISSION ACCOMPLIE, CHOOM." : "TRANSMISSION ERROR",
                                  ok ? "DONE" : "ERROR",
                                  d.reply || "", d.actions || 0, d.duration || 0,
                                  ok ? win.green : win.red)
                    if (ok) win.showBubble("done.", "face-smug.png", 1500)
                }
            } catch (e) {}
        }
        x.send()
    }

    // ── summon from the plasmoid ────────────────────────────────────
    function pollSummon() {
        var x = new XMLHttpRequest()
        x.open("GET", win.bridge + "/summon?since=" + win.summonSince)
        x.timeout = 600
        x.onreadystatechange = function () {
            if (x.readyState !== XMLHttpRequest.DONE) return
            if (x.status !== 200) return
            try {
                var d = JSON.parse(x.responseText)
                if (d.id > win.summonSince) {
                    win.summonSince = d.id
                    if (typeof d.x === "number" && typeof d.y === "number")
                        win.summonPop(d.x, d.y)
                }
            } catch (e) {}
        }
        x.send()
    }

    function summonPop(gx, gy) {
        driftAnim.stop()
        tpTimer.stop()
        peekTimer.stop()
        popStay.stop()
        win.peeking = false
        win.sitting = false
        perch.visible = false
        win.busyMoving = true
        win.warpSquash = 1.0
        win.wake()
        win.asleep = false
        body.opacity = 1
        win.x = Math.round(gx - 150)
        win.y = Math.round(gy - 300)
        win.popping = true
        win.popScale = 0.05
        win.popRot = -12
        win.bubbleVisible = false
        win.glitchNow(true, 520)
        win.spawnShards(16, 150, 300)
        warpLine.y = body.y
        warpLine.opacity = 0.9
        warpFade.restart()
        win.lastActivity = Date.now()
        win.showPopup("WHAT SHOULD WE DO?", "LINKED", "Tune in. Tell me what to break.", 0, 0, win.violet)
        popAnim.restart()
        popStay.restart()
    }

    // ── sitting on the active application window ────────────────────
    function parseWindow(text) {
        if (!text) return
        var raw = String(text)
        var at = raw.indexOf("CAPRIWIN|")
        if (at < 0) return
        var f = raw.slice(at).trim().split("|")
        if (f.length < 7) return
        var x = parseFloat(f[1]), y = parseFloat(f[2])
        var w = parseFloat(f[3]), h = parseFloat(f[4])
        var cls = f[5] || ""
        var cap = f.slice(6).join("|")
        if (!isFinite(x) || !isFinite(y) || !isFinite(w) || !isFinite(h)) return
        if (cap.indexOf("CAPRI //") === 0 || cap.indexOf("Capri //") === 0 || cls === "plasmashell") return
        var good = (y >= 160 && w >= 360 && h >= 240)
        win.lastActive = { x: x, y: y, w: w, h: h, good: good }
        if (good) win.sitOn(x, y, w, h)
        else if (win.sitting) win.standUp()
    }

    function sitOn(x, y, w, h) {
        if (win.dragging || win.popping) return
        var tx = Math.round(x + w / 2 - 150)
        var ty = Math.round(y - 427)
        if (win.sitting && Math.abs(win.x - tx) < 2 && Math.abs(win.y - ty) < 2) return
        driftAnim.stop(); tpTimer.stop(); popStay.stop(); peekTimer.stop()
        win.peeking = false
        win.busyMoving = false
        win.asleep = false
        body.opacity = 1
        win.popScale = 1.0
        win.popping = false
        win.sitting = true
        perch.x = Math.round(x + w / 2 - 150)
        perch.y = Math.round(y - 270)
        perch.visible = true
        win.x = -2000
        win.y = -2000
        win.tilt = 0
        win.bubbleVisible = false
        win.lastActivity = Date.now()
    }

    function tryPerch() {
        if (!win.lastActive || !win.lastActive.good) {
            win.showBubble("need a window.", "face-aside.png", 1700)
            return
        }
        win.sitOn(win.lastActive.x, win.lastActive.y, win.lastActive.w, win.lastActive.h)
    }

    function standUp() {
        if (!win.sitting) return
        win.sitting = false
        perch.visible = false
        win.glitchNow(true, 220)
        var s = win.randomSpot()
        win.teleportTo(s.x, s.y, "over here.")
    }

    // ── glitch / shards ─────────────────────────────────────────────
    function glitchNow(big, hold) {
        glitching = true
        glitchOff.interval = hold || 120
        glitchOff.restart()
        if (big) spawnShards(4, body.x + 80 + Math.random() * 120, body.y + 80 + Math.random() * 160)
    }

    Timer {
        id: glitchOff
        interval: 120
        onTriggered: win.glitching = false
    }

    SequentialAnimation {
        id: popAnim
        ParallelAnimation {
            NumberAnimation { target: win; property: "popScale"; to: 1.12; duration: 360; easing.type: Easing.OutBack }
            NumberAnimation { target: win; property: "popRot"; to: 3; duration: 360 }
        }
        ParallelAnimation {
            NumberAnimation { target: win; property: "popScale"; to: 1.0; duration: 120 }
            NumberAnimation { target: win; property: "popRot"; to: 0; duration: 120 }
        }
        onFinished: {
            win.popping = false
            win.popScale = 1.0
            win.popRot = 0
            win.spawnShards(8, 150, 300)
            win.showBubble("hey!", "face-smug.png", 1600)
            win.busyMoving = false
            win.lastActivity = Date.now()
        }
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
        sleepMask.visible = true
        sleepMask.opacity = 1
        body.opacity = 0.08
        showBubble("zZz…", "face-smug.png", 999999)
    }

    function wake() {
        if (!asleep) return
        asleep = false
        sleepMask.opacity = 0
        sleepMask.visible = false
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

    Rectangle {
        id: warpLine
        x: 149; y: 90; width: 3; height: 420
        color: win.red
        opacity: 0
        visible: opacity > 0
        z: 16
    }

    SequentialAnimation {
        id: warpAnim
        NumberAnimation { target: win; property: "warpSquash"; to: 0.02; duration: 80; easing.type: Easing.InCubic }
        NumberAnimation { target: win; property: "warpSquash"; to: 1.0; duration: 180; easing.type: Easing.OutBack }
    }
    NumberAnimation {
        id: warpFade
        target: warpLine
        property: "opacity"
        to: 0
        duration: 260
    }

    Image {
        id: sleepMask
        x: 88; y: 220; width: 124; height: 104
        source: win.assets + "mask.png"
        fillMode: Image.PreserveAspectFit
        visible: false
        opacity: 0
        z: 6
        Behavior on opacity { NumberAnimation { duration: 280 } }
        SequentialAnimation on y {
            running: win.asleep
            loops: Animation.Infinite
            NumberAnimation { to: 212; duration: 1700; easing.type: Easing.InOutSine }
            NumberAnimation { to: 222; duration: 1700; easing.type: Easing.InOutSine }
        }
    }

    // ── body ────────────────────────────────────────────────────────
    Item {
        id: body
        x: 40
        y: win.baseY + win.bob
        width: 220
        height: 420
        transformOrigin: win.popping ? Item.Center : Item.Bottom
        transform: Scale { origin.x: body.width / 2; origin.y: body.height / 2; xScale: win.warpSquash }
        rotation: win.tilt + (win.popping ? win.popRot : 0)
        scale: (win.asleep ? 0.9 : (win.hovered ? 1.02 : 1.0)) * (win.popping ? win.popScale : 1.0) * (win.sitting ? 0.55 : 1.0)
        Behavior on scale { enabled: !win.popping; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
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
                { label: "PERCH", act: "perch" },
                { label: "INTRO", act: "intro" },
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
                        else if (modelData.act === "perch") { win.tryPerch() }
                        else if (modelData.act === "intro") { exec.run("/home/marteam/.local/bin/capri-intro-open.sh") }
                        else if (modelData.act === "wander") { win.roaming = !win.roaming; win.showBubble(win.roaming ? "wandering." : "staying put.", "face-calm.png", 2000) }
                        else if (modelData.act === "glitch") { win.glitchNow(true); win.showBubble(win.pickTaunt(), "face-smug.png", 1800) }
                        else if (modelData.act === "close") Qt.quit()
                    }
                }
            }
        }
    }

    Window {
        id: perch
        width: 300
        height: 300
        visible: false
        color: "transparent"
        title: "CAPRI // PERCH"
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnBottomHint | Qt.Tool

        Item {
            x: 40; y: 0; width: 220; height: 270
            clip: true
            MultiEffect {
                x: 5; y: 4
                width: 220; height: 420
                source: perchImg
                colorization: 1.0
                colorizationColor: win.violet
                opacity: 0.8
            }
            Image {
                id: perchImg
                width: 220; height: 420
                source: win.assets + "capri-cutout.png"
                fillMode: Image.PreserveAspectFit
            }
        }

        Rectangle {
            x: 8; y: 4; width: 96; height: 18
            color: win.ink
            Text {
                anchors.centerIn: parent
                text: "comfy."
                color: win.green
                font.family: "JetBrains Mono"
                font.pixelSize: 8
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: function (mouse) {
                if (mouse.button === Qt.RightButton) win.standUp()
                else exec.run("/home/marteam/.local/bin/capri-chat-open.sh")
            }
        }
    }

    Window {
        id: popup
        width: 380
        height: 232
        visible: false
        color: "transparent"
        title: "CAPRI // TRANSMISSION"
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnBottomHint | Qt.Tool

        property string titleText: "MISSION ACCOMPLIE, CHOOM."
        property string stateText: "DONE"
        property string replyText: ""
        property int actionCount: 0
        property real elapsed: 0
        property color accent: win.green
        property string faceFile: "face-smug.png"

        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                function plate(dx, dy, fill) {
                    ctx.beginPath()
                    ctx.moveTo(8 + dx, 20 + dy)
                    ctx.lineTo(20 + dx, 8 + dy)
                    ctx.lineTo(230 + dx, 8 + dy)
                    ctx.lineTo(233 + dx, 14 + dy)
                    ctx.lineTo(236 + dx, 8 + dy)
                    ctx.lineTo(348 + dx, 8 + dy)
                    ctx.lineTo(372 + dx, 32 + dy)
                    ctx.lineTo(372 + dx, 224 + dy)
                    ctx.lineTo(30 + dx, 224 + dy)
                    ctx.lineTo(8 + dx, 202 + dy)
                    ctx.closePath()
                    ctx.fillStyle = fill
                    ctx.fill()
                }
                plate(5, 5, win.violet)
                plate(0, 0, win.ink)
            }
        }

        Rectangle { x: 22; y: 21; width: 54; height: 54; color: win.violet }
        Image {
            id: popupFace
            x: 18; y: 17; width: 54; height: 54
            source: win.assets + popup.faceFile
            fillMode: Image.PreserveAspectCrop
        }
        Rectangle { x: 18; y: 17; width: 54; height: 54; color: "transparent"; border.color: win.ink; border.width: 1 }

        Text {
            x: 84; y: 14
            text: "CAPRI"
            color: win.paper
            font.family: "Chakra Petch"
            font.pixelSize: 16
            font.letterSpacing: 2
        }
        Text {
            x: 145; y: 18
            text: "/ NIGHT-CITY--"
            color: win.paper3
            font.family: "JetBrains Mono"
            font.pixelSize: 7
            font.letterSpacing: 1
        }
        Rectangle {
            x: 296; y: 14; width: 64; height: 17
            color: popup.accent
            Text {
                anchors.centerIn: parent
                text: popup.stateText
                color: win.ink
                font.family: "JetBrains Mono"
                font.pixelSize: 7
                font.bold: true
                font.letterSpacing: 1
            }
        }

        Text {
            x: 84; y: 40
            width: 276; height: 34
            text: popup.titleText
            color: win.paper
            font.family: "Chakra Petch"
            font.pixelSize: 13
            wrapMode: Text.WordWrap
        }
        Text {
            x: 84; y: 78
            width: 276; height: 96
            text: popup.replyText
            color: win.paper2
            font.family: "JetBrains Mono"
            font.pixelSize: 8
            lineHeight: 1.4
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            maximumLineCount: 6
            clip: true
        }
        Text {
            x: 84; y: 194
            text: "◆ " + popup.actionCount + " actions · " + popup.elapsed + " s"
            color: popup.accent
            font.family: "JetBrains Mono"
            font.pixelSize: 8
            font.letterSpacing: 1
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: popup.visible = false
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
