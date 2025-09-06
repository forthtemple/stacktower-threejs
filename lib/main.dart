
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'StackTowerPage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb&&(Platform.isLinux||Platform.isWindows||Platform.isMacOS)) {

    await WindowManager.instance.ensureInitialized();
    windowManager.waitUntilReadyToShow().then((_) async {

      await windowManager.setTitle(gamename);

      final screens = PlatformDispatcher.instance.displays;
      final fSize = screens.first.size;

      await windowManager.setSize(Size(  900,900));

      await windowManager.setAlignment(Alignment.center);

    });
  }
  runApp(const MyApp());
}
class MyApp extends StatefulWidget{
  const MyApp({super.key,}) ;
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  String onPage = '';
  double pageLocation = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: gamename,
      //  theme: CSS.darkTheme,
        home: Scaffold(
          appBar:null,
          body: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: gamename,
           // theme: CSS.darkTheme,
              theme:ThemeData(
              textTheme: Theme.of(context).textTheme.apply(
                //    fontFamily: 'NanumMyeongjo',
                bodyColor: Colors.white,
                fontSizeFactor: 1.1,
                fontSizeDelta: 2.0,
              )),
              home: StackTowerSplashPage()

          ),
        )
      )
    );
  }
}


class StackTowerSplashPage extends StatefulWidget {
  const StackTowerSplashPage({super.key});

  @override
  State<StackTowerSplashPage> createState() => _StackTowerSplashPageState();
}


class _StackTowerSplashPageState extends State<StackTowerSplashPage> {//}with WidgetsBindingObserver{
  void start() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => StackTowerPage()), //JPage(groups: groups)),
    );
  }

  @override
  Widget build(BuildContext context) {
    /* SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);*/

    return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("icons/stacktower.jpg"),
            fit: BoxFit.cover,
          ),
        ),child:Scaffold(
      backgroundColor: Colors.transparent,

      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[

            Container(
                decoration: BoxDecoration(
                  border: Border.all(width: 1 ,color: Colors.white),//transparent), //color is transparent so that it does not blend with the actual color specified
                  borderRadius: const BorderRadius.all(const Radius.circular(6.0)),
                  color: Colors.black,//.withOpacity(0.5) // Specifies the background color and the opacity
                ),
                child: Padding(padding:EdgeInsets.only(left:10,top:0,right:10,bottom:0),
                    child:Text(gamename, style:TextStyle(fontSize:30, color:Colors.white, fontWeight: FontWeight.bold)))),
            SizedBox(height:20),
            //(0xfffffd6d)
            Container(
                decoration: BoxDecoration(
                  border: Border.all(width: 1 ,color: Colors.transparent), //color is transparent so that it does not blend with the actual color specified
                  borderRadius: const BorderRadius.all(const Radius.circular(30.0)),
                  gradient: LinearGradient(
                      colors: [
                        Colors.orange.withOpacity(0.5),//Color(0xFF3366FF),
                        Colors.yellow,//Color(0xFF00CCFF),
                      ],
                      begin: const FractionalOffset(0.0, 0.0),
                      end: const FractionalOffset(0.5, 0.5),
                      stops: [0.0, 1],
                      //   tileMode: TileMode.clamp),
                      tileMode: TileMode.mirror),

                ),

                child: Padding(padding:EdgeInsets.only(left:20,top:20,right:20,bottom:10),
                    child: Column(
                        children:[Container(padding:EdgeInsets.all(15),
                            decoration: BoxDecoration(
                                border: Border.all(width: 1 ,color: Colors.transparent), //color is transparent so that it does not blend with the actual color specified
                                borderRadius: const BorderRadius.all(const Radius.circular(10.0)),
                                color: Colors.black//.withOpacity(0.2) // Specifies the background color and the opacity
                            ),
                            child:Text("Make a tower as tall as you can.\n"+
                                "Press 'Start' to begin and then press space \n"+
                                "to send the block down to the foundation stone.\n"
                                , textAlign: TextAlign.center,
                                style:TextStyle(fontSize:17, color:Colors.white,fontWeight: FontWeight.bold))),
                          SizedBox(height:20),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor:Colors.black,
                                side: BorderSide(
                                  width: 3.0,
                                  color: Colors.white,
                                ),),
                              onPressed: () {
                                start();
                              },
                              //Color(0xff926b01)
                              child: Text("Start", style:TextStyle(fontSize:20, color:Colors.white,fontWeight: FontWeight.bold)))
                        ]))),

          ],
        ),
      ),
    )
    );
  }
}



