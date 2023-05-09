import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

void main() => runApp(const BluetoothApp(color: Colors.blue));

@pragma('vm:entry-point')
void bluetoothView() => runApp(const BluetoothApp(color: Colors.blue));

class BluetoothDevice {
  final String? name;
  final String address;

  final bool connected = false;

  const BluetoothDevice({
    this.name,
    required this.address,
  });

  /// Creates `BluetoothDevice` from json.
  /// Used to create the object from platform code.
  factory BluetoothDevice.fromJson(Map<dynamic, dynamic> parsedJson) {
    return BluetoothDevice(
      name: parsedJson['name'] as String,
      address: parsedJson['address'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        "name": name,
        "address": address,
      };

  operator ==(Object other) {
    return other is BluetoothDevice && other.address == address;
  }

  @override
  int get hashCode => address.hashCode;
}

class BluetoothApp extends StatelessWidget {
  const BluetoothApp({super.key, required this.color});
  final MaterialColor color;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter + NativeScript Bluetooth',
      theme: ThemeData(
        colorSchemeSeed: color,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 8,
        ),
      ),
      home: const BluetoothPage(title: 'Flutter + NativeScript Bluetooth'),
    );
  }
}

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key, required this.title});

  final String title;

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  static const platform = BasicMessageChannel('nativescript', StringCodec());

  bool _scanning = false;
  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice? _device;

  _BluetoothPageState() {
    platform.setMessageHandler((String? message) async {
      print('Received: $message');

      Map<String, dynamic> platformMessage = jsonDecode(message!);
      switch (platformMessage['type']) {
        case 'scanResults':
          List<BluetoothDevice> devices = platformMessage['data']
              .map<BluetoothDevice>((i) => BluetoothDevice.fromJson(i))
              .toList();
          print("scanResults...$devices");
          updateDevices(devices);
          break;
      }

      return 'success';
    });
  }

  void updateDevices(List<BluetoothDevice> devices) {
    setState(() {
      _devicesList = devices;
      if (_devicesList.isNotEmpty) {
        _device ??= _devicesList[0];
      }
    });
  }

  void stopScanning() {
    Map<String, dynamic> message = {'type': 'stopScanning'};
    platform.send(jsonEncode(message));
    setState(() {
      _scanning = false;
    });
  }

  void startScanning() {
    // List<BluetoothDevice> devices = [];
    Map<String, dynamic> message = {'type': 'startScanning'};
    platform.send(jsonEncode(message));
    setState(() {
      _scanning = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.lightBlue.shade100,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light
        ),
      ),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.max, children: <Widget>[
          Visibility(
            visible: _scanning,
            child: const LinearProgressIndicator(
              backgroundColor: Colors.yellow,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            ),
          ),
          Expanded(
              child: ListView(
                  padding: EdgeInsets.zero,
                  children: _devicesList.isEmpty
                      ? [
                          const ListTile(
                              title:
                                  Text('No devices found yet, try scanning.'))
                        ]
                      : _devicesList.map((d) {
                          return ListTile(
                            title: Text(d.name!,
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20)),
                            subtitle: Text(d.address,
                                style: const TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.normal,
                                    fontSize: 15)),
                            trailing: TextButton(
                              child: const Text('Connect'),
                              onPressed: () {
                                // could connect to peripheral here
                              },
                            ),
                          );
                        }).toList()))
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scanning ? stopScanning : startScanning,
        tooltip: _scanning ? 'Stop scanning' : 'Start Scanning',
        child: _scanning
            ? const Icon(Icons.settings_input_antenna)
            : const Icon(Icons.network_check),
      ),
    );
  }
}
