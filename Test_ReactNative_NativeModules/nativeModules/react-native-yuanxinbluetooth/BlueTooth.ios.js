'use strict';

import { NativeModules } from 'react-native';
const { BlueToothModule  } = NativeModules;

export default class BlueTooth {
    static CheckBtIsValueble():Promise{
        return new Promise(function(resolve, reject) {
            reject({code: '-1', message: '暂不支持该方法'});
        });
    }
    static getBtState():Promise{
        return BlueToothModule.getBtState();
    }
    static startBt():Promise{
        return BlueToothModule.startBt();
    }
    static ScanBt(data):Promise{
        return BlueToothModule.ScanBt(data);
    }
    static connectDev(data):Promise{
        return BlueToothModule.connBtDev(data);
    }
    static writeBtData(data):Promise{
        return BlueToothModule.writeBtData(data)
    }
    static ToSerchAndConn():Promise{
        return new Promise(function(resolve, reject) {
            reject({code: '-1', message: '暂不支持该方法'});
        });
    }

    // ios
    static getPeripheralServices(peripheralUUID):Promise{
        return BlueToothModule.getPeripheralServices(peripheralUUID);
    }
}
