import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class BroadcastScreen extends StatefulWidget {
  final String roomId;

  const BroadcastScreen({super.key, required this.roomId});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  late IO.Socket socket;
  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  // final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _localRenderer.initialize();
    // _remoteRenderer.initialize();
    connectSocket();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
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

      // broadcaster join room
      socket.emit("broadcaster", widget.roomId);
      await startBroadcast();
      setState(() {});
    });

    // incoming offer for viewer
    socket.on("offer", (data) async {
      print("Received offer: $data");
      var description = RTCSessionDescription(
        data["sdpOffer"]["sdp"],
        data["sdpOffer"]["type"],
      );
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

  // ✅ Broadcaster start
  Future<void> startBroadcast() async {
    peerConnection = await createPeerConnection({
      "iceServers": [
        {"urls": "stun:stun.l.google.com:19302"},
      ],
    });

    localStream = await navigator.mediaDevices.getUserMedia({
      "video": true,
      "audio": true,
    });

    _localRenderer.srcObject = localStream;

    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    peerConnection?.onIceCandidate = (candidate) {
      socket.emit("iceCandidate", {
        "targetId": widget.roomId, // viewers listening
        "iceCandidate": {
          "candidate": candidate.candidate,
          "sdpMid": candidate.sdpMid,
          "sdpMLineIndex": candidate.sdpMLineIndex,
        },
      });
    };

    // when viewer joins
    socket.on("viewer", (viewerId) async {
      print("New viewer: $viewerId");

      RTCSessionDescription offer = await peerConnection!.createOffer();
      await peerConnection!.setLocalDescription(offer);

      socket.emit("offer", {
        "viewerId": viewerId,
        "sdpOffer": {"sdp": offer.sdp, "type": offer.type},
      });
    });
  }

  // ✅ Viewer join
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
      appBar: AppBar(title: Text("Broadcaster")),
      body: Column(
        children: [Expanded(child: RTCVideoView(_localRenderer, mirror: true))],
      ),
    );
  }
}
