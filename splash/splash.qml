import QtQuick
import QtQuick.Window

Window {
    id: root

    property int screenIndex: {
        var a = Qt.application.arguments
        var n = a.length > 1 ? parseInt(a[a.length - 1]) : 0
        return isNaN(n) ? 0 : n
    }
    property var targetScreen: Qt.application.screens[Math.min(screenIndex, Qt.application.screens.length - 1)]

    visible: true
    visibility: Window.FullScreen
    color: "#050308"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    title: "capricorn-boot-" + screenIndex

    property real progress: 0
    property string hexA: "0x0000"
    property string hexB: "0x0000"
    property string hexC: "0x0000"

    function statusFor(p) {
        if (p < 0.14) return "MOUNTING CHROME"
        if (p < 0.30) return "LINKING OPTICS"
        if (p < 0.46) return "DECRYPTING ICE"
        if (p < 0.62) return "SPOOFING RELAY"
        if (p < 0.78) return "TRACING BLACKWALL"
        if (p < 0.94) return "LOADING CAPRICORN"
        return "SYSTEM ONLINE"
    }

    FontLoader {
        id: chakra
        source: "file:///home/marteam/.local/share/fonts/cyberpunk/ChakraPetch-Bold.ttf"
    }
    FontLoader {
        id: raj
        source: "file:///home/marteam/.local/share/fonts/cyberpunk/Rajdhani-SemiBold.ttf"
    }

    Item {
        id: scene
        anchors.fill: parent
        focus: true
        Keys.onPressed: function (event) { Qt.quit() }

        // ── backdrop ─────────────────────────────────────────────────
        Rectangle {
            anchors.fill: parent
            color: "#050308"
        }

        Image {
            id: bg
            anchors.fill: parent
            source: "file:///home/marteam/.local/share/wallpapers/capricorn-lock-left.png"
            fillMode: Image.PreserveAspectCrop
            opacity: 0.55
            scale: 1.06
            NumberAnimation on scale {
                from: 1.06
                to: 1.16
                duration: 7000
                easing.type: Easing.OutQuad
            }
        }
        Rectangle {
            anchors.fill: parent
            color: "#050308"
            opacity: 0.45
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#f2050308" }
                GradientStop { position: 0.45; color: "#66050308" }
                GradientStop { position: 1.0; color: "#f2050308" }
            }
        }

        // ── rotating hud ring ────────────────────────────────────────
        Canvas {
            id: ring
            width: 760
            height: 760
            anchors.centerIn: scene
            anchors.verticalCenterOffset: -20
            opacity: 0.30
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                ctx.strokeStyle = "#ff0a54"
                ctx.lineWidth = 2
                ctx.beginPath()
                ctx.arc(380, 380, 330, 0, Math.PI * 2)
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(380, 380, 300, 0, Math.PI * 2)
                ctx.stroke()
                for (var i = 0; i < 72; i++) {
                    var a = i * Math.PI / 36
                    var r1 = 330
                    var r2 = (i % 6 === 0) ? 352 : 342
                    ctx.beginPath()
                    ctx.moveTo(380 + Math.cos(a) * r1, 380 + Math.sin(a) * r1)
                    ctx.lineTo(380 + Math.cos(a) * r2, 380 + Math.sin(a) * r2)
                    ctx.stroke()
                }
                ctx.strokeStyle = "#0dff6e"
                ctx.lineWidth = 4
                ctx.beginPath()
                ctx.arc(380, 380, 300, -0.6, 0.4)
                ctx.stroke()
                ctx.strokeStyle = "#b14cff"
                ctx.beginPath()
                ctx.arc(380, 380, 330, 1.8, 2.6)
                ctx.stroke()
            }
            RotationAnimator on rotation {
                from: 0
                to: 360
                duration: 26000
                loops: Animation.Infinite
            }
        }

        // ── top-left identity ───────────────────────────────────────
        Text {
            anchors.left: scene.left
            anchors.top: scene.top
            anchors.margins: 52
            text: "NIGHT CITY  //  NET_54.7"
            color: "#0dff6e"
            font.family: raj.name
            font.pixelSize: 17
            font.letterSpacing: 3
            opacity: 0.85
        }

        // ── boot log ────────────────────────────────────────────────
        Column {
            id: logCol
            anchors.left: scene.left
            anchors.top: scene.top
            anchors.leftMargin: 52 + (scene.tear ? ((scene.barTick % 7) - 3) : 0)
            anchors.topMargin: 108
            spacing: 9

            Repeater {
                model: [
                    { t: "MOUNTING CHROME ......... OK", ok: true, d: 250 },
                    { t: "LINKING OPTICS .......... OK", ok: true, d: 520 },
                    { t: "DECRYPTING ICE .......... OK", ok: true, d: 790 },
                    { t: "SPOOFING RELAY .......... OK", ok: true, d: 1060 },
                    { t: "TRACING BLACKWALL ....... OK", ok: true, d: 1330 },
                    { t: "LOADING CAPRICORN.EXE ... OK", ok: true, d: 1600 }
                ]
                Item {
                    id: lineItem
                    required property var modelData
                    required property int index
                    width: txt.implicitWidth
                    height: txt.implicitHeight

                    Text {
                        id: txt
                        text: "> " + modelData.t
                        color: modelData.ok ? (index === 5 ? "#0dff6e" : "#8a7480") : "#ff0a54"
                        font.family: raj.name
                        font.pixelSize: 15
                        font.letterSpacing: 1.6
                    }
                    opacity: 0
                    x: -18
                    SequentialAnimation {
                        running: true
                        PauseAnimation { duration: modelData.d }
                        ParallelAnimation {
                            NumberAnimation { target: lineItem; property: "opacity"; to: 1; duration: 220 }
                            NumberAnimation { target: lineItem; property: "x"; to: 0; duration: 220 }
                        }
                    }
                }
            }

            Row {
                spacing: 6
                Rectangle {
                    width: 8
                    height: 16
                    color: "#ff0a54"
                    opacity: 0
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.9; duration: 420 }
                        NumberAnimation { to: 0; duration: 420 }
                    }
                }
                Text {
                    text: "ROOT@BLACKWALL:~#"
                    color: "#5c4a54"
                    font.family: raj.name
                    font.pixelSize: 14
                    font.letterSpacing: 1.5
                }
            }
        }

        // ── hex feed ────────────────────────────────────────────────
        Column {
            anchors.right: scene.right
            anchors.top: scene.top
            anchors.margins: 52
            spacing: 4
            Text {
                text: root.hexA + "\n" + root.hexB + "\n" + root.hexC
                color: "#b14cff"
                opacity: 0.6
                font.family: raj.name
                font.pixelSize: 14
                font.letterSpacing: 2
                horizontalAlignment: Text.AlignRight
            }
            Text {
                text: "ICE // ACTIVE"
                color: "#0dff6e"
                opacity: 0.55
                font.family: raj.name
                font.pixelSize: 12
                font.letterSpacing: 3
                horizontalAlignment: Text.AlignRight
            }
        }

        Timer {
            interval: 85
            running: true
            repeat: true
            onTriggered: {
                function rnd() {
                    var v = Math.floor(Math.random() * 65535).toString(16).toUpperCase()
                    return "0x" + ("0000" + v).slice(-4)
                }
                root.hexA = rnd()
                root.hexB = rnd()
                root.hexC = rnd()
            }
        }

        // ── title ───────────────────────────────────────────────────
        Item {
            id: titleBlock
            anchors.horizontalCenter: scene.horizontalCenter
            anchors.verticalCenter: scene.verticalCenter
            anchors.verticalCenterOffset: -30
            width: title.implicitWidth
            height: title.implicitHeight

            Text {
                text: "CAPRICORN"
                font.family: chakra.name
                font.pixelSize: 176
                font.letterSpacing: 16
                color: "#ff0a54"
                opacity: 0.9
                x: glitch.dx
                y: 4
            }
            Text {
                text: "CAPRICORN"
                font.family: chakra.name
                font.pixelSize: 176
                font.letterSpacing: 16
                color: "#b14cff"
                opacity: 0.75
                x: -glitch.dx
                y: -2
            }
            Text {
                id: title
                text: "CAPRICORN"
                font.family: chakra.name
                font.pixelSize: 176
                font.letterSpacing: 16
                color: "#f7efF4"
            }
            SequentialAnimation on opacity {
                running: true
                NumberAnimation { from: 0; to: 1; duration: 280 }
            }
        }

        QtObject {
            id: glitch
            property real dx: 0
            Behavior on dx { NumberAnimation { duration: 60 } }
        }
        Timer {
            interval: 85
            running: true
            repeat: true
            onTriggered: {
                var spike = Math.random() < (scene.tear ? 0.85 : 0.3)
                var amp = scene.tear ? 34 : 13
                glitch.dx = spike ? Math.random() * amp * 2 - amp : 0
            }
        }

        Text {
            anchors.top: titleBlock.bottom
            anchors.topMargin: 10
            anchors.horizontalCenter: scene.horizontalCenter
            text: "BLACKWALL  //  BREACH"
            color: "#0dff6e"
            font.family: raj.name
            font.pixelSize: 22
            font.letterSpacing: 10
            opacity: 0
            SequentialAnimation on opacity {
                running: true
                PauseAnimation { duration: 380 }
                NumberAnimation { to: 0.95; duration: 420 }
            }
        }

        // ── progress ────────────────────────────────────────────────
        Item {
            id: barArea
            width: scene.width * 0.46
            height: 12
            anchors.horizontalCenter: scene.horizontalCenter
            anchors.bottom: scene.bottom
            anchors.bottomMargin: scene.height * 0.15

            Row {
                id: segs
                anchors.fill: parent
                spacing: 4
                Repeater {
                    model: 48
                    Rectangle {
                        required property int index
                        width: (barArea.width - 47 * 4) / 48
                        height: barArea.height
                        color: (index / 48) < root.progress
                               ? ((index % 6 === 0) ? "#0dff6e" : "#ff0a54")
                               : "#1c0d14"
                        Behavior on color { ColorAnimation { duration: 90 } }
                    }
                }
            }

            Text {
                anchors.left: parent.left
                anchors.bottom: parent.top
                anchors.bottomMargin: 10
                text: {
                    var n = Math.round(root.progress * 100)
                    return (n < 10 ? "00" : (n < 100 ? "0" : "")) + n + "%"
                }
                color: "#0dff6e"
                font.family: raj.name
                font.pixelSize: 17
                font.letterSpacing: 3
            }
            Text {
                anchors.right: parent.right
                anchors.bottom: parent.top
                anchors.bottomMargin: 10
                text: root.statusFor(root.progress)
                color: "#f7eff4"
                font.family: raj.name
                font.pixelSize: 17
                font.letterSpacing: 4
                opacity: 0.9
            }
        }

        // ── scanlines ───────────────────────────────────────────────
        Rectangle {
            width: parent.width
            height: 2
            color: "#ffffff"
            opacity: 0.05
            y: -10
            NumberAnimation on y {
                from: -10
                to: scene.height
                duration: 1900
                loops: Animation.Infinite
            }
        }

        // ── glitch bursts ───────────────────────────────────────────
        property int barTick: 0
        property bool tear: false

        Timer {
            interval: 620
            running: true
            repeat: true
            onTriggered: {
                scene.barTick++
                if (Math.random() < 0.55) {
                    scene.tear = true
                    tearEnd.restart()
                }
            }
        }

        Timer {
            id: tearEnd
            interval: 120
            repeat: false
            onTriggered: scene.tear = false
        }

        Repeater {
            model: 7
            Rectangle {
                required property int index
                width: 160 + ((index * 137) % 700)
                height: 2 + ((index * 7) % 9)
                x: ((index * 233 + scene.barTick * 41) % Math.max(1, scene.width - width))
                y: ((index * 191 + scene.barTick * 67) % Math.max(1, scene.height))
                color: index % 3 === 0 ? "#0dff6e" : (index % 3 === 1 ? "#ff0a54" : "#b14cff")
                opacity: scene.tear ? 0.5 : 0
                visible: opacity > 0
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#ff0a54"
            opacity: scene.tear ? 0.05 : 0
        }

        // ── finale ──────────────────────────────────────────────────
        Item {
            id: granted
            anchors.centerIn: scene
            opacity: 0
            width: g1.implicitWidth
            height: g1.implicitHeight
            Text {
                id: g1
                text: "ACCESS GRANTED"
                font.family: chakra.name
                font.pixelSize: 54
                font.letterSpacing: 14
                color: "#ff0a54"
            }
        }

        Rectangle {
            id: flash
            anchors.fill: parent
            color: "#ffd9e4"
            opacity: 0
        }

        SequentialAnimation {
            running: true
            PauseAnimation { duration: 4750 }
            ParallelAnimation {
                NumberAnimation { target: titleBlock; property: "opacity"; to: 0; duration: 240 }
                NumberAnimation { target: granted; property: "opacity"; to: 1; duration: 260 }
                NumberAnimation { target: flash; property: "opacity"; to: 0.16; duration: 120 }
            }
            NumberAnimation { target: granted; property: "scale"; from: 0.92; to: 1.0; duration: 320 }
            NumberAnimation { target: flash; property: "opacity"; to: 0; duration: 300 }
            PauseAnimation { duration: 520 }
            NumberAnimation { target: scene; property: "opacity"; to: 0; duration: 420 }
            ScriptAction { script: Qt.quit() }
        }
    }

    NumberAnimation on progress {
        from: 0
        to: 1
        duration: 4300
        easing.type: Easing.InOutQuad
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Qt.quit()
    }
}
