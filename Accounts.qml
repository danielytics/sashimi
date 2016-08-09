import QtQuick 2.3
import QtQuick.Controls 2.0
import QtQuick.LocalStorage 2.0
import QtQuick.Layouts 1.3

Rectangle {
    signal accountOpened (string email, string remote_key)

    id: accountsDialog
    anchors.fill: parent
//    title: "Checkvist Accounts"
    visible: true
    color: "darkgray"
    z: 100

//    standardButtons: StandardButton.Cancel | StandardButton.Open
    Rectangle {
        anchors.fill: parent
        anchors.margins: 25
        color: "lightgray"

        GroupBox {
            id: accountListArea
            visible: false
            anchors.fill: parent
            anchors.margins: 10
            title: "Select Account"
            ListView {
                id: accountList
                anchors.fill: parent
                model: ListModel {}
                highlight: Rectangle { color: "lightsteelblue"; radius: 5 }
                delegate: Text {
                    height: 20
                    text: email
                }
            }
            Button {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                text: "Log In"
                onClicked: {
                    var selectedAccount = accountList.model.get(accountList.currentIndex);
                    accountOpened(selectedAccount.email, selectedAccount.remote_key);
                    accountsDialog.visible = false
                }
            }
        }
        GroupBox {
            id: addAccountArea
            visible: false
            anchors.fill: parent
            anchors.margins: 10
            title: "Add Account"
            GridLayout {
                anchors.fill: parent
                columns: 2
                Text {
                    text: "Email:"
                }
                Rectangle {
                    color: "white"
                    width: 200
                    height: 15
                    TextInput {
                        anchors.fill: parent
                        id: email
                    }
                }

                Text {
                    text: "API Key:"
                }
                Rectangle {
                    color: "white"
                    width: 200
                    height: 15
                    TextInput {
                        anchors.fill: parent
                        id: remote_key
                    }
                }

                Rectangle {}
                Button {
                    text: "Add"
                    onClicked: {
                        var error = false;
                        if (! email.text || email.text == "") {
                            error = true;
                        }
                        if (! email.text || email.text == "") {
                            error = true;
                        }
                        if (! error) {
                            _transaction(function(tx){
                                tx.executeSql('INSERT INTO CheckvistUsers VALUES(?, ?)', [ email.text, remote_key.text ]);
                            });
                            accountList.model.append({email: email.text, remote_key: remote_key.text})
                            addAccountArea.visible = false;
                            accountListArea.visible = true;
                        }
                    }
                }
            }
        }
    }

    function _transaction (func) {
        var db = LocalStorage.openDatabaseSync("SashimiUserDB", "1.0", "Sashimi Checkvist Users", 1024);
        db.transaction(func);
    }

    function open () {
        accountListArea.visible = false;
        addAccountArea.visible = false;

        _transaction(function(tx) {
            // Create the database if it doesn't already exist
            tx.executeSql('CREATE TABLE IF NOT EXISTS CheckvistUsers (email TEXT, remote_key TEXT)');

            // Show all added greetings
            var results = tx.executeSql('SELECT * FROM CheckvistUsers').rows;
            if (results.length > 0) {
                accountList.model.clear();
                for (var idx = 0; idx < results.length; idx++) {
                    accountList.model.append(results.item(idx));
                }
                accountListArea.visible = true;
            } else {
                addAccountArea.visible = true;
            }
            // Make the dialog visible
            visible = true;
        });
    }
}
