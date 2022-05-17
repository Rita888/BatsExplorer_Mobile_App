import 'package:batsexplorer/models/sensor_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:batsexplorer/utils/customcolors.dart';
import 'package:intl/intl.dart';
import 'package:mqtt_client/mqtt_client.dart' as mqtt;
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:string_validator/string_validator.dart' as sV;

class GuideScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return GuideScreenState();
  }
}

class GuideScreenState extends State<GuideScreen> {
  List<SensorItem> _mqttSensors = <SensorItem>[];

  String broker = 'mqtt.cetools.org';
  int port = 1883;
  String clientIdentifier = 'ce-mqtt-mobile-app';
  // String clientIdentifier = '';

  mqtt.MqttClient? client;
  mqtt.MqttConnectionState? connectionState;

  String _topic = "UCL/QEOP/bats/bat5";

  StreamSubscription? subscription;

  bool _sensorInList = false;

  //late ProgressHUD _progressHUD;
  bool _loading = true;

  int dissmissView = 0;

  void _subscribeToTopic(String topic) {
    if (connectionState == mqtt.MqttConnectionState.connected) {
      print('[MQTT client] Subscribing to ' + broker + ':\t ${topic.trim()}');
      client!.subscribe(topic, mqtt.MqttQos.exactlyOnce);
    }
  }

  @override
  void initState() {
    super.initState();

    _populateSensorList();
  }

  @override
  void dispose() {
    print("MQTT Server View is Closed");
    dissmissView = 1;
    if (client!.connectionState == mqtt.MqttConnectionState.connected) {
      print('[MQTT client] Disconnecting from MQTT Server: ' + broker);
      _disconnect();
    }

    super.dispose();
  }

  void _populateSensorList() {
    _connect();
  }

  ListTile _buildItemsForListView(BuildContext context, int i) {
    return ListTile(
      leading: new CircleAvatar(child: Text("$i")),
      title: new Text("Device Name"),
      subtitle: new Text("Last Message: " +
          new DateFormat("dd-MM-yyyy HH:mm:ss")
              .format(_mqttSensors[i].lastMessage!)),
      trailing: Icon(Icons.keyboard_arrow_right,
          color: Color.fromRGBO(58, 66, 86, 1.0), size: 30.0),
      isThreeLine: true,
      onTap: () {
        // Navigator.pushNamed(context, MQTTDetail.routeName,
        //     arguments: _mqttSensors[i]);
      },
      onLongPress: () {
        print(
          Text("Long Pressed"),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
            decoration: BoxDecoration(
              color: CustomColors.backgroundColor,
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 50,
                  left: 10,
                  right: 0,
                  child: Align(
                      alignment: Alignment.topLeft,
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 100.0,
                        height: 100.0,
                        fit: BoxFit.contain,
                      )),
                ),
                Positioned(
                    top: 50,
                    bottom: 0,
                    left: 15,
                    right: 15,
                    child: Center(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        ListView.builder(
                          itemCount: _mqttSensors.length,
                          itemBuilder: _buildItemsForListView,
                          padding: EdgeInsets.all(8.0),
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                        ),
                      ],
                    ))),
              ],
            )),
      ),
    );
  }

  void dismissProgressHUD() {
    setState(() {
      // if (_loading) {
      //   _progressHUD.state.dismiss();
      // } else {
      //   _progressHUD.state.show();
      // }

      _loading = !_loading;
    });
  }

  void _connect() async {
    client = MqttServerClient(broker, '');
    client!.port = port;

    client!.logging(on: false);
    client!.keepAlivePeriod = 30;

    client!.onDisconnected = _onDisconnected;

    dissmissView = 0;

    final mqtt.MqttConnectMessage connMess = mqtt.MqttConnectMessage()
        .withClientIdentifier(clientIdentifier)
        .startClean() // Non persistent session for testing
        .keepAliveFor(30)
        .withWillQos(mqtt.MqttQos.atMostOnce);

    print('[MQTT client] MQTT client connecting....');

    client!.connectionMessage = connMess;

    try {
      await client!.connect();
    } catch (e) {
      print(e);
      dismissProgressHUD();
      _disconnect();
    }

    /// Check if we are connected
    if (client!.connectionState == mqtt.MqttConnectionState.connected) {
      print('[MQTT client] Connected to ' + broker);
      dismissProgressHUD();
      setState(() {
        connectionState = client!.connectionState;
      });
    } else {
      print('[MQTT client] ERROR: MQTT client connection failed - '
          'disconnecting, state is ${client!.connectionStatus}');

      _disconnect();
    }

    subscription = client!.updates!.listen(_onMessage);

    _subscribeToTopic(_topic);
  }

  void _disconnect() {
    print('[MQTT client] _disconnect()');
    client!.disconnect();
    _onDisconnected();
  }

  void _onDisconnected() {
    print('[MQTT client] _onDisconnected');

    if (dissmissView != 1) {
      setState(() {
        if (client != null) {
          connectionState = client!.connectionState;
        }
        client = null;
        if (subscription != null) {
          subscription!.cancel();
        }
        subscription = null;
      });
    } else {
      if (client != null) {
        connectionState = client!.connectionState;
      }

      client = null;
      if (subscription != null) {
        subscription!.cancel();
      }
      subscription = null;
    }

    print('[MQTT client] MQTT client disconnected');

    if (dissmissView != 1) {
      dismissProgressHUD();
      print("Disconnected from MQTT Server");
    }
  }

  void _onMessage(List<mqtt.MqttReceivedMessage> event) {
    final mqtt.MqttPublishMessage recMess =
        event[0].payload as mqtt.MqttPublishMessage;
    final String message =
        mqtt.MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

    SensorItem s = new SensorItem(event[0].topic);
    _sensorInList = false;

    Map? decodedJSON;

    try {
      if (!sV.isNumeric(message)) {
        //decodedJSON = jsonDecode(message);

      }
    } on Exception catch (e) {
      print('SJG: Message: $message');
      print(e.toString());
    }

    if (decodedJSON != null) {
      String? host = decodedJSON['host'];
      String? ip = decodedJSON['ip'];
      String? mac = decodedJSON['mac'];

      s.ip = ip!;
      s.host = host!;
      s.macAddress = mac!;

      for (var i = 0; i < _mqttSensors.length; i++) {
        if (_mqttSensors[i].macAddress == s.macAddress) {
          _sensorInList = true;
          setState(() {
            // _mqttSensors[i].updateLastMessage();
            // _mqttSensors[i].updateLastMessageJSON(message);
          });
        }
      }

      setState(() {
        //Check if Sensor is in the list
        if (!_sensorInList) {
          // s.updateLastMessage();
          // s.updateLastMessageJSON(message);
          _mqttSensors.insert(0, s);
        }
        _sensorInList = false;
      });
    }
  }
}
