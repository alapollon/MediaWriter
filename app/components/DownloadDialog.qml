/*
 * Fedora Media Writer
 * Copyright (C) 2016 Martin Bříza <mbriza@redhat.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 2.3
import QtQuick.Controls 1.2
import QtQuick.Controls.Styles 1.2
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
import QtQuick.Window 2.0

import MediaWriter 1.0

Dialog {
    id: dialog
    title: qsTr("Write %1").arg(releases.selected.name)

    height: layout.height + $(56)
    standardButtons: StandardButton.NoButton

    width: $(640)

    function reset() {
        writeArrow.color = palette.text
        writeImmediately.checked = false
    }

    onVisibleChanged: {
        if (!visible) {
            if (drives.selected)
                drives.selected.cancel()
            releases.variant.resetStatus()
            downloadManager.cancel()
        }
        reset()
    }

    Connections {
        target: releases
        onSelectedChanged: {
            reset();
        }
    }

    Connections {
        target: drives
        onSelectedChanged: {
            writeImmediately.checked = false
        }
    }

    Connections {
        target: releases.variant
        onStatusChanged: {
            if ([Variant.FINISHED, Variant.FAILED, Variant.FAILED_DOWNLOAD].indexOf(releases.variant.status) >= 0)
                writeImmediately.checked = false
        }
    }

    contentItem: Rectangle {
        id: contentWrapper
        anchors.fill: parent
        color: palette.window
        focus: true

        states: [
            State {
                name: "preparing"
                when: releases.variant.status === Variant.PREPARING
            },
            State {
                name: "downloading"
                when: releases.variant.status === Variant.DOWNLOADING
                PropertyChanges {
                    target: progressBar;
                    value: releases.variant.progress.ratio
                }
            },
            State {
                name: "download_verifying"
                when: releases.variant.status === Variant.DOWNLOAD_VERIFYING
                PropertyChanges {
                    target: progressBar;
                    value: releases.variant.progress.ratio;
                    progressColor: Qt.lighter("green")
                }
            },
            State {
                name: "ready_no_drives"
                when: releases.variant.status === Variant.READY && drives.length <= 0
            },
            State {
                name: "ready"
                when: releases.variant.status === Variant.READY && drives.length > 0
                PropertyChanges {
                    target: messageLoseData;
                    visible: true
                }
                PropertyChanges {
                    target: rightButton;
                    text: qsTr("Write to disk");
                    enabled: true;
                    color: "red";
                    onClicked: drives.selected.write(releases.variant)
                }
            },
            State {
                name: "writing_not_possible"
                when: releases.variant.status === Variant.WRITING_NOT_POSSIBLE
                PropertyChanges {
                    target: driveCombo;
                    enabled: false;
                    placeholderText: qsTr("Writing is not possible")
                }
            },
            State {
                name: "writing"
                when: releases.variant.status === Variant.WRITING
                PropertyChanges {
                    target: messageRestore;
                    visible: true
                }
                PropertyChanges {
                    target: driveCombo;
                    enabled: false
                }
                PropertyChanges {
                    target: progressBar;
                    value: drives.selected.progress.ratio;
                    progressColor: "red"
                }
            },
            State {
                name: "write_verifying"
                when: releases.variant.status === Variant.WRITE_VERIFYING
                PropertyChanges {
                    target: messageRestore;
                    visible: true
                }
                PropertyChanges {
                    target: driveCombo;
                    enabled: false
                }
                PropertyChanges {
                    target: progressBar;
                    value: drives.selected.progress.ratio;
                    progressColor: Qt.lighter("green")
                }
            },
            State {
                name: "finished"
                when: releases.variant.status === Variant.FINISHED
                PropertyChanges {
                    target: messageRestore;
                    visible: true
                }
                PropertyChanges {
                    target: leftButton;
                    text: qsTr("Close");
                    color: "#628fcf";
                    textColor: "white"
                    onClicked: {
                        if (eraseCheckbox.checked)
                            releases.variant.erase()
                        dialog.close()
                    }
                }
                PropertyChanges {
                    target: eraseCheckbox
                    visible: true
                    checked: true
                }
            },
            State {
                name: "failed_verification_no_drives"
                when: releases.variant.status === Variant.FAILED_VERIFICATION && drives.length <= 0
                PropertyChanges {
                    target: rightButton;
                    text: qsTr("Retry");
                    enabled: false;
                    color: "red";
                    onClicked: drives.selected.write(releases.variant)
                }
            },
            State {
                name: "failed_verification"
                when: releases.variant.status === Variant.FAILED_VERIFICATION && drives.length > 0
                PropertyChanges {
                    target: messageLoseData;
                    visible: true
                }
                PropertyChanges {
                    target: rightButton;
                    text: qsTr("Retry");
                    enabled: true;
                    color: "red";
                    onClicked: drives.selected.write(releases.variant)
                }
            },
            State {
                name: "failed_download"
                when: releases.variant.status === Variant.FAILED_DOWNLOAD
                PropertyChanges {
                    target: driveCombo;
                    enabled: false
                }
                PropertyChanges {
                    target: rightButton;
                    text: qsTr("Retry");
                    enabled: true;
                    color: "#628fcf";
                    onClicked: releases.variant.download()
                }
            },
            State {
                name: "failed_no_drives"
                when: releases.variant.status === Variant.FAILED && drives.length <= 0
                PropertyChanges {
                    target: rightButton;
                    text: qsTr("Retry");
                    enabled: false;
                    color: "red";
                    onClicked: drives.selected.write(releases.variant)
                }
            },
            State {
                name: "failed"
                when: releases.variant.status === Variant.FAILED && drives.length > 0
                PropertyChanges {
                    target: messageLoseData;
                    visible: true
                }
                PropertyChanges {
                    target: rightButton;
                    text: qsTr("Retry");
                    enabled: true;
                    color: "red";
                    onClicked: drives.selected.write(releases.variant)
                }
            }
        ]

        Keys.onEscapePressed: {
            if ([Variant.WRITING, Variant.WRITE_VERIFYING].indexOf(releases.variant.status) < 0)
                dialog.visible = false
        }

        ScrollView {
            id: contentScrollView
            anchors.fill: parent
            contentItem: Item {
                width: contentScrollView.width - $(48)
                height: layout.height + $(32)
                Column {
                    id: layout
                    spacing: $(24)
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        topMargin: $(32)
                        leftMargin: $(48)
                    }
                    Column {
                        id: infoColumn
                        spacing: $(4)
                        width: parent.width

                        InfoMessage {
                            id: messageLoseData
                            visible: false
                            width: infoColumn.width
                            text: qsTr("By writing, you will lose all of the data on %1.").arg(driveCombo.currentText)
                        }

                        InfoMessage {
                            id: messageRestore
                            visible: false
                            width: infoColumn.width
                            text: qsTr("Your computer will now report this drive is much smaller than it really is. Just insert your drive again while Fedora Media Writer is running and you'll be able to restore it back to its full size.")
                        }

                        InfoMessage {
                            id: messageSelectedImage
                            width: infoColumn.width
                            visible: releases.selected.isLocal
                            text: "<font color=\"gray\">" + qsTr("Selected:") + "</font> " + (releases.variant.iso ? (((String)(releases.variant.iso)).split("/").slice(-1)[0]) : ("<font color=\"gray\">" + qsTr("None") + "</font>"))
                        }

                        InfoMessage {
                            error: true
                            width: infoColumn.width
                            visible: releases.variant && releases.variant.errorString.length > 0
                            text: releases.variant ? releases.variant.errorString : ""
                        }
                    }

                    ColumnLayout {
                        width: parent.width
                        spacing: $(5)

                        Behavior on y {
                            NumberAnimation {
                                duration: 1000
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            horizontalAlignment: Text.AlignHCenter
                            font.pointSize: $(9)
                            property double leftSize: releases.variant.progress.to - releases.variant.progress.value
                            property string leftStr:  leftSize <= 0                    ? "" :
                                                     (leftSize < 1024)                 ? qsTr("(%1 B left)").arg(leftSize) :
                                                     (leftSize < (1024 * 1024))        ? qsTr("(%1 KB left)").arg((leftSize / 1024).toFixed(1)) :
                                                     (leftSize < (1024 * 1024 * 1024)) ? qsTr("(%1 MB left)").arg((leftSize / 1024 / 1024).toFixed(1)) :
                                                                                         qsTr("(%1 GB left)").arg((leftSize / 1024 / 1024 / 1024).toFixed(1))
                            text: releases.variant.statusString + (releases.variant.status == Variant.DOWNLOADING ? (" " + leftStr) : "")
                            color: palette.windowText
                        }
                        Item {
                            Layout.fillWidth: true
                            height: childrenRect.height
                            AdwaitaProgressBar {
                                id: progressBar
                                width: parent.width
                                progressColor: "#54aada"
                                value: 0.0
                            }
                        }
                        AdwaitaCheckBox {
                            id: writeImmediately
                            enabled: driveCombo.count && opacity > 0.0
                            opacity: (releases.variant.status == Variant.DOWNLOADING || (releases.variant.status == Variant.DOWNLOAD_VERIFYING && releases.variant.progress.ratio < 0.95)) ? 1.0 : 0.0
                            text: qsTr("Write the image immediately when the download is finished")
                            onCheckedChanged: {
                                if (drives.selected) {
                                    drives.selected.cancel()
                                    if (checked)
                                        drives.selected.write(releases.variant)
                                }
                            }
                        }
                    }

                    RowLayout {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: $(32)
                        Image {
                            source: releases.selected.icon
                            Layout.preferredWidth: $(64)
                            Layout.preferredHeight: $(64)
                            sourceSize.width: $(64)
                            sourceSize.height: $(64)
                            fillMode: Image.PreserveAspectFit
                        }
                        Arrow {
                            id: writeArrow
                            anchors.verticalCenter: parent.verticalCenter
                            scale: $(1.4)
                            SequentialAnimation {
                                running: releases.variant.status == Variant.WRITING
                                loops: -1
                                onStopped: {
                                    if (releases.variant.status == Variant.FINISHED)
                                        writeArrow.color = "#00dd00"
                                    else
                                        writeArrow.color = palette.text
                                }
                                ColorAnimation {
                                    duration: 3500
                                    target: writeArrow
                                    property: "color"
                                    to: "red"
                                }
                                PauseAnimation {
                                    duration: 500
                                }
                                ColorAnimation {
                                    duration: 3500
                                    target: writeArrow
                                    property: "color"
                                    to: palette.text
                                }
                                PauseAnimation {
                                    duration: 500
                                }
                            }
                        }
                        Column {
                            spacing: $(6)
                            Layout.preferredWidth: driveCombo.implicitWidth * 2.5
                            AdwaitaComboBox {
                                id: driveCombo
                                width: driveCombo.implicitWidth * 2.5
                                model: drives
                                textRole: "display"
                                Binding {
                                    target: drives
                                    property: "selectedIndex"
                                    value: driveCombo.currentIndex
                                }
                                enabled: true
                                placeholderText: qsTr("There are no portable drives connected")
                            }
                            AdwaitaComboBox {
                                visible: releases.selected.version.variant.arch.id == Architecture.ARM || (releases.selected.isLocal && releases.variant.iso.indexOf(".iso", releases.variant.iso.length - ".iso".length) === -1)
                                width: driveCombo.implicitWidth * 2.5
                                model: ["Raspberry Pi 2 Model B", "Raspberry Pi 3 Model B"]
                            }
                        }
                    }

                    ColumnLayout {
                        z: -1
                        width: parent.width
                        spacing: $(12)
                        RowLayout {
                            height: rightButton.height
                            width: parent.width
                            spacing: $(10)

                            Item {
                                Layout.fillWidth: true
                                height: $(1)
                            }

                            AdwaitaButton {
                                id: leftButton
                                anchors {
                                    right: rightButton.left
                                    top: parent.top
                                    bottom: parent.bottom
                                    rightMargin: $(6)
                                }
                                text: qsTr("Cancel")
                                enabled: true
                                onClicked: {
                                    releases.variant.resetStatus()
                                    writeImmediately.checked = false
                                    dialog.close()
                                }
                                AdwaitaCheckBox {
                                    id: eraseCheckbox
                                    visible: false
                                    opacity: visible ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 120 } }
                                    text: "Erase the saved image"
                                    anchors {
                                        bottom: parent.top
                                        margins: $(6)
                                    }
                                }
                            }
                            AdwaitaButton {
                                id: rightButton
                                anchors {
                                    right: parent.right
                                    top: parent.top
                                    bottom: parent.bottom
                                }
                                textColor: enabled ? "white" : palette.text
                                text: qsTr("Write to disk")
                                enabled: false
                            }
                        }
                    }
                }
            }
        }
    }
}
