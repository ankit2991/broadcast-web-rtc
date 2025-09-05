// import 'package:flutter/material.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:socket_io_client/socket_io_client.dart' as IO;

// class AllbroadcasterScreen extends StatefulWidget {
//   @override
//   _AllbroadcasterScreenState createState() => _AllbroadcasterScreenState();
// }

// class _AllbroadcasterScreenState extends State<AllbroadcasterScreen> {
//   IO.Socket? socket;
//   RTCPeerConnection? peerConnection;
//   final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

//   @override
//   void initState() {
//     super.initState();
//     initRenderer();
//     connectSocket();
//   }

//   Future<void> initRenderer() async {
//     await _remoteRenderer.initialize();
//   }

//   void connectSocket() {
//     socket = IO.io("https://demo.syspaisa.com/", <String, dynamic>{
//       "transports": ["websocket"],
//       "autoConnect": false,
//     });

//     socket!.connect();

//     socket!.onConnect((_) {
//       print("Connected as Allbroadcaster");
//       socket!.emit("Allbroadcaster");
//     });

//     // Broadcaster sends offer
//     socket!.on("offer", (data) async {
//       String broadcasterId = data["broadcasterId"];
//       String sdpOffer = data["sdpOffer"];

//       peerConnection = await createPeerConnection({"iceServers": []});

//       peerConnection!.onTrack = (event) {
//         if (event.streams.isNotEmpty) {
//           _remoteRenderer.srcObject = event.streams[0];
//           setState(() {});
//         }
//       };

//       peerConnection!.onIceCandidate = (candidate) {
//         if (candidate != null) {
//           socket!.emit("iceCandidate", {
//             "targetId": broadcasterId,
//             "iceCandidate": {
//               "candidate": candidate.candidate,
//               "sdpMid": candidate.sdpMid,
//               "sdpMLineIndex": candidate.sdpMLineIndex,
//             },
//           });
//         }
//       };

//       await peerConnection!.setRemoteDescription(
//         RTCSessionDescription(sdpOffer, "offer"),
//       );

//       var answer = await peerConnection!.createAnswer();
//       await peerConnection!.setLocalDescription(answer);

//       socket!.emit("answer", {
//         "broadcasterId": broadcasterId,
//         "sdpAnswer": answer.sdp,
//       });
//     });

//     // Handle ICE from broadcaster
//     socket!.on("iceCandidate", (data) async {
//       var candidate = RTCIceCandidate(
//         data["iceCandidate"]["candidate"],
//         data["iceCandidate"]["sdpMid"],
//         data["iceCandidate"]["sdpMLineIndex"],
//       );
//       await peerConnection?.addCandidate(candidate);
//     });
//   }

//   @override
//   void dispose() {
//     _remoteRenderer.dispose();
//     socket?.disconnect();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Allbroadcaster")),
//       body: RTCVideoView(_remoteRenderer, mirror: true),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:view/view.dart';

class Allbroadcaster extends StatefulWidget {
  const Allbroadcaster({super.key});

  @override
  State<Allbroadcaster> createState() => _AllbroadcasterState();
}

class _AllbroadcasterState extends State<Allbroadcaster> {
  late IO.Socket socket;
  List<dynamic> allBroadcasters = [];
  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  // final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  // final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    // _localRenderer.initialize();
    // _remoteRenderer.initialize();
    connectSocket();
  }

  @override
  void dispose() {
    // _localRenderer.dispose();
    // _remoteRenderer.dispose();
    peerConnection?.close();
    localStream?.dispose();
    socket.disconnect();
    super.dispose();
  }

  // ✅ Connect socket
  void connectSocket() {
    socket = IO.io("http://192.168.29.134:500/", <String, dynamic>{
      "transports": ["websocket"],
      "autoConnect": true,
    });

    socket.onConnect((_) async {
      print("Connected to backend");

      // Allbroadcaster join room
      // socket.emit("Allbroadcaster", widget.roomId);
      // await joinBroadcast();

      socket.on("broadcasterDisconnected", (data) {
        String roomId = data["roomId"];
        setState(() {
          // socket.emit("getBroadcasters");
        });
      });
      socket.on("broadcastersList", (data) {
        setState(() {
          allBroadcasters = List<dynamic>.from(data);
        });

        if (allBroadcasters.isNotEmpty) {
          // Auto-join the first broadcaster
          socket.emit("viewer", allBroadcasters.first[0]); // roomId
        }
      });
    });

    // incoming offer for Allbroadcaster
    socket.on("offer", (data) async {
      print("Received offer: $data");
      var description = RTCSessionDescription(
        data["sdpOffer"]["sdp"],
        data["sdpOffer"]["type"],
      );
      peerConnection = await createPeerConnection({
        "iceServers": [
          {"urls": "stun:stun.l.google.com:19302"},
        ],
      });
      await peerConnection?.setRemoteDescription(description);

      RTCSessionDescription answer = await peerConnection!.createAnswer();
      await peerConnection!.setLocalDescription(answer);

      socket.emit("answer", {
        "broadcasterId": data["broadcasterId"],
        "sdpAnswer": {"sdp": answer.sdp, "type": answer.type},
      });
    });

    // incoming answer for broadcaster
    socket.on("answer", (data) async {
      print("Received answer: $data");
      var description = RTCSessionDescription(
        data["sdpAnswer"]["sdp"],
        data["sdpAnswer"]["type"],
      );
      await peerConnection?.setRemoteDescription(description);
    });

    // ICE candidate exchange
    socket.on("iceCandidate", (data) async {
      print("Received ICE: $data");
      await peerConnection?.addCandidate(
        RTCIceCandidate(
          data["iceCandidate"]["candidate"],
          data["iceCandidate"]["sdpMid"],
          data["iceCandidate"]["sdpMLineIndex"],
        ),
      );
    });
  }
  // ✅ Allbroadcaster join
  // Future<void> joinBroadcast() async {
  //   peerConnection = await createPeerConnection({
  //     "iceServers": [
  //       {"urls": "stun:stun.l.google.com:19302"},
  //     ],
  //   });

  //   peerConnection?.onTrack = (event) {
  //     if (event.streams.isNotEmpty) {
  //       _remoteRenderer.srcObject = event.streams[0];
  //       setState(() {});
  //     }
  //   };

  //   peerConnection?.onIceCandidate = (candidate) {
  //     socket.emit("iceCandidate", {
  //       "targetId": widget.roomId, // broadcaster
  //       "iceCandidate": {
  //         "candidate": candidate.candidate,
  //         "sdpMid": candidate.sdpMid,
  //         "sdpMLineIndex": candidate.sdpMLineIndex,
  //       },
  //     });
  //   };
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Allbroadcaster")),
      body: GridView.builder(
        shrinkWrap: true,
        itemCount: allBroadcasters.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      Viewer(roomId: allBroadcasters[index][0]),
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.all(10),
              color: Colors.amber,
              child: Text(allBroadcasters[index][0]),
            ),
          );
        },
      ),
    );
  }
}
