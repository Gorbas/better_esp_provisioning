import 'dart:async';
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:esp_provisioning/esp_provisioning.dart';
import 'package:esp_provisioning/extensions.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'transport.dart';

class TransportBLE implements ProvTransport {
  final BluetoothDevice peripheral;
  List<BluetoothService> peripheralServices = <BluetoothService>[];
  List<BluetoothCharacteristic> cList = <BluetoothCharacteristic>[];
  final String serviceUUID;
  late Map<String, String> nuLookup;
  final Map<String, String> lockupTable;

  static const PROV_BLE_SERVICE = '021a9004-0382-4aea-bff4-6b3f1c5adfb4';
  static const PROV_BLE_EP = {
    'prov-scan': 'ff50',
    'prov-session': 'ff51',
    'prov-config': 'ff52',
    'proto-ver': 'ff53',
    'custom-data': 'ff54',
  };

  TransportBLE(this.peripheral,
      {this.serviceUUID = PROV_BLE_SERVICE, this.lockupTable = PROV_BLE_EP}) {
    nuLookup = Map<String, String>();

    for (var name in lockupTable.keys) {
      var charsInt = int.parse(lockupTable[name]!, radix: 16);
      var serviceHex = charsInt.toRadixString(16).padLeft(4, '0');
      nuLookup[name] =
          serviceUUID.substring(0, 4) + serviceHex + serviceUUID.substring(8);
    }
  }

  Future<bool> _isConnected(BluetoothDevice peripheral) async {
    final state = await peripheral.state.first;
    return state == BluetoothDeviceState.connected;
  }

  Future<bool> connect() async {
    bool isConnected = await _isConnected(peripheral);
    if (isConnected) {
      return Future.value(true);
    }
    await peripheral.connect(timeout: const Duration(seconds: 10));

    try {
      peripheralServices = await peripheral.discoverServices();
    } on TimeoutException {
      throw ('TransportBLE : discoverServices for ${peripheral.name} timed out ');
    } catch (e) {
      throw ('TransportBLE : discoverServices for ${peripheral.name} unknown exception ${e.toString()} ');
    }

    peripheralServices = peripheralServices
        .where((s) => s.uuid.toString() == serviceUUID)
        .toList();

    for (var service in peripheralServices) {
      cList = service.characteristics;
    }

    return await _isConnected(peripheral);
  }

  Future<Uint8List?> sendReceive(String? epName, Uint8List? data) async {
    if (data != null) {
      if (data.length > 0) {
        var c = cList.firstWhereOrNull((BluetoothCharacteristic c) =>
            c.uuid.toString() == nuLookup[epName ?? ""]);
        if (c != null) {
          await c.write(data, withoutResponse: false);
          var response = await c.read();
          // print('response: ${response.toString()}');
          return response.asUint8List();
        } else {
          throw Exception('No characteristic for $epName');
        }
      }
    }
    return null;
  }

  Future<void> disconnect() async {
    bool check = await _isConnected(peripheral);
    if (check) {
      return await peripheral.disconnect();
    } else {
      return;
    }
  }

  Future<bool> checkConnect() async {
    return await _isConnected(peripheral);
  }

  void dispose() {
    print('dispose ble');
  }
}
