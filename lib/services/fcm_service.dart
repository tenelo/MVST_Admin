import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mvst_admin/main.dart';
import 'package:mvst_admin/screens/suggestions_admin.dart';
import 'package:mvst_admin/services/api_client.dart';
import 'package:mvst_admin/services/auth_service.dart';

// Handler background : DOIT etre top-level + annote.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Rien de special ici : le systeme affiche deja la notif quand l'app est en
  // arriere-plan/fermee (payload notification). Point d'entree requis par FCM.
}

class FcmService {
  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _canal = AndroidNotificationChannel(
    'mvst_admin_canal',
    'Notifications MVST',
    description: 'Notifications de suggestions',
    importance: Importance.high,
  );

  static void _ouvrirSuggestions() {
    final nav = navigatorKeyAdmin.currentState;
    if (nav == null) return;
    nav.push(MaterialPageRoute(builder: (_) => const SuggestionsAdmin()));
  }

  // Init technique : permission, canal Android, handlers. A appeler dans main().
  static Future<void> initialiser() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await FirebaseMessaging.instance.requestPermission();

    await _localNotif.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_canal);

    // Avant-plan : afficher une notif locale (sinon rien ne s'affiche).
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notif = message.notification;
      if (notif != null) {
        _localNotif.show(
          notif.hashCode,
          notif.title,
          notif.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _canal.id,
              _canal.name,
              channelDescription: _canal.description,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // Tap sur notif quand l'app est en arriere-plan (pas fermee)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _ouvrirSuggestions();
    });

    // Tap sur notif quand l'app etait FERMEE (message initial au demarrage)
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      // Retarder pour laisser le navigatorKey s'attacher au 1er frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ouvrirSuggestions();
      });
    }
  }

  // Enregistre le token FCM du compte connecte. No-op si non connecte.
  static Future<void> enregistrerTokenSiConnecte() async {
    final id = AuthService.getUid();
    if (id == null || id.isEmpty) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      await ApiClient.instance.post(
        'device-tokens/enregistrer',
        body: {
          'type_compte': 'admin',
          'id_compte': id,
          'token': token,
          'plateforme': 'android',
        },
      );
    } catch (e) {
      // best-effort : ne jamais casser le demarrage / login sur une erreur FCM
    }
  }
}
