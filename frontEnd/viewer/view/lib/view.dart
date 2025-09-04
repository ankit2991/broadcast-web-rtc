import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ViewerScreen extends StatefulWidget {
  @override
  _ViewerScreenState createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  IO.Socket? socket;
  RTCPeerConnection? peerConnection;
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    initRenderer();
    connectSocket();
  }

  Future<void> initRenderer() async {
    await _remoteRenderer.initialize();
  }

  void connectSocket() {
    socket = IO.io("http://192.168.29.134:5000", <String, dynamic>{
      "transports": ["websocket"],
      "autoConnect": false,
    });

    socket!.connect();

    socket!.onConnect((_) {
      print("Connected as Viewer");
      socket!.emit("viewer");
    });

    // Broadcaster sends offer
    socket!.on("offer", (data) async {
      String broadcasterId = data["broadcasterId"];
      String sdpOffer = data["sdpOffer"];

      peerConnection = await createPeerConnection({"iceServers": []});

      peerConnection!.onTrack = (event) {
        if (event.streams.isNotEmpty) {
          _remoteRenderer.srcObject = event.streams[0];
          setState(() {});
        }
      };

      peerConnection!.onIceCandidate = (candidate) {
        if (candidate != null) {
          socket!.emit("iceCandidate", {
            "targetId": broadcasterId,
            "iceCandidate": {
              "candidate": candidate.candidate,
              "sdpMid": candidate.sdpMid,
              "sdpMLineIndex": candidate.sdpMLineIndex,
            },
          });
        }
      };

      await peerConnection!.setRemoteDescription(
        RTCSessionDescription(sdpOffer, "offer"),
      );

      var answer = await peerConnection!.createAnswer();
      await peerConnection!.setLocalDescription(answer);

      socket!.emit("answer", {
        "broadcasterId": broadcasterId,
        "sdpAnswer": answer.sdp,
      });
    });

    // Handle ICE from broadcaster
    socket!.on("iceCandidate", (data) async {
      var candidate = RTCIceCandidate(
        data["iceCandidate"]["candidate"],
        data["iceCandidate"]["sdpMid"],
        data["iceCandidate"]["sdpMLineIndex"],
      );
      await peerConnection?.addCandidate(candidate);
    });
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    socket?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Viewer")),
      body: Column(
        children: [
          RTCVideoView(_remoteRenderer, mirror: true),
          Container(height: 150, width: double.infinity, color: Colors.teal),
        ],
      ),
    );
  }
}
