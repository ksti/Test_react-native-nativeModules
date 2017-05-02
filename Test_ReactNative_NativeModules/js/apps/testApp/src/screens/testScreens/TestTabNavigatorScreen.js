/**
 * Created by GJS on 2017/4/7.
 */

import React from 'react';
import {
    Platform,
    ScrollView,
    StyleSheet,
    TouchableOpacity,
    Button,
    Text,
    View,
} from 'react-native';
import { TabNavigator } from "react-navigation";

class RecentChatsScreen extends React.Component {
    static navigationOptions = ({ navigation }) => ({
        title: `RecentChatsScreen`,
    });
    render() {
        return <Text>List of recent chats</Text>
    }
}

class AllContactsScreen extends React.Component {
    static navigationOptions = ({ navigation }) => ({
        title: `AllContactsScreen`,
    });
    render() {
        return (
            <View>
                <Text>List of all contacts</Text>
                <Button
                    onPress={() => {
                        this.props.navigation.navigate('Chat', { user: 'Lucy' })
                    }}
                    title="Chat with Lucy"
                />
            </View>
        )


    }
}

const MainScreenNavigator = TabNavigator({
    Recent: { screen: RecentChatsScreen },
    All: { screen: AllContactsScreen },
});

MainScreenNavigator.navigationOptions = {
    title: 'My Chats',
};

export default MainScreenNavigator;

// const SimpleStack = StackNavigator({
//     Home: {
//         screen: MyHomeScreen,
//     },
//     Profile: {
//         path: 'people/:name',
//         screen: MyProfileScreen,
//     },
//     Photos: {
//         path: 'photos/:name',
//         screen: MyPhotosScreen,
//     },
// });