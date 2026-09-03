import QtQuick 2.0
import SddmComponents 2.0

Rectangle {
    id: root

    width: 1920
    height: 1080
    color: "#07090d"

    property color bg: "#07090d"
    property color panel: "#090d13"
    property color field: "#0d131b"
    property color fg: "#e0e5eb"
    property color muted: "#7b8794"
    property color accent: "#6fa8e8"
    property color accentBright: "#a8c8ee"
    property color border: "#2c3b4c"
    property color success: "#6fd29b"
    property color danger: "#d66a74"

    property bool authenticating: false

    signal tryLogin()

    function submitLogin() {
        if (username.text.length === 0)
            return

        authenticating = true
        status.text = "AUTHENTICATING"
        status.color = accent

        sddm.login(username.text, password.text, session.index)
    }

    onTryLogin: submitLogin()

    Connections {
        target: sddm

        onLoginSucceeded: {
            authenticating = false
            status.text = "ACCESS GRANTED"
            status.color = success
        }

        onLoginFailed: {
            authenticating = false
            status.text = "AUTHENTICATION FAILED"
            status.color = danger
            password.text = ""
            failureFlash.start()
        }

        onInformationMessage: {
            authenticating = false
            status.text = message
            status.color = danger
            failureFlash.start()
        }
    }

    Image {
        anchors.fill: parent
        source: "background.jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
    }

    // Keep the wallpaper dominant while darkening the login side.
    Rectangle {
        anchors.fill: parent
        color: bg
        opacity: 0.28
    }

    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: parent.width * 0.46
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#07090d00" }
            GradientStop { position: 0.34; color: "#07090dcc" }
            GradientStop { position: 1.0; color: "#05070bf2" }
        }
    }

    // ─────────────────────────────────────────────
    // TOP HUD
    // ─────────────────────────────────────────────

    Row {
        x: 34
        y: 28
        spacing: 10

        Text {
            text: "◈"
            color: accent
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
        }

        Column {
            spacing: 3

            Text {
                text: "GOTHAM CITY"
                color: fg
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 1.3
            }

            Text {
                text: "SECURE NODE  //  BATCAVE-01"
                color: muted
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 8
                font.letterSpacing: 1.0
            }
        }
    }

    Column {
        anchors.right: parent.right
        anchors.rightMargin: 34
        y: 23
        spacing: 3

        Text {
            id: clock
            width: 170
            color: fg
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 18
            horizontalAlignment: Text.AlignRight
        }

        Text {
            id: dateText
            width: 170
            color: accent
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 8
            horizontalAlignment: Text.AlignRight
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true

        onTriggered: {
            var now = new Date()
            clock.text = Qt.formatTime(now, "h:mm AP")
            dateText.text = Qt.formatDate(now, "ddd, dd MMM yyyy").toUpperCase()
        }
    }

    Component.onCompleted: {
        var now = new Date()

        clock.text = Qt.formatTime(now, "h:mm AP")
        dateText.text = Qt.formatDate(now, "ddd, dd MMM yyyy").toUpperCase()

        if (username.text === "")
            username.forceActiveFocus()
        else
            password.forceActiveFocus()
    }

    // ─────────────────────────────────────────────
    // RIGHT LOGIN PANEL
    // ─────────────────────────────────────────────

    Rectangle {
        id: card

        width: 470
        height: 650

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 120

        radius: 16

        color: panel
        opacity: 0.97

        border.width: 1
        border.color: border

        // Thin glowing top edge.
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 1
            height: 2
            color: accent
            opacity: 0.82
        }

        // Minimal HUD corner cuts.
        Rectangle { x: -1; y: 28; width: 42; height: 1; color: accent; opacity: 0.8 }
        Rectangle { x: -1; y: 28; width: 1; height: 42; color: accent; opacity: 0.8 }
        Rectangle { anchors.right: parent.right; anchors.rightMargin: -1; y: 28; width: 42; height: 1; color: accent; opacity: 0.8 }
        Rectangle { anchors.right: parent.right; anchors.rightMargin: -1; y: 28; width: 1; height: 42; color: accent; opacity: 0.8 }
        Rectangle { x: -1; anchors.bottom: parent.bottom; anchors.bottomMargin: 28; width: 42; height: 1; color: accent; opacity: 0.35 }
        Rectangle { x: -1; anchors.bottom: parent.bottom; anchors.bottomMargin: 28; width: 1; height: 42; color: accent; opacity: 0.35 }
        Rectangle { anchors.right: parent.right; anchors.rightMargin: -1; anchors.bottom: parent.bottom; anchors.bottomMargin: 28; width: 42; height: 1; color: accent; opacity: 0.35 }
        Rectangle { anchors.right: parent.right; anchors.rightMargin: -1; anchors.bottom: parent.bottom; anchors.bottomMargin: 28; width: 1; height: 42; color: accent; opacity: 0.35 }

        Column {
            anchors.fill: parent
            anchors.leftMargin: 34
            anchors.rightMargin: 34
            anchors.topMargin: 30
            anchors.bottomMargin: 28
            spacing: 14

            // Bat mark.
            Item {
                width: parent.width
                height: 74

                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top

                    width: 58
                    height: 42

                    source: "bat.svg"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom

                    width: 130
                    height: 1

                    color: accent
                    opacity: 0.35
                }
            }

            Text {
                width: parent.width
                text: "B A T C A V E"
                color: fg
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 27
                font.letterSpacing: 5
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                width: parent.width
                text: "NIGHTWATCH SYSTEM"
                color: accent
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                font.letterSpacing: 2.2
                horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
                width: parent.width
                height: 1
                color: border
            }

            Text {
                width: parent.width
                text: "SECURE AUTHENTICATION"
                color: fg
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                font.bold: true
                font.letterSpacing: 1.3
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                width: parent.width
                text: "NIGHTWATCH NODE"
                color: muted
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 9
                font.letterSpacing: 1.1
                horizontalAlignment: Text.AlignHCenter
            }

            Item {
                width: 1
                height: 2
            }

            Text {
                text: "IDENTITY"
                color: muted
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 9
                font.bold: true
                font.letterSpacing: 1.5
            }

            Rectangle {
                width: parent.width
                height: 56

                radius: 8
                color: field
                border.width: 1
                border.color: username.activeFocus ? accent : border

                TextInput {
                    id: username

                    x: 15
                    y: 15
                    width: parent.width - 30
                    height: 28

                    text: userModel.lastUser

                    color: fg
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14

                    selectByMouse: true

                    KeyNavigation.tab: password
                    KeyNavigation.backtab: session

                    Keys.onReturnPressed: password.forceActiveFocus()
                    Keys.onEnterPressed: password.forceActiveFocus()
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 2

                    color: accent
                    opacity: username.activeFocus ? 0.85 : 0
                }
            }

            Text {
                text: "AUTHORIZATION"
                color: muted
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 9
                font.bold: true
                font.letterSpacing: 1.5
            }

            Rectangle {
                width: parent.width
                height: 56

                radius: 8
                color: field
                border.width: 1
                border.color: password.activeFocus ? accent : border

                PasswordBox {
                    id: password

                    x: 15
                    y: 15
                    width: parent.width - 30
                    height: 28

                    color: "transparent"
                    borderColor: "transparent"
                    focusColor: "transparent"
                    hoverColor: "transparent"
                    textColor: fg

                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14

                    tooltipEnabled: true
                    tooltipText: "Caps Lock is enabled"
                    tooltipFG: fg
                    tooltipBG: panel

                    KeyNavigation.tab: loginButton
                    KeyNavigation.backtab: username

                    Keys.onPressed: {
                        if (event.key === Qt.Key_Return ||
                            event.key === Qt.Key_Enter) {
                            root.tryLogin()
                            event.accepted = true
                        }
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 2

                    color: accent
                    opacity: password.activeFocus ? 0.85 : 0
                }
            }

            Row {
                width: parent.width
                height: 18
                spacing: 8

                Rectangle {
                    width: 6
                    height: 6
                    radius: 3

                    anchors.verticalCenter: parent.verticalCenter

                    color: authenticating ? accent : success
                }

                Text {
                    id: status

                    text: "SYSTEM READY"
                    color: muted

                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 8
                    font.bold: true
                    font.letterSpacing: 1.2

                    anchors.verticalCenter: parent.verticalCenter
                }

                Item {
                    width: 1
                    height: 1
                }

                Text {
                    text: "ENCRYPTED"
                    color: muted
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 8
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Rectangle {
                id: loginButton

                width: parent.width
                height: 52

                radius: 8

                color: loginMouse.containsMouse ? accentBright : accent

                Text {
                    anchors.centerIn: parent

                    text: authenticating
                          ? "AUTHENTICATING..."
                          : "INITIALIZE SESSION"

                    color: bg

                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 1.3
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter

                    text: "›"
                    color: bg
                    font.pixelSize: 24
                }

                MouseArea {
                    id: loginMouse

                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: root.tryLogin()
                }

                KeyNavigation.tab: session
                KeyNavigation.backtab: password
            }

            Row {
                width: parent.width
                height: 38
                spacing: 12

                Text {
                    text: "SESSION"
                    color: muted
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 1.1
                    anchors.verticalCenter: parent.verticalCenter
                }

                ComboBox {
                    id: session

                    width: parent.width - 80
                    height: 38

                    model: sessionModel
                    index: sessionModel.lastIndex

                    color: field
                    borderColor: border
                    focusColor: accent
                    hoverColor: field
                    textColor: fg
                    menuColor: panel

                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10

                    KeyNavigation.tab: username
                    KeyNavigation.backtab: loginButton
                }
            }
        }
    }

    // Bottom rail.
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        height: 48

        color: "#05070a"
        opacity: 0.94

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            height: 1
            color: border
        }

        Text {
            x: 28
            anchors.verticalCenter: parent.verticalCenter

            text: "BATCAVE // SECURE LOGIN"

            color: muted
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 9
            font.letterSpacing: 1.1
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            text: "CONNECTION: ENCRYPTED"

            color: accent
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 9
            font.letterSpacing: 1.0
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 28
            anchors.verticalCenter: parent.verticalCenter
            spacing: 24

            Text {
                text: "REBOOT"
                color: muted
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 9
                font.bold: true

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sddm.reboot()
                }
            }

            Text {
                text: "SHUTDOWN"
                color: muted
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 9
                font.bold: true

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sddm.powerOff()
                }
            }
        }
    }

    SequentialAnimation {
        id: failureFlash

        PropertyAnimation {
            target: card
            property: "border.color"
            to: danger
            duration: 120
        }

        PauseAnimation { duration: 260 }

        PropertyAnimation {
            target: card
            property: "border.color"
            to: border
            duration: 500
        }

        PauseAnimation { duration: 1500 }

        ScriptAction {
            script: {
                status.text = "SYSTEM READY"
                status.color = muted
            }
        }
    }
}
