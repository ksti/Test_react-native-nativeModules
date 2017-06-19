/**
 * Created by GJS on 2017/5/2.
 */

import React from 'react';
import {
    Button,
    Platform,
    ScrollView,
    StyleSheet,
    Text,
    TouchableOpacity,
    View,
} from 'react-native';

import YuanXinBluetooth from 'react-native-yuanxinbluetooth'

export default class TestBluetoothScreen extends React.Component {
    static navigationOptions = {
        title: 'Welcome',
    };
    render() {
        const { navigate } = this.props.navigation;
        return (
            <View>
                <Text style={styles.title}>test bluetooth!</Text>
                <Button
                    onPress={() => navigate('Chat', { user: 'Lucy' })}
                    title="Chat with Lucy" />
                <Button
                    onPress={() => {
                        YuanXinBluetooth && YuanXinBluetooth.startBt().then((result) => {
                            console.log('start bluetooth:' + JSON.stringify(result));
                        }).catch((err) => {
                            console.log('start bluetooth error:' + err.message);
                        });
                    }}
                    title="start bluetooth" />
                <Button
                    onPress={() => {
                        /**
                         *
                         [
                             {
                                 "peripheral":"44AE323F-EF63-4AE4-BBA2-1B4A67C13E92",
                                 "RSSI":-79,
                                 "advertisementData":{
                                     "kCBAdvDataIsConnectable":true,
                                     "kCBAdvDataManufacturerData":{

                                     }
                                 }
                             },
                             {
                                 "peripheral":"67D824DD-EB3F-4C9F-8F27-DACDE124D71E",
                                 "RSSI":-47,
                                 "advertisementData":{
                                     "kCBAdvDataIsConnectable":true
                                 }
                             },
                             {
                                 "peripheral":"03BF0044-DE1A-49B3-A7BB-29283D498D36",
                                 "RSSI":-90,
                                 "advertisementData":{
                                     "kCBAdvDataLocalName":"mambo 2",
                                     "kCBAdvDataManufacturerData":{

                                     },
                                     "kCBAdvDataServiceUUIDs":[
                                         {

                                         },
                                         {

                                         }
                                     ],
                                     "kCBAdvDataIsConnectable":true
                                 }
                             },
                             {
                                 "peripheral":"5AF62210-2A39-43D4-9BD5-E6C2B2C19E3B",
                                 "RSSI":-94,
                                 "advertisementData":{
                                     "kCBAdvDataIsConnectable":true,
                                     "kCBAdvDataLocalName":"MI1A",
                                     "kCBAdvDataServiceUUIDs":[
                                         {

                                         },
                                         {

                                         }
                                     ],
                                     "kCBAdvDataServiceData":{

                                     },
                                     "kCBAdvDataManufacturerData":{

                                     }
                                 }
                             }
                         ]
                         */
                        YuanXinBluetooth && YuanXinBluetooth.ScanBt().then((result) => {
                            console.log('scan:' + JSON.stringify(result));
                        }).catch((err) => {
                            console.log('scan error:' + err.message);
                        });
                    }}
                    title="scan" />
                <Button
                    onPress={() => {
                        YuanXinBluetooth && YuanXinBluetooth.connectDev({
                            peripheral: '67D824DD-EB3F-4C9F-8F27-DACDE124D71E',
                        });
                    }}
                    title="connect" />
                <Button
                    onPress={() => {
                        /**
                         *
                         {
                             "result":[
                                 {
                                     "characteristics":[
                                         "2A29",
                                         "2A24"
                                     ],
                                     "serviceUUID":"180A"
                                 },
                                 {
                                     "characteristics":[
                                         "8667556C-9A37-4C91-84ED-54EE27D90049"
                                     ],
                                     "serviceUUID":"D0611E78-BBB4-4591-A5F8-487910AE4366"
                                 },
                                 {
                                     "characteristics":[
                                         "AF0BADB1-5B99-43CD-917A-A77BC549E3CC"
                                     ],
                                     "serviceUUID":"9FA480E0-4967-4542-9390-D343DC5D04AE"
                                 }
                             ]
                         }
                         */
                        YuanXinBluetooth && YuanXinBluetooth.getPeripheralServices('67D824DD-EB3F-4C9F-8F27-DACDE124D71E').then((result) => {
                            console.log('get peripheral services:' + JSON.stringify(result));
                        }).catch((err) => {
                            console.log('get peripheral services error:' + err.message);
                        });
                    }}
                    title="get peripheral services" />
                <Button
                    onPress={() => {
                        YuanXinBluetooth && YuanXinBluetooth.ScanBt([
                            '180A',
                        ]).then((result) => {
                            console.log('scan services:' + JSON.stringify(result));
                        }).catch((err) => {
                            console.log('scan services error:' + err.message);
                        });
                    }}
                    title="scan services" />
            </View>
    );
    }
}

const styles = StyleSheet.create({
    title: {
        fontSize: 16,
        fontWeight: 'bold',
        color: '#444',
    },
    description: {
        fontSize: 13,
        color: '#999',
    },
    image: {
        width: 120,
        height: 120,
        alignSelf: 'center',
        marginBottom: 20,
        resizeMode: 'contain',
    },
});