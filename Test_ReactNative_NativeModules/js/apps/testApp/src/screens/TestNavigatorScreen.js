/**
 * Created by GJS on 2017/4/10.
 */

import React from 'react';

import {
    Platform,
    ScrollView,
    StyleSheet,
    TouchableOpacity,
    Button,
    Image,
    Text,
    View,
} from 'react-native';
import { StackNavigator } from 'react-navigation';

import TestTabNavigator from './testScreens/TestTabNavigatorScreen';
import TestBluetoothScreen from './testScreens/TestBluetoothScreen';

const ExampleRoutes = {
    TestTabNavigator: {
        name: 'test tab navigator',
        description: 'A tab navigator',
        screen: TestTabNavigator,
    },
    TestBluetooth: {
        name: 'test bluetooth',
        description: 'A test screen: bluetooth',
        screen: TestBluetoothScreen,
    },
};

const Banner = () => (
    <View style={styles.banner}>
        <Image
            source={require('../../assets/NavLogo.png')}
            style={styles.bannerImage}
        />
        <Text style={styles.bannerTitle}>Test React Navigation</Text>
    </View>
);

const MainScreen = ({ navigation }) => (
    <ScrollView>
        <Banner />
        {Object.keys(ExampleRoutes).map((routeName: string) =>
            <TouchableOpacity
                key={routeName}
                onPress={() => {
                  const { path, params, screen } = ExampleRoutes[routeName];
                  const { router } = screen;
                  const action = path && router.getActionForPathAndParams(path, params);
                  navigation.navigate(routeName, {}, action);
                }}
            >
                <View style={styles.item}>
                    <Text style={styles.title}>{ExampleRoutes[routeName].name}</Text>
                    <Text style={styles.description}>{ExampleRoutes[routeName].description}</Text>
                </View>
            </TouchableOpacity>
        )}
    </ScrollView>
);

MainScreen.navigationOptions = {
    title: 'test navigation screens',
}

const AppNavigator = StackNavigator({
    ...ExampleRoutes,
    Index: {
        screen: MainScreen,
    },
}, {
    initialRouteName: 'Index',
    headerMode: 'none',

    /*
     * Use modal on iOS because the card mode comes from the right,
     * which conflicts with the drawer example gesture
     */
    // mode: Platform.OS === 'ios' ? 'modal' : 'card',
    mode: 'card',
});

// export default () => <AppNavigator />;
export default AppNavigator;

const styles = StyleSheet.create({
    banner: {
        backgroundColor: '#673ab7',
        flexDirection: 'row',
        alignItems: 'center',
        padding: 16,
        // marginTop: Platform.OS === 'ios' ? 20 : 0,
    },
    bannerImage: {
        width: 36,
        height: 36,
        resizeMode: 'contain',
        tintColor: '#fff',
        margin: 8,
    },
    bannerTitle: {
        fontSize: 18,
        fontWeight: '200',
        color: '#fff',
        margin: 8,
    },
    item: {
        backgroundColor: '#fff',
        paddingHorizontal: 16,
        paddingVertical: 12,
        borderBottomWidth: StyleSheet.hairlineWidth,
        borderBottomColor: '#ddd',
    },
    image: {
        width: 120,
        height: 120,
        alignSelf: 'center',
        marginBottom: 20,
        resizeMode: 'contain',
    },
    title: {
        fontSize: 16,
        fontWeight: 'bold',
        color: '#444',
    },
    description: {
        fontSize: 13,
        color: '#999',
    },
});
