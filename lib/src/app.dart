import 'package:flutter/material.dart';
import 'package:handleliste/src/shopping_list_creation_view/shopping_list_creation_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:easy_dynamic_theme/easy_dynamic_theme.dart';

import 'shoppinglist/shopping_list_view.dart';
import 'signinscreen/signinscreen.dart';
import 'settings/settings_controller.dart';

/// The Widget that configures your application.
class MyApp extends StatelessWidget {
  final SettingsController settingsController;

  const MyApp({super.key, required this.settingsController});

  Future<bool> _isUserLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  Future<String?> _getShoppingListId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('shoppingListId');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          restorationScopeId: 'app',
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English, no country code
          ],
          onGenerateTitle: (BuildContext context) =>
              AppLocalizations.of(context)!.appTitle,
          theme: ThemeData(),
          darkTheme: ThemeData.dark(),
          themeMode: EasyDynamicTheme.of(context)
              .themeMode, //settingsController.themeMode,
          onGenerateRoute: (RouteSettings routeSettings) {
            return MaterialPageRoute<void>(
              settings: routeSettings,
              builder: (BuildContext context) {
                // Add your route handling logic here
                // If none of your conditions are met, return a default widget
                return Container();
              },
            );
          },
          home: FutureBuilder<bool>(
            future: _isUserLoggedIn(),
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else {
                if (snapshot.data != null && snapshot.data!) {
                  return FutureBuilder<String?>(
                    future: _getShoppingListId(),
                    builder: (BuildContext context,
                        AsyncSnapshot<String?> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else {
                        if (snapshot.data != null) {
                          return ShoppingListView(listId: snapshot.data!);
                        } else {
                          return const ShoppingListCreationView();
                        }
                      }
                    },
                  );
                } else {
                  return const SignInScreen();
                }
              }
            },
          ),
        );
      },
    );
  }
}
