import 'package:broadcaster/idScreen.dart';
import 'package:broadcaster/multi.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: Idscreen(),
      // home: BroadcasterScreen()
    );
  }
}

// class home extends StatelessWidget {
//   const home({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           ElevatedButton(
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => Idscreen(isBroadcaster: true),
//                 ),
//               );
//             },
//             child: Text("Start BroadCast"),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => Idscreen(isBroadcaster: false),
//                 ),
//               );
//             },
//             child: Text("Join BroadCast"),
//           ),
//         ],
//       ),
//     );
//   }
// }
