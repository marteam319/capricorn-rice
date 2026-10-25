import QtQuick
import org.kde.plasma.plasmoid

WallpaperItem {
    id: root

    readonly property var frames: [
        Qt.resolvedUrl("frames/frame0.png"),
        Qt.resolvedUrl("frames/frame1.png"),
        Qt.resolvedUrl("frames/frame2.png"),
        Qt.resolvedUrl("frames/frame3.png")
    ]

    property int current: 0

    Repeater {
        model: root.frames.length
        Image {
            required property int index
            anchors.fill: parent
            source: root.frames[index]
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            opacity: root.current === index ? 1 : 0
        }
    }

    // breathing magenta light
    Rectangle {
        anchors.fill: parent
        color: "#ff0a54"
        opacity: 0.02
        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { to: 0.075; duration: 1100; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.02; duration: 1900; easing.type: Easing.InOutSine }
        }
    }

    // ── glitch clock, top-left ────────────────────────────────────────
    FontLoader {
        id: chakra
        source: "file:///home/marteam/.local/share/fonts/cyberpunk/ChakraPetch-Bold.ttf"
    }
    FontLoader {
        id: rajdhani
        source: "file:///home/marteam/.local/share/fonts/cyberpunk/Rajdhani-SemiBold.ttf"
    }

    property string clockText: Qt.formatTime(new Date(), "HH:mm")
    property string secText: Qt.formatTime(new Date(), "ss")
    property string dayText: ["SUNDAY","MONDAY","TUESDAY","WEDNESDAY","THURSDAY","FRIDAY","SATURDAY"][new Date().getDay()]
    property real glitchX: 0

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root.clockText = Qt.formatTime(new Date(), "HH:mm")
            root.secText = Qt.formatTime(new Date(), "ss")
            root.dayText = ["SUNDAY","MONDAY","TUESDAY","WEDNESDAY","THURSDAY","FRIDAY","SATURDAY"][new Date().getDay()]
        }
    }

    Timer {
        interval: 120
        running: true
        repeat: true
        onTriggered: root.glitchX = Math.random() < 0.22 ? Math.random() * 9 - 4.5 : 0
    }

    Item {
        id: clockBlock
        x: 44
        y: 44
        width: timeGroup.width
        height: timeGroup.height + 44

        Item {
            id: timeGroup
            width: mainTime.implicitWidth
            height: mainTime.height
            rotation: -2.5
            transformOrigin: Item.TopLeft

            Text {
                text: root.clockText
                x: root.glitchX
                y: 6
                font.family: chakra.name
                font.pixelSize: 86
                font.letterSpacing: 5
                color: "#b14cff"
                opacity: 0.85
            }
            Text {
                text: root.clockText
                x: -root.glitchX
                y: -3
                font.family: chakra.name
                font.pixelSize: 86
                font.letterSpacing: 5
                color: "#ff0a54"
                opacity: 0.8
            }
            Text {
                id: mainTime
                text: root.clockText
                font.family: chakra.name
                font.pixelSize: 86
                font.letterSpacing: 5
                color: "#ffe3ec"
            }
            Rectangle {
                y: mainTime.height + 6
                width: mainTime.width
                height: 2
                color: "#ff0a54"
                opacity: 0.85
            }
        }

        Text {
            anchors.top: timeGroup.bottom
            anchors.topMargin: 14
            anchors.left: parent.left
            text: root.dayText + "   //   " + root.secText
            font.family: rajdhani.name
            font.pixelSize: 20
            font.letterSpacing: 4
            color: "#b14cff"
        }
    }

    // ── blackwall intrusion + night tint ─────────────────────────────
    property bool breach: false
    property real nightTint: {
        var h = new Date().getHours()
        return (h >= 22 || h < 6) ? 0.16 : (h >= 19 ? 0.07 : 0.0)
    }

    Rectangle {
        anchors.fill: parent
        color: "#141a5a"
        opacity: root.nightTint
    }

    Timer {
        interval: 45000
        running: true
        repeat: true
        onTriggered: {
            if (Math.random() < 0.4) {
                root.breach = true
                breachEnd.restart()
            }
        }
    }

    Timer {
        id: breachEnd
        interval: 1500
        repeat: false
        onTriggered: {
            root.breach = false
            root.current = 0
        }
    }

    Timer {
        interval: 70
        running: root.breach
        repeat: true
        onTriggered: root.current = 1 + Math.floor(Math.random() * 3)
    }

    Rectangle {
        anchors.fill: parent
        color: "#ff0a54"
        opacity: root.breach ? 0.10 : 0.0
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: "#ff0a54"
        border.width: root.breach ? 6 : 0
    }

    Column {
        visible: root.breach
        anchors.centerIn: parent
        spacing: 8
        Text {
            text: "!! BLACKWALL TRACE !!"
            color: "#ff0a54"
            font.family: chakra.name
            font.pixelSize: 32
            font.letterSpacing: 8
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Text {
            text: "ICE COUNTERMEASURE // " + root.secText
            color: "#0dff6e"
            font.family: rajdhani.name
            font.pixelSize: 16
            font.letterSpacing: 4
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // ── living wallpaper layers ──────────────────────────────────────
    function glyphColumn(i) {
        var chars = "0123456789ABCDEF/\\|<>[]{}#$%&*+=アイウエオカキクケコ"
        var out = ""
        for (var k = 0; k < 34; k++) {
            out += chars.charAt(Math.floor(Math.random() * chars.length)) + "\n"
        }
        return out
    }

    // breathing optic glow
    Item {
        id: opticGlow
        x: root.width * 0.845 - width / 2
        y: root.height * 0.285 - height / 2
        width: 640
        height: 640

        Repeater {
            model: 12
            Rectangle {
                required property int index
                width: 150 + index * 40
                height: width
                radius: width / 2
                color: "#ff2038"
                opacity: 0.012
                anchors.centerIn: parent
            }
        }
        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { to: 1.0; duration: 2200; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.35; duration: 3200; easing.type: Easing.InOutSine }
        }
    }

    // falling glyph columns
    Repeater {
        model: 28
        Text {
            required property int index
            x: (index * 397) % Math.max(1, root.width)
            text: root.glyphColumn(index)
            color: index % 3 === 0 ? "#0dff6e" : (index % 3 === 1 ? "#ff2038" : "#b14cff")
            opacity: 0.09
            font.family: "DejaVu Sans Mono"
            font.pixelSize: 14
            NumberAnimation on y {
                from: -700
                to: root.height + 700
                duration: 9000 + (index % 7) * 1500
                loops: Animation.Infinite
            }
        }
    }

    // rising embers
    Repeater {
        model: 60
        Rectangle {
            required property int index
            width: 2 + (index % 3)
            height: width
            radius: width / 2
            color: index % 4 === 0 ? "#0dff6e" : "#ff2038"
            x: (index * 733) % Math.max(1, root.width)
            y: root.height + 20
            opacity: 0.3
            NumberAnimation on y {
                from: root.height + 20
                to: -20
                duration: 7000 + (index % 9) * 900
                loops: Animation.Infinite
            }
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0.05; duration: 800 + (index % 5) * 200 }
                NumberAnimation { to: 0.45; duration: 900 + (index % 7) * 160 }
            }
        }
    }

    // scanline sweep
    Rectangle {
        width: parent.width
        height: 2
        color: "#ffffff"
        opacity: 0.06
        y: -10
        NumberAnimation on y {
            from: -10
            to: root.height
            duration: 2800
            loops: Animation.Infinite
        }
    }

    Rectangle {
        width: parent.width
        height: 1
        color: "#0dff6e"
        opacity: 0.06
        y: -30
        NumberAnimation on y {
            from: -30
            to: root.height
            duration: 6100
            loops: Animation.Infinite
        }
    }

    // occaisional hard glitch cut back to a torn frame
    Timer {
        interval: 240
        running: true
        repeat: true
        onTriggered: {
            if (Math.random() < 0.34) {
                root.current = 1 + Math.floor(Math.random() * 3)
                hold.restart()
            }
        }
    }

    Timer {
        id: hold
        interval: 130
        repeat: false
        onTriggered: root.current = 0
    }
}
