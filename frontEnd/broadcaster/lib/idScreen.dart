import 'package:broadcaster/multi.dart';
import 'package:flutter/material.dart';

TextEditingController idcon = TextEditingController();

class Idscreen extends StatelessWidget {
  Idscreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextFormField(
            decoration: InputDecoration(labelText: "Id"),
            controller: idcon,
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BroadcastScreen(roomId: idcon.text),
                ),
              );
            },
            child: Text("join"),
          ),
        ],
      ),
    );
  }
}
