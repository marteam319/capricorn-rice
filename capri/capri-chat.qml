import QtQuick
import QtQuick.Window
import org.kde.plasma.plasma5support as Plasma5Support

Window {
    id: root

    width: 380
    height: 460
    visible: true
    color: "#050308"
    title: "CAPRI"
    flags: Qt.FramelessWindowHint | Qt.Tool

    readonly property color cBright: "#f2f4c0"
    readonly property color cRed: "#ff2038"
    readonly property color cGreen: "#0dff6e"
    readonly property color cViolet: "#b14cff"
    readonly property color cDim: "#8f5a66"
    readonly property color cBody: "#d9c4cb"

    property string fullMessage: ""
    property string shownMessage: ""
    property bool typing: false
    property int charPos: 0
    property var options: []
    property var nextOptions: []

    Plasma5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: function (sourceName, data) { exec.disconnectSource(sourceName) }
        function run(cmd) { exec.connectSource(cmd) }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: Qt.quit()
    }

    function say(text, opts) {
        fullMessage = text
        shownMessage = ""
        charPos = 0
        nextOptions = opts
        options = []
        typing = true
        typeTimer.restart()
    }

    function backOpts() {
        return [
            { id: "back", label: "BACK" },
            { id: "close", label: "CLOSE" }
        ]
    }

    function mainMenu() {
        say("What should I show you?\nPick one, I'll take you there.", [
            { id: "breach", label: "BREACH PROTOCOL" },
            { id: "wallpapers", label: "WALLPAPERS" },
            { id: "project", label: "PROJECT FOLDER" },
            { id: "opencode", label: "OPENCODE FOLDER" },
            { id: "nothing", label: "NOTHING, THANKS" }
        ])
    }

    function act(id) {
        if (id === "breach") {
            exec.run("/home/marteam/.local/bin/capricorn-breach-open.sh")
            say("Breach panel is up.\nTry not to get traced, netrunner.", [])
            closeTimer.restart()
        } else if (id === "wallpapers") {
            exec.run("xdg-open /home/marteam/.local/share/wallpapers")
            say("Wallpapers live in\n~/.local/share/wallpapers.\nI opened the folder.", backOpts())
        } else if (id === "project") {
            exec.run("xdg-open /home/marteam/Projekty/cyberpunk-capricorn")
            say("Opening the Capricorn project.\nDon't break my rice.", backOpts())
        } else if (id === "opencode") {
            exec.run("xdg-open /home/marteam/.config/opencode")
            say("Opening OpenCode's config folder.\nGo build something.", backOpts())
        } else if (id === "back") {
            mainMenu()
        } else if (id === "nothing") {
            say("Fine. I'll be on the wallpaper.", [
                { id: "close", label: "CLOSE" }
            ])
        } else if (id === "close") {
            Qt.quit()
        }
    }

    Timer {
        id: typeTimer
        interval: 18
        repeat: true
        running: false
        onTriggered: {
            root.charPos++
            root.shownMessage = root.fullMessage.slice(0, root.charPos)
            if (root.charPos >= root.fullMessage.length) {
                typeTimer.stop()
                root.typing = false
                root.options = root.nextOptions
            }
        }
    }

    Timer {
        id: closeTimer
        interval: 1700
        onTriggered: Qt.quit()
    }

    Component.onCompleted: mainMenu()

    // ── frame ────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        border.color: root.cRed
        border.width: 1
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0c0710" }
            GradientStop { position: 0.55; color: "#08050a" }
            GradientStop { position: 1.0; color: "#10060c" }
        }
    }

    Canvas {
        anchors.fill: parent
        opacity: 0.45
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.strokeStyle = "rgba(255,32,56,0.07)"
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

    Rectangle { x: 6; y: 6; width: 22; height: 2; color: root.cGreen }
    Rectangle { x: 6; y: 6; width: 2; height: 22; color: root.cGreen }
    Rectangle { x: parent.width - 28; y: parent.height - 8; width: 22; height: 2; color: root.cRed }
    Rectangle { x: parent.width - 8; y: parent.height - 28; width: 2; height: 22; color: root.cRed }

    // ── header ───────────────────────────────────────────────────────
    Rectangle {
        id: header
        width: parent.width
        height: 48
        color: "#0b0710"

        Rectangle { x: 0; y: parent.height - 1; width: parent.width; height: 1; color: "#3a1622" }

        Image {
            x: 14
            y: 9
            width: 30
            height: 30
            source: "file:///home/marteam/.local/share/capricorn/capri-avatar.png"
            fillMode: Image.PreserveAspectCrop
        }
        Rectangle {
            x: 14
            y: 9
            width: 30
            height: 30
            color: "transparent"
            border.color: root.cRed
            border.width: 1
        }
        Text {
            x: 54
            y: 8
            text: "CAPRI"
            color: root.cBright
            font.family: "Chakra Petch"
            font.pixelSize: 16
            font.letterSpacing: 5
        }
        Rectangle { x: 54; y: 30; width: 5; height: 5; radius: 2.5; color: root.cGreen }
        Text {
            x: 65
            y: 26
            text: "LINKED // NIGHT CITY"
            color: root.cDim
            font.family: "Rajdhani"
            font.pixelSize: 8
            font.letterSpacing: 2
        }

        MouseArea {
            anchors.fill: parent
            onPressed: root.startSystemMove()
        }
        Item {
            width: 30
            height: 30
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            Text {
                anchors.centerIn: parent
                text: "✕"
                color: closeMouse.containsMouse ? root.cBright : root.cDim
                font.pixelSize: 15
            }
            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Qt.quit()
            }
        }
    }

    // ── message ──────────────────────────────────────────────────────
    Text {
        id: message
        x: 18
        y: 66
        width: 344
        height: 100
        text: root.shownMessage
        color: root.cBody
        font.family: "Rajdhani"
        font.pixelSize: 12
        lineHeight: 1.3
        wrapMode: Text.WordWrap
        textFormat: Text.PlainText
    }

    Text {
        x: 18
        y: 166
        visible: root.typing
        text: "..."
        color: root.cGreen
        font.family: "Chakra Petch"
        font.pixelSize: 11
        font.letterSpacing: 3
        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { to: 0.2; duration: 380 }
            NumberAnimation { to: 1.0; duration: 380 }
        }
    }

    // ── options ──────────────────────────────────────────────────────
    Column {
        id: optionColumn
        x: 18
        y: 180
        width: 344
        spacing: 8

        Repeater {
            model: root.options

            Rectangle {
                required property var modelData
                width: 344
                height: 36
                color: optHover.containsMouse ? "#260c16" : "#120810"
                border.color: optHover.containsMouse ? root.cRed : "#4a1622"
                border.width: 1
                Behavior on color { ColorAnimation { duration: 110 } }

                Text {
                    x: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.label
                    color: optHover.containsMouse ? root.cBright : root.cBody
                    font.family: "Chakra Petch"
                    font.pixelSize: 10
                    font.letterSpacing: 2
                }
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: ">"
                    color: optHover.containsMouse ? root.cGreen : root.cRed
                    font.family: "Chakra Petch"
                    font.pixelSize: 12
                }

                MouseArea {
                    id: optHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.act(modelData.id)
                }
            }
        }
    }

    // ── footer ───────────────────────────────────────────────────────
    Text {
        x: 18
        y: 432
        text: "CAPRI // DESKTOP COMPANION"
        color: root.cDim
        font.family: "Rajdhani"
        font.pixelSize: 8
        font.letterSpacing: 2
    }
    Text {
        anchors.right: parent.right
        anchors.rightMargin: 18
        y: 432
        text: "ESC // CLOSE"
        color: root.cDim
        font.family: "Rajdhani"
        font.pixelSize: 8
        font.letterSpacing: 2
    }
}
