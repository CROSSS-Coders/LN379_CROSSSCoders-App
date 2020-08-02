import 'dart:math';
import 'dart:typed_data';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:overlay_support/overlay_support.dart';

import 'utils/constants.dart';
import 'views/home/home.dart';
import './models/dam.dart';
import './views/auth/index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  bool registered = await initHive();
  runApp(SIHNotifier(registered: registered));
}

Future<bool> initHive() async {
  Hive.registerAdapter(DamInfoAdapter());
  await Hive.openBox('user');
  await Hive.openBox('notification_dams');
  await Hive.openBox('chart_dams');
<<<<<<< HEAD
  await Hive.openBox('iot_dam');
=======
>>>>>>> d11398eb6b0e53dd69d06a294103fd692515a427
  await Hive.openBox('peers');
  bool registered = Hive.box('user').containsKey('id');
  return registered;
}

<<<<<<< HEAD
class SIHNotifier extends StatelessWidget {
=======
class SIHNotifier extends StatefulWidget {
>>>>>>> d11398eb6b0e53dd69d06a294103fd692515a427
  final bool registered;

  SIHNotifier({this.registered});

  @override
<<<<<<< HEAD
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Roboto',
        backgroundColor: kBlue,
        primaryColor: kBlue,
        accentColor: kBlue,
      ),
      title: 'JalPravah',
      home: registered ? Home() : Authentication(),
      // home: NearbyService(),
=======
  _SIHNotifierState createState() => _SIHNotifierState();
}

class _SIHNotifierState extends State<SIHNotifier> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final String userID = Random().nextInt(10000).toString();
  final Strategy strategy = Strategy.P2P_CLUSTER;
  Box peers = Hive.box('peers');

  static Future<dynamic> backgroundMessageHandler(
      Map<String, dynamic> message) async {
    print(message.toString());
    showSimpleNotification(
      Text(message['notification']['title']),
      background: kRed,
      contentPadding: EdgeInsets.all(5),
      elevation: 5,
      subtitle: Text(message['notification']['body']),
    );
  }

  void startAdvertising() async {
    try {
      bool adv = await Nearby().startAdvertising(
        userID,
        strategy,
        onConnectionInitiated: (id, info) async {
          acceptConnection(id);
        },
        onConnectionResult: (id, status) {
          print(status);
          if (status == Status.CONNECTED) {
            print('$userID: Connected to $id');
            peers.put(id, id);
          }
        },
        onDisconnected: (id) {
          peers.delete(id);
          print('$userID: Disconnected from $id');
        },
      );
      print('ADVERTISING ${adv.toString()}');
    } catch (e) {
      print(e);
    }
  }

  void startDiscovery() async {
    try {
      bool dis = await Nearby().startDiscovery(userID, strategy,
          onEndpointFound: (id, name, serviceId) async {
        print(id);
        Nearby().requestConnection(
          userID,
          id,
          onConnectionInitiated: (id, info) async {
            acceptConnection(id);
          },
          onConnectionResult: (id, status) {
            print(status);
            if (status == Status.CONNECTED) {
              peers.put(id, id);
              print('$userID: Connected to $id');
            }
          },
          onDisconnected: (id) {
            peers.delete(id);
            print('$userID: Disconnected to $id');
          },
        );
      }, onEndpointLost: (id) {
        print("Lost: " + id);
      });
      print('DISCOVERING: ${dis.toString()}');
    } catch (e) {
      print(e);
    }
  }

  void acceptConnection(id) async {
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endid, payload) async {
        String str = String.fromCharCodes(payload.bytes);
        if (str == 'WARNING') {
          showSimpleNotification(
            Text('WARNING'),
            background: kRed,
            contentPadding: EdgeInsets.all(5),
            elevation: 5,
            subtitle: Text('Possible flood in your area'),
          );
        }
      },
    );
  }

  void _sendData() async {
    String warning = 'WARNING';
    for (var peer in peers.values) {
      Nearby().sendBytesPayload(peer, Uint8List.fromList(warning.codeUnits));
    }
  }

  @override
  void initState() {
    Nearby().askLocationAndExternalStoragePermission();
    startAdvertising();
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: " + message.toString());
        showSimpleNotification(
          Text(message['notification']['title']),
          background: kRed,
          contentPadding: EdgeInsets.all(5),
          elevation: 5,
          subtitle: Text(message['notification']['body']),
        );
        _sendData();
      },
      onBackgroundMessage: backgroundMessageHandler,
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: " + message.toString());
        showSimpleNotification(
          Text(message['notification']['title']),
          background: kRed,
          contentPadding: EdgeInsets.all(5),
          elevation: 5,
          subtitle: Text(message['notification']['body']),
        );
        _sendData();
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: " + message.toString());
        showSimpleNotification(
          Text(message['notification']['title']),
          background: kRed,
          contentPadding: EdgeInsets.all(5),
          elevation: 5,
          subtitle: Text(message['notification']['body']),
        );
        _sendData();
      },
    );
    _firebaseMessaging.requestNotificationPermissions(
      const IosNotificationSettings(
        sound: true,
        badge: true,
        alert: true,
        provisional: true,
      ),
    );
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
    _firebaseMessaging.getToken().then((String token) {
      assert(token != null);
      print(token);
      Hive.box('user').put('fcmToken', token);
    });
    startDiscovery();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return OverlaySupport(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          fontFamily: 'Roboto',
          backgroundColor: kBlue,
          primaryColor: kBlue,
          accentColor: kBlue,
        ),
        title: 'JalPravah',
        home: widget.registered ? Home() : Authentication(),
        // home: NearbyService(),
      ),
>>>>>>> d11398eb6b0e53dd69d06a294103fd692515a427
    );
  }
}