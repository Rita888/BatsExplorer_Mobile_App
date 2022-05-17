
import 'dart:ui';
import 'package:batsexplorer/screens/guide_screen.dart';
import 'package:batsexplorer/screens/login_screen.dart';
import 'package:batsexplorer/screens/records_screen.dart';
import 'package:batsexplorer/utils/appstate.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:batsexplorer/screens/home_screen.dart';
import 'package:batsexplorer/utils/customcolors.dart';

class MainScreen extends StatefulWidget {
  final int index;
  MainScreen(this.index);

  @override
  State<StatefulWidget> createState() {
    return _MainScreenState();
  }
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {

  TabController? controller;

  var scaffoldKey = GlobalKey<ScaffoldState>();
  List<Widget>? screens ;
  Widget? currentScreen ;
  int _selectedIndex = 0;
  Widget selectedWidget= LoginScreen();

  void _onItemTapped(int index) {
    setState(() {
      if(index==2){
        if(AppState.isLogin){
          screens = [
            HomeScreen(),
            GuideScreen(),
            RecordsScreen(),
          ];
          selectedWidget=RecordsScreen();
        } else{
          screens = [
            HomeScreen(),
            GuideScreen(),
            LoginScreen(),
          ];
          // selectedWidget=LoginScreen();
        }
        _selectedIndex = index;
      } else {
        _selectedIndex = index;
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    AppState.synchronizeSettingsFromPhone().then((value) {
      if(AppState.isLogin){
        selectedWidget=RecordsScreen();
      } else{
        selectedWidget=LoginScreen();
      }



    });


    // screens = [
    //   HomeScreen(),
    //   GuideScreen(),
    //   LoginScreen(),
    // ];
    setState(() {
      if(AppState.isLogin){
        screens = [
          HomeScreen(),
          GuideScreen(),
          RecordsScreen(),
        ];
      } else{
        screens = [
          HomeScreen(),
          GuideScreen(),
          LoginScreen(),
        ];

      }

      _selectedIndex= widget.index;

    });
    controller = TabController(length: 3, vsync: this);
    controller!.animateTo(_selectedIndex, duration: Duration(seconds: 1), curve: Curves.easeOut);

  }

  @override
  void dispose() {
    // other dispose methods
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: scaffoldKey,
        resizeToAvoidBottomInset: false,

        body: Center(
            child:Container(
              width: double.infinity,
              height: double.infinity,

              child: screens?.elementAt(_selectedIndex),
            )),

        bottomNavigationBar:
        Container(

        decoration: const BoxDecoration(color: Colors.white),

        child: PreferredSize(
        preferredSize: Size(
        double.infinity, 50),
          child:TabBar(
          controller: controller,
          unselectedLabelColor: CustomColors.unselectedColor,
          labelColor: CustomColors.selectedColor,
          labelStyle: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),
          unselectedLabelStyle:  TextStyle(fontSize: 16,fontWeight: FontWeight.bold),
          onTap: (index) {_onItemTapped(index);},
          tabs:  [
            _individualTab('Home', 0),
            _individualTab('Guide', 1),
            _individualTab('Records', 2),
          ],
        )))
    );
  }

  Widget _individualTab(String title, int index) {
    return SizedBox(
      height: 40,
      child: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
            child: Tab(
              child:
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }


}
