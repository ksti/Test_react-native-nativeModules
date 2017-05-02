/**
 * Created by GJS on 2017/3/30.
 */

import React from 'react';
import {
    Text,
} from 'react-native';
import { StackNavigator } from 'react-navigation';

/*
 * Screens
 */
import HomeScreen from './screens/HomeScreen'
import ChatScreen from './screens/ChatScreen'

import TestNavigatorScreen from './screens/TestNavigatorScreen'

/**
 * Header is only available for StackNavigator.
 */

const SimpleApp = StackNavigator({
    Home: { screen: HomeScreen },
    Chat: { screen: ChatScreen },

    // test navigator screens
    TestNavigatorScreen: { screen: TestNavigatorScreen },
});

export default SimpleApp;
