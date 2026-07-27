import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Dialogs
import Qt5Compat.GraphicalEffects

ApplicationWindow {
    id: window
    visible: true
    width: 960
    height: 600
    minimumWidth: 750
    minimumHeight: 450
    title: "Hash Lookup // LevelDB Utility"
    color: "#0a0a0a" // Deep terminal black

    readonly property string sansFont: "Inter, Roboto, Segoe UI, sans-serif"
    readonly property string monoFont: "JetBrains Mono, FiraCode Nerd Font, Fira Code, Monospace, Courier New"

    FontLoader {
        id: titleFont
        source: "qrc:/font/cyberblast.ttf"
    }

    // Central Layout Manager
    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: startScreenComponent

        replaceEnter: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 450
            }
        }
        replaceExit: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 450
            }
        }
    }

    // -------------------------------------------------------------
    // START SCREEN COMPONENT
    // -------------------------------------------------------------
    Component {
        id: startScreenComponent

        Item {
            id: startScreenItem
            anchors.fill: parent

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 24

                // Stylized Title
                Text {
                    text: "LASH"
                    color: "#00ff99"
                    font.pixelSize: 64
                    font.bold: true
                    font.letterSpacing: 4
                    font.family: titleFont.status === FontLoader.Ready ? titleFont.name : sansFont
                    Layout.alignment: Qt.AlignHCenter
                }

                // Subtitle
                Text {
                    text: "HASH LOOKUP"
                    color: "#555555"
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 3
                    font.family: sansFont
                    Layout.alignment: Qt.AlignHCenter
                }

                Item { implicitHeight: 6 }

                // Brute-Force Decryption Matrix Loading Bar (10 Blocks)
                Item {
                    id: progressTrack
                    implicitWidth: matrixRow.implicitWidth
                    implicitHeight: 28
                    Layout.alignment: Qt.AlignHCenter

                    property real animatedProgress: 0.0
                    property int totalBlocks: 10

                    Row {
                        id: matrixRow
                        anchors.centerIn: parent
                        spacing: 6

                        Repeater {
                            model: progressTrack.totalBlocks

                            Rectangle {
                                id: blockRect
                                width: 22
                                height: 26
                                radius: 3

                                readonly property bool isLocked: progressTrack.animatedProgress >= (index / 10.0)
                                property string hexChar: "0"

                                color: progressTrack.animatedProgress >= (index / 10.0) ? "#00ff99" : "#1e2622"
                                border.color: isLocked ? "#00ff99" : "#223328"

                                Behavior on color {
                                    ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: blockRect.isLocked ? "█" : blockRect.hexChar
                                    color: blockRect.isLocked ? "#0a0a0a" : "#00ff99"
                                    font.family: monoFont
                                    font.pixelSize: 13
                                    font.bold: true
                                    opacity: blockRect.isLocked ? 0.9 : 0.6
                                }

                                Timer {
                                    interval: 40
                                    repeat: true
                                    running: !blockRect.isLocked
                                    onTriggered: {
                                        let chars = "0123456789ABCDEF"
                                        blockRect.hexChar = chars.charAt(Math.floor(Math.random() * 16))
                                    }
                                }
                            }
                        }
                    }

                    NumberAnimation {
                        id: smoothProgress
                        target: progressTrack
                        property: "animatedProgress"
                        from: 0.0
                        to: 1.0
                        duration: 1200
                        easing.type: Easing.OutCubic
                        running: true
                        onFinished: {
                            stackView.replace(dashboardComponent)
                        }
                    }
                }

                // Watermark
                Text {
                    text: "by Cyras"
                    color: "#444444"
                    font.pixelSize: 12
                    font.italic: true
                    font.family: sansFont
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    // -------------------------------------------------------------
    // DASHBOARD COMPONENT
    // -------------------------------------------------------------
    Component {
        id: dashboardComponent

        Item {
            id: dashboardItem
            anchors.fill: parent

            function formatHashCount(num) {
                if (num >= 1000000000) return (num / 1000000000).toFixed(1) + "B";
                if (num >= 1000000) return (num / 1000000).toFixed(1) + "M";
                if (num >= 1000) return (num / 1000).toFixed(1) + "K";
                return num.toString();
            }

            function appendFormatted(htmlSnippet) {
                if (consoleOutput.text.length > 0) {
                    consoleOutput.text += "<br>" + htmlSnippet
                } else {
                    consoleOutput.text = htmlSnippet
                }
            }

            // Listen for signals from C++ backend
            Connections {
                target: hashEngine
                
                function onStatusUpdate(message) {
                    if (message === "ERR_EMPTY" || message === "[-] EMPTY") {
                        appendFormatted('<font color="#ff5555">[-] EMPTY</font>')
                        emptyWarningAnim.start()
                    } else if (message.startsWith("[-] MISS")) {
                        appendFormatted('<font color="#888888">' + message + '</font>')
                    } else if (message.startsWith("[+] Imported") || message.indexOf("Database cleared") !== -1) {
                        appendFormatted('<font color="#00ff99">' + message + '</font>')
                    } else {
                        appendFormatted('<font color="#888888">' + message + '</font>')
                    }
                }
                function onMatchFound(matchResult) {
                    appendFormatted('<font color="#00ff99"><b>[+] MATCH | ' + matchResult + '</b></font>')
                }
                function onErrorOccurred(errorMessage) {
                    appendFormatted('<font color="#ff5555"><b>[!] ERROR: ' + errorMessage + '</b></font>')
                }
            }

            function appendConsole(msg) {
                if (msg.startsWith("> ")) {
                    appendFormatted('<font color="#77ccff">&gt; ' + msg.substring(2) + '</font>')
                } else if (msg.startsWith("[!]")) {
                    appendFormatted('<font color="#ff5555"><b>' + msg + '</b></font>')
                } else {
                    appendFormatted('<font color="#888888">' + msg + '</font>')
                }
            }

            // File Dialog for importing wordlists
            FileDialog {
                id: fileDialog
                title: "Select Wordlist File"
                nameFilters: ["Text files (*.txt)", "All files (*)"]
                onAccepted: {
                    let path = fileDialog.selectedFile.toString()
                    if (path.startsWith("file://")) {
                        path = path.substring(7)
                    }
                    hashEngine.importWordlist(path)
                }
            }

            // Modal Dialog for adding single word
            Dialog {
                id: addWordDialog
                title: "Add Word"
                modal: true
                anchors.centerIn: parent
                width: 320
                padding: 20
                background: Rectangle {
                    color: "#181818"
                    radius: 8
                    border.color: "#333333"
                }
                header: Rectangle {
                    color: "transparent"
                    height: 36
                    Text {
                        text: "ADD WORD"
                        color: "#00ff99"
                        font.pixelSize: 12
                        font.bold: true
                        font.family: sansFont
                        anchors.centerIn: parent
                    }
                }
                contentItem: ColumnLayout {
                    spacing: 15
                    TextField {
                        id: singleWordInput
                        Layout.fillWidth: true
                        placeholderText: "Word..."
                        color: "#ffffff"
                        font.family: monoFont
                        font.pixelSize: 13
                        background: Rectangle {
                            color: "#222222"
                            radius: 4
                            border.color: singleWordInput.activeFocus ? "#00ff99" : "#444444"
                        }
                        onAccepted: {
                            if (singleWordInput.text.trim().length > 0) {
                                hashEngine.addWord(singleWordInput.text.trim())
                                singleWordInput.text = ""
                                addWordDialog.close()
                            }
                        }
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        spacing: 10
                        Button {
                            text: "Cancel"
                            onClicked: addWordDialog.close()
                        }
                        Button {
                            text: "Add Word"
                            onClicked: {
                                if (singleWordInput.text.trim().length > 0) {
                                    hashEngine.addWord(singleWordInput.text.trim())
                                    singleWordInput.text = ""
                                    addWordDialog.close()
                                }
                            }
                        }
                    }
                }
            }

            property string targetWordlistToRemove: ""

            // Wordlist Removal Confirmation Dialog
            Dialog {
                id: removeWordlistDialog
                modal: true
                anchors.centerIn: parent
                width: 320
                padding: 20
                background: Rectangle {
                    color: "#0a0a0a"
                    radius: 8
                    border.color: "#00ff99"
                    border.width: 1
                }
                header: null
                contentItem: ColumnLayout {
                    spacing: 18

                    Text {
                        text: "REMOVE WORDLIST"
                        color: "#00ff99"
                        font.pixelSize: 12
                        font.bold: true
                        font.family: sansFont
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "Remove wordlist. Delete generated hashes from database?"
                        color: "#cccccc"
                        font.pixelSize: 12
                        font.family: sansFont
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 16

                        Rectangle {
                            width: 96
                            height: 32
                            color: keepBtnArea.containsMouse ? "#222222" : "#141414"
                            radius: 4
                            border.color: keepBtnArea.containsMouse ? "#666666" : "#333333"

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                Layout.alignment: Qt.AlignVCenter

                                Item {
                                    width: 14
                                    height: 14
                                    Layout.alignment: Qt.AlignVCenter

                                    Image {
                                        id: keepIcon
                                        anchors.fill: parent
                                        source: "qrc:/icons/keep.svg"
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        visible: false
                                    }

                                    ColorOverlay {
                                        anchors.fill: keepIcon
                                        source: keepIcon
                                        color: keepBtnArea.containsMouse ? "#ffffff" : "#888888"
                                    }
                                }

                                Text {
                                    text: "KEEP"
                                    color: keepBtnArea.containsMouse ? "#ffffff" : "#888888"
                                    font.pixelSize: 11
                                    font.bold: true
                                    font.family: sansFont
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }

                            MouseArea {
                                id: keepBtnArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    hashEngine.removeWordlist(targetWordlistToRemove, false)
                                    removeWordlistDialog.close()
                                }
                            }
                        }

                        Rectangle {
                            width: 96
                            height: 32
                            color: clearWordlistBtnArea.containsMouse ? "#3a1515" : "#141414"
                            radius: 4
                            border.color: clearWordlistBtnArea.containsMouse ? "#ff5555" : "#444444"

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                Layout.alignment: Qt.AlignVCenter

                                Item {
                                    width: 14
                                    height: 14
                                    Layout.alignment: Qt.AlignVCenter

                                    Image {
                                        id: clearWordlistIcon
                                        anchors.fill: parent
                                        source: "qrc:/icons/clear.svg"
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        visible: false
                                    }

                                    ColorOverlay {
                                        anchors.fill: clearWordlistIcon
                                        source: clearWordlistIcon
                                        color: clearWordlistBtnArea.containsMouse ? "#ff5555" : "#00ff99"
                                    }
                                }

                                Text {
                                    text: "CLEAR"
                                    color: clearWordlistBtnArea.containsMouse ? "#ff5555" : "#00ff99"
                                    font.pixelSize: 11
                                    font.bold: true
                                    font.family: sansFont
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }

                            MouseArea {
                                id: clearWordlistBtnArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    hashEngine.removeWordlist(targetWordlistToRemove, true)
                                    removeWordlistDialog.close()
                                }
                            }
                        }
                    }
                }
            }

            // About Dialog
            Dialog {
                id: aboutDialog
                title: "About Hash Lookup"
                modal: true
                anchors.centerIn: parent
                width: 360
                padding: 20
                background: Rectangle {
                    color: "#0a0a0a"
                    radius: 8
                    border.color: "#00ff99"
                    border.width: 1
                }
                header: Rectangle {
                    color: "transparent"
                    height: 36
                    Text {
                        text: "ABOUT LASH"
                        color: "#00ff99"
                        font.family: sansFont
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1.2
                        anchors.centerIn: parent
                    }
                }
                contentItem: ColumnLayout {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12

                    Text {
                        text: "LASH"
                        color: "#00ff99"
                        font.family: titleFont.status === FontLoader.Ready ? titleFont.name : sansFont
                        font.pixelSize: 28
                        font.bold: true
                        font.letterSpacing: 2
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "v1.0"
                        color: "#888888"
                        font.family: sansFont
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "Developed by Cyras"
                        color: "#ffffff"
                        font.family: sansFont
                        font.pixelSize: 13
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Rectangle {
                        Layout.preferredWidth: 280
                        Layout.alignment: Qt.AlignHCenter
                        height: 1
                        color: "#222222"
                    }

                    Text {
                        text: "CyberSec Assignment @ 2026 IBT"
                        color: "#aaaaaa"
                        font.family: monoFont
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 280
                    }

                    Item { implicitHeight: 4 }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 100
                        height: 32
                        color: closeBtnArea.containsMouse ? "#222222" : "#141414"
                        radius: 4
                        border.color: closeBtnArea.containsMouse ? "#00ff99" : "#444444"

                        Text {
                            anchors.centerIn: parent
                            text: "Close"
                            color: closeBtnArea.containsMouse ? "#00ff99" : "#ffffff"
                            font.family: sansFont
                            font.pixelSize: 12
                            font.bold: true
                        }

                        MouseArea {
                            id: closeBtnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: aboutDialog.close()
                        }
                    }
                }
            }

            // Dual Pane SplitView Layout
            SplitView {
                anchors.fill: parent
                anchors.margins: 15
                orientation: Qt.Horizontal

                handle: Rectangle {
                    implicitWidth: 8
                    color: "transparent"
                    Rectangle {
                        anchors.centerIn: parent
                        width: 2
                        height: parent.height
                        color: "#282828"
                    }
                }

                // LEFT PANE: Controls & State
                Rectangle {
                    SplitView.preferredWidth: 350
                    SplitView.minimumWidth: 280
                    SplitView.maximumWidth: 480
                    color: "#141414"
                    radius: 8
                    border.color: "#2a2a2a"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 14

                        // Input Section Header
                        Text {
                            text: "MAIN"
                            color: "#555555"
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 1.2
                            font.family: sansFont
                        }

                        // Command Palette TextField
                        TextField {
                            id: inputField
                            Layout.fillWidth: true
                            placeholderText: "Enter Hash..."
                            color: "#ffffff"
                            font.family: monoFont
                            font.pixelSize: 13
                            background: Rectangle {
                                color: "#222222"
                                radius: 4
                                border.color: inputField.activeFocus ? "#00ff99" : "#333333"
                            }
                            
                            onAccepted: {
                                let text = inputField.text.trim()
                                if (text.length === 0) return

                                if (text === ":clear") {
                                    hashEngine.clearDatabase()
                                } else if (text.startsWith(":")) {
                                    appendFormatted('<font color="#ffaa00">[-] Invalid command. Use :clear to wipe database.</font>')
                                } else {
                                    hashEngine.lookupHash(text)
                                }
                                inputField.text = ""
                            }
                        }

                        // Action Row
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            // Button 1: [Import Wordlist]
                            Rectangle {
                                Layout.fillWidth: true
                                height: 36
                                color: importBtnArea.containsMouse ? "#222222" : "#1a1a1a"
                                radius: 4
                                border.color: importBtnArea.containsMouse ? "#00ff99" : "#333333"

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 8

                                    Item {
                                        width: 16
                                        height: 16
                                        Layout.alignment: Qt.AlignVCenter

                                        Image {
                                            id: folderIcon
                                            anchors.fill: parent
                                            source: "qrc:/icons/folder-open.svg"
                                            fillMode: Image.PreserveAspectFit
                                            smooth: true
                                            visible: false
                                        }

                                        ColorOverlay {
                                            anchors.fill: folderIcon
                                            source: folderIcon
                                            color: importBtnArea.containsMouse ? "#00ff99" : "#cccccc"
                                        }
                                    }

                                    Text {
                                        text: "Import Wordlist"
                                        color: importBtnArea.containsMouse ? "#00ff99" : "#cccccc"
                                        font.pixelSize: 12
                                        font.bold: true
                                        font.family: sansFont
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                }

                                MouseArea {
                                    id: importBtnArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: fileDialog.open()
                                }
                            }

                            // Button 2: [N] (Add New Word)
                            Rectangle {
                                width: 85
                                height: 36
                                color: addBtnArea.containsMouse ? "#222222" : "#1a1a1a"
                                radius: 4
                                border.color: addBtnArea.containsMouse ? "#00ff99" : "#333333"

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 8

                                    Item {
                                        width: 15
                                        height: 15
                                        Layout.alignment: Qt.AlignVCenter

                                        Image {
                                            id: plusIcon
                                            anchors.fill: parent
                                            source: "qrc:/icons/plus-square.svg"
                                            fillMode: Image.PreserveAspectFit
                                            smooth: true
                                            visible: false
                                        }

                                        ColorOverlay {
                                            anchors.fill: plusIcon
                                            source: plusIcon
                                            color: addBtnArea.containsMouse ? "#00ff99" : "#ffffff"
                                        }
                                    }

                                    Text {
                                        text: "Add"
                                        color: addBtnArea.containsMouse ? "#ffffff" : "#cccccc"
                                        font.pixelSize: 12
                                        font.bold: true
                                        font.family: sansFont
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                }

                                MouseArea {
                                    id: addBtnArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: addWordDialog.open()
                                }
                            }
                        }

                        // Wordlist Manager Header
                        Text {
                            text: "WORDLIST MANAGER"
                            color: "#555555"
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 1.2
                            font.family: sansFont
                            Layout.topMargin: 6
                        }

                        // Wordlist Manager (ListView) inside ScrollView
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "#181818"
                            radius: 6
                            border.color: "#282828"

                            ScrollView {
                                anchors.fill: parent
                                anchors.margins: 6
                                clip: true

                                ListView {
                                    id: wordlistView
                                    anchors.fill: parent
                                    spacing: 6
                                    model: hashEngine.activeWordlists

                                    delegate: Rectangle {
                                        width: wordlistView.width
                                        height: 36
                                        color: "#222222"
                                        radius: 4
                                        border.color: "#333333"

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
                                            spacing: 8

                                            Text {
                                                text: "🗄"
                                                font.pixelSize: 12
                                            }

                                            Text {
                                                text: modelData
                                                color: "#e0e0e0"
                                                font.pixelSize: 12
                                                font.family: sansFont
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }

                                            Rectangle {
                                                width: 22
                                                height: 22
                                                radius: 3
                                                color: removeBtnArea.containsMouse ? "#3a1515" : "#1a1a1a"
                                                border.color: removeBtnArea.containsMouse ? "#ff5555" : "#444444"

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "✕"
                                                    color: removeBtnArea.containsMouse ? "#ff5555" : "#888888"
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                    font.family: sansFont
                                                }

                                                MouseArea {
                                                    id: removeBtnArea
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    onClicked: {
                                                        targetWordlistToRemove = modelData
                                                        removeWordlistDialog.open()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Empty state indicator
                            Text {
                                anchors.centerIn: parent
                                visible: hashEngine.activeWordlists.length === 0
                                text: "No active wordlist."
                                color: "#444444"
                                font.pixelSize: 11
                                font.family: sansFont
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }

                // RIGHT PANE: Console & Footer
                Rectangle {
                    SplitView.fillWidth: true
                    color: "#141414"
                    radius: 8
                    border.color: "#2a2a2a"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        // Terminal Wipe Animation & Shortcut
                        Shortcut {
                            sequence: "Ctrl+L"
                            onActivated: wipeAnimation.start()
                        }

                        SequentialAnimation {
                            id: wipeAnimation

                            NumberAnimation {
                                target: consoleOutput
                                property: "opacity"
                                to: 0.0
                                duration: 100
                                easing.type: Easing.InOutQuad
                            }
                            ScriptAction {
                                script: consoleOutput.text = ""
                            }
                            PropertyAction {
                                target: consoleOutput
                                property: "opacity"
                                value: 1.0
                            }
                        }

                        // Console Header
                        Text {
                            text: "OUTPUT"
                            color: "#555555"
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 1.2
                            font.family: sansFont
                        }

                        // Console Output View
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "#181818"
                            radius: 6
                            border.color: "#282828"

                            ScrollView {
                                anchors.fill: parent
                                anchors.margins: 12
                                clip: true

                                TextArea {
                                    id: consoleOutput
                                    width: parent.width
                                    readOnly: true
                                    textFormat: TextEdit.RichText
                                    wrapMode: Text.WrapAnywhere
                                    font.family: monoFont
                                    font.pixelSize: 13
                                    leftPadding: 10
                                    rightPadding: 10
                                    topPadding: 10
                                    bottomPadding: 10
                                    text: ""
                                    background: null
                                }
                            }

                            // Bottom Right Clear Icon Button
                            Item {
                                anchors.bottom: parent.bottom
                                anchors.right: parent.right
                                anchors.margins: 15
                                width: 20
                                height: 20
                                opacity: clearMouseArea.containsMouse ? 1.0 : 0.4

                                Behavior on opacity {
                                    NumberAnimation { duration: 150 }
                                }

                                Image {
                                    id: clearIcon
                                    anchors.fill: parent
                                    source: "qrc:/icons/clear.svg"
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    visible: false
                                }

                                ColorOverlay {
                                    anchors.fill: clearIcon
                                    source: clearIcon
                                    color: clearMouseArea.containsMouse ? "#00ff99" : "#ffffff"
                                }

                                MouseArea {
                                    id: clearMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: wipeAnimation.start()
                                }
                            }
                        }

                        // Status Footer
                        Rectangle {
                            Layout.fillWidth: true
                            height: 44
                            color: "#181818"
                            radius: 6
                            border.color: "#282828"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14

                                // Mode indicator
                                RowLayout {
                                    spacing: 6
                                    Text {
                                        text: "Hash Type:"
                                        color: "#666666"
                                        font.pixelSize: 11
                                        font.family: sansFont
                                    }
                                    Text {
                                        text: {
                                            let t = inputField.text.trim()
                                            if (t.startsWith(":")) return "SYSTEM COMMAND"
                                            if (t.length === 32) return "MD5 (32 hex)"
                                            if (t.length === 40) return "SHA1 (40 hex)"
                                            if (t.length === 64) return "SHA256 (64 hex)"
                                            return "MD5 / SHA1 / SHA256"
                                        }
                                        color: "#00ff99"
                                        font.pixelSize: 11
                                        font.bold: true
                                        font.family: monoFont
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                // Loaded Hashes & Watermark
                                ColumnLayout {
                                    Layout.alignment: Qt.AlignRight
                                    spacing: 2

                                    Text {
                                        id: totalHashesText
                                        text: "TOTAL HASHES: " + formatHashCount(hashEngine.totalHashes)
                                        color: "#ffffff"
                                        font.pixelSize: 11
                                        font.bold: true
                                        font.family: sansFont
                                        Layout.alignment: Qt.AlignRight

                                        SequentialAnimation {
                                            id: emptyWarningAnim
                                            loops: 3
                                            ColorAnimation { target: totalHashesText; property: "color"; to: "#ff3333"; duration: 150 }
                                            ColorAnimation { target: totalHashesText; property: "color"; to: "#ffffff"; duration: 150 }
                                        }
                                    }

                                    RowLayout {
                                        spacing: 6
                                        Layout.alignment: Qt.AlignRight

                                        Text {
                                            text: "by Cyras"
                                            color: "#555555"
                                            font.pixelSize: 10
                                            font.italic: true
                                            font.family: sansFont
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Item {
                                            width: 14
                                            height: 14
                                            Layout.alignment: Qt.AlignVCenter

                                            Image {
                                                id: infoIcon
                                                anchors.fill: parent
                                                source: "qrc:/icons/info.svg"
                                                fillMode: Image.PreserveAspectFit
                                                smooth: true
                                                visible: false
                                            }

                                            ColorOverlay {
                                                anchors.fill: infoIcon
                                                source: infoIcon
                                                color: infoMouseArea.containsMouse ? "#00ff99" : "#666666"
                                            }

                                            MouseArea {
                                                id: infoMouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: aboutDialog.open()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
