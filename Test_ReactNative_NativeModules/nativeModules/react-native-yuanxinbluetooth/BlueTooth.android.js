'use strict';

import { NativeModules } from 'react-native';
const { BlueToothModule  } = NativeModules;

export default class BlueTooth {
    static CheckBtIsValueble():Promise{
        return  BlueToothModule.checkBtIsValueble();
    }
    static getBtState():Promise{
        return  BlueToothModule.getBtState();
    }
    static startBt():Promise{
        return  BlueToothModule.startBt();
    }
    static ScanBt():Promise{
        return  BlueToothModule.ScanBt();
    }
    static connectDev(data):Promise{
        return  BlueToothModule.connBtDev(data);
    }
    static writeBtData(data):Promise{
        return BlueToothModule.writeBtData(data)
    }
    static ToSerchAndConn():Promise{
        return  BlueToothModule.ToSerchAndConn();
    }
}