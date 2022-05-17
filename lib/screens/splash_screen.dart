
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:liquid_progress_indicator/liquid_progress_indicator.dart';

import 'package:page_transition/page_transition.dart';
import 'package:batsexplorer/screens/main_screen.dart';
import 'package:batsexplorer/utils/appstate.dart';
import 'package:batsexplorer/utils/customcolors.dart';



class SplashScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return SplashScreenState();
  }
}

class SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
      loader();
    }

  Future<Timer> loader() async {
    return new Timer(Duration(seconds: 2), onDoneLoading);
  }

  onDoneLoading() async {
    Navigator.pushReplacement(context, PageTransition(type: PageTransitionType.rightToLeft, child: MainScreen(0)));
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
          child:
          Stack(children: [
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              right: 0,
              child: new Center(
                  child:
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Image.asset(
                        'assets/images/logo.png',
                        width: 250.0,
                        height: 250.0,
                        fit: BoxFit.scaleDown,
                      ),
                      SizedBox(height: 50,),
                      Container(
                        width: 200,
                        height: 100,
                        padding: EdgeInsets.fromLTRB(50, 0, 50, 0),
                        child: LiquidCircularProgressIndicator(
                          value: 0.75, // Defaults to 0.5.
                          valueColor: AlwaysStoppedAnimation(CustomColors.selectedColor), // Defaults to the current Theme's accentColor.
                          backgroundColor: CustomColors.backgroundColor, // Defaults to the current Theme's backgroundColor.
                          borderColor: Colors.white,
                          borderWidth: 1.0,
                          direction: Axis.vertical, // The direction the liquid moves (Axis.vertical = bottom to top, Axis.horizontal = left to right). Defaults to Axis.vertical.
                          center: Text("Loading...",style: TextStyle(color: Colors.white),),
                        ),
                      )

                    ],)

              ),

            ),

          ],)

        ),
      ),
    );
  }

}