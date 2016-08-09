import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import QtQuick.Dialogs 1.2

import "networking.js" as Network

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 640
    height: 480
    title: qsTr("Hello World")

    function fetchLists (username, remote_key) {
        Network.workflow("https://checkvist.com")
            // First request: Get the API Token
            .params({"username": username, "remote_key": remote_key})
            .get("/auth/login.json")
            .when(200, function (headers, body) {auth.api_token = body;})
            // Next request: List all checklists
            .next()
            .params({token: function(){return auth.api_token;}})
            .get("/checklists.json")
            .when(200, function (headers, body) {
                listMenu.model.clear();
                for (var idx in body) {
                    listMenu.model.append(body[idx]);
                }
            })
            // Run the workflow
            .run();
    }

    Component {
        id: listDelegate
        Item {
            width: 180
            height: 20
            property var view: ListView.view
            MouseArea {
                anchors.fill: parent
                Column {
                    Text {
                        font.pointSize: 10
                        text: name
                    }
                }
                onClicked: view.currentIndex = index
            }
        }
    }
    Component {
        id: itemDelegate
        Item {
            width: 180
            height: 20
            property var view: ListView.view
            MouseArea {
                anchors.fill: parent
                Column {
                    Text {
                        font.pointSize: 10
                        text: content
                    }
                }
                onClicked: view.currentIndex = index;
            }
        }
    }

    QtObject {
        id: auth
        property string api_token: ""
    }
    Accounts {
        id: accounts
//        width: mainWindow.width - 100
//        height: mainWindow.height - 100

        onAccountOpened: fetchLists(email, remote_key)
    }

    Component.onCompleted: {
        accounts.open();
    }

    Rectangle {
        id: menuArea
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: 100
        color: "lightgray"
        clip: true

        ListView {
            id: listMenu
            anchors.fill: parent
            model: ListModel {}
            highlight: Rectangle { color: "lightsteelblue"; radius: 5 }
            delegate: listDelegate
            focus: true
            onCurrentIndexChanged: {
                var index = currentIndex;
                var currentList = model.get(index);
                var listName = currentList['name'];
                var listId =  currentList['id'];
                function updateList (list) {
                    if (index == currentIndex) {
                        itemList.model.clear();
                        for (var idx in list) {
                            itemList.model.append(list[idx]);
                        }
                    }
                }
                if (itemList.listCache[listId] === undefined) {
                    Network.workflow("https://checkvist.com")
                        // Get the selected list
                        .params({token: auth.api_token})
                        .get("/checklists/" + listId + "/tasks.json")
                        .when(200, function (headers, body) {
                            itemList.listCache[listId] = body;
                            updateList(body);
                        })
                        // Run the workflow
                        .run();
                } else {
                    updateList(itemList.listCache[listId]);
                }
            }
        }
    }
    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: menuArea.right
        anchors.right: parent.right

        ListView {
            property var listCache: ({})
            id: itemList
            anchors.fill: parent
            model: ListModel {}
            highlight: Rectangle { color: "lightsteelblue"; radius: 5 }
            highlightMoveDuration: 0
            delegate: itemDelegate
        }
    }
}
