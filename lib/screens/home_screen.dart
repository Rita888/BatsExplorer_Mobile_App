import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'package:page_transition/page_transition.dart';

import 'package:batsexplorer/utils/customcolors.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return HomeScreenState();
  }
}

class HomeScreenState extends State<HomeScreen> {
  static final String mqttServer = "mqtt.cetools.org";
//  static final String mqttTopic="UCL/QEOP/bats/bat5";
  static final String mqttTopic = "student/CASA0014/plant/ucfnaka";

  final client = MqttServerClient.withPort(mqttServer, '', 1883);
  var pongCount = 0;
  @override
  void initState() {
    super.initState();
    // initMqtt();
    // connect();
  }

  Future<MqttServerClient> connect() async {
    MqttServerClient client = MqttServerClient.withPort(mqttServer, '', 1883);
    client.logging(on: true);
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    // client.onUnsubscribed = ;
    client.onSubscribed = onSubscribed;
    // client.onSubscribeFail = onSubscribeFail;
    client.pongCallback = pong;

    final connMessage = MqttConnectMessage()
        // .authenticateAs('username', 'password')
        .keepAliveFor(60)
        .withWillTopic('willtopic')
        .withWillMessage('Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;
    try {
      await client.connect();
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
    }

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      /// The above may seem a little convoluted for users only interested in the
      /// payload, some users however may be interested in the received publish message,
      /// lets not constrain ourselves yet until the package has been in the wild
      /// for a while.
      /// The payload is a byte buffer, this will be specific to the topic
      print(
          'EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
      print('');
    });

    return client;
  }

  Future<void> initMqtt() async {
    client.logging(on: false);

    /// Set the correct MQTT protocol for mosquito
    client.setProtocolV311();

    /// If you intend to use a keep alive you must set it here otherwise keep alive will be disabled.
    client.keepAlivePeriod = 20;

    /// Add the unsolicited disconnection callback
    client.onDisconnected = onDisconnected;

    /// Add the successful connection callback
    client.onConnected = onConnected;

    /// Add a subscribed callback, there is also an unsubscribed callback if you need it.
    /// You can add these before connection or change them dynamically after connection if
    /// you wish. There is also an onSubscribeFail callback for failed subscriptions, these
    /// can fail either because you have tried to subscribe to an invalid topic or the broker
    /// rejects the subscribe request.
    client.onSubscribed = onSubscribed;

    /// Set a ping received callback if needed, called whenever a ping response(pong) is received
    /// from the broker.
    client.pongCallback = pong;

    final connMess = MqttConnectMessage()
        .withClientIdentifier('')
        .withWillTopic(
            'willtopic') // If you set this you must set a will message
        .withWillMessage('My Will message')
        .startClean() // Non persistent session for testing
        .withWillQos(MqttQos.atLeastOnce);
    print('EXAMPLE::Mosquitto client connecting....');
    client.connectionMessage = connMess;

    try {
      await client.connect();
    } on NoConnectionException catch (e) {
      // Raised by the client when connection fails.
      print('EXAMPLE::client exception - $e');
      client.disconnect();
    } on SocketException catch (e) {
      // Raised by the socket layer
      print('EXAMPLE::socket exception - $e');
      client.disconnect();
    }
    try {
      /// Check we are connected
      if (client.connectionStatus!.state == MqttConnectionState.connected) {
        print('EXAMPLE::Mosquitto client connected');
      } else {
        /// Use status here rather than state if you also want the broker return code.
        print(
            'EXAMPLE::ERROR Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}');
        client.disconnect();
        exit(-1);
      }

      /// Ok, lets try a subscription
      print('EXAMPLE::Subscribing to the topic');
      client.subscribe(mqttTopic, MqttQos.atMostOnce);

      /// The client has a change notifier object(see the Observable class) which we then listen to to get
      /// notifications of published updates to each subscribed topic.
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
        final recMess = c![0].payload as MqttPublishMessage;
        final pt =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

        /// The above may seem a little convoluted for users only interested in the
        /// payload, some users however may be interested in the received publish message,
        /// lets not constrain ourselves yet until the package has been in the wild
        /// for a while.
        /// The payload is a byte buffer, this will be specific to the topic
        print(
            'EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
        print('');
      });

      /// If needed you can listen for published messages that have completed the publishing
      /// handshake which is Qos dependant. Any message received on this stream has completed its
      /// publishing handshake with the broker.
      client.published!.listen((MqttPublishMessage message) {
        print(
            'EXAMPLE::Published notification:: topic is ${message.variableHeader!.topicName}, with Qos ${message.header!.qos}');
      });

      // const pubTopic = 'Dart/Mqtt_client/testtopic';
      // final builder = MqttClientPayloadBuilder();
      // builder.addString('Hello from mqtt_client');
      //
      // /// Subscribe to it
      // print('EXAMPLE::Subscribing to the Dart/Mqtt_client/testtopic topic');
      // client.subscribe(pubTopic, MqttQos.exactlyOnce);

      /// Publish it
      // print('EXAMPLE::Publishing our topic');
      // client.publishMessage(pubTopic, MqttQos.exactlyOnce, builder.payload!);

      /// Ok, we will now sleep a while, in this gap you will see ping request/response
      /// messages being exchanged by the keep alive mechanism.
      print('EXAMPLE::Sleeping....');
      await MqttUtilities.asyncSleep(60);

      /// Finally, unsubscribe and exit gracefully
      print('EXAMPLE::Unsubscribing');
      client.unsubscribe(mqttTopic);

      /// Wait for the unsubscribe message from the broker if you wish.
      await MqttUtilities.asyncSleep(2);
      print('EXAMPLE::Disconnecting');
      client.disconnect();
      print('EXAMPLE::Exiting normally');
    } catch (ex) {
      debugPrint(ex.toString());
    }
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
                  right: 10,
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
                    top: 0,
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            "Welcome To Bats Explorer".toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 32,
                                color: CustomColors.textHeadColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(height: 30),
                      ],
                    ))),
              ],
            )),
      ),
    );
  }

  void onSubscribed(String topic) {
    print('EXAMPLE::Subscription confirmed for topic $topic');
  }

  /// The unsolicited disconnect callback
  void onDisconnected() {
    print('EXAMPLE::OnDisconnected client callback - Client disconnection');
    if (client.connectionStatus!.disconnectionOrigin ==
        MqttDisconnectionOrigin.solicited) {
      print('EXAMPLE::OnDisconnected callback is solicited, this is correct');
    } else {
      print(
          'EXAMPLE::OnDisconnected callback is unsolicited or none, this is incorrect - exiting');
      exit(-1);
    }
    if (pongCount == 3) {
      print('EXAMPLE:: Pong count is correct');
    } else {
      print('EXAMPLE:: Pong count is incorrect, expected 3. actual $pongCount');
    }
  }

  /// The successful connect callback
  void onConnected() {
    print(
        'EXAMPLE::OnConnected client callback - Client connection was successful');
  }

  /// Pong callback
  void pong() {
    print('EXAMPLE::Ping response client callback invoked');
    pongCount++;
  }
}
