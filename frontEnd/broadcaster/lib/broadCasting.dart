import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class BroadcasterScreen extends StatefulWidget {
  @override
  _BroadcasterScreenState createState() => _BroadcasterScreenState();
}

class _BroadcasterScreenState extends State<BroadcasterScreen> {
  IO.Socket? socket;
  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  Map<String, RTCPeerConnection> viewers = {};

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  bool isFrontCameraSelected = true;
  @override
  void initState() {
    super.initState();
    requestPermissions().then((value) {
      if (value) {
        initRenderer();
        connectSocket();
        startStream();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("give the permission")));
      }
    });
  }

  _switchCamera() {
    // change status
    isFrontCameraSelected = !isFrontCameraSelected;

    // switch camera
    localStream?.getVideoTracks().forEach((track) {
      // ignore: deprecated_member_use
      track.switchCamera();
    });
    setState(() {});
  }

  Future<void> initRenderer() async {
    await _localRenderer.initialize();
  }

  Future<bool> requestPermissions() async {
    var camera = await Permission.camera.request();
    var mic = await Permission.microphone.request();

    return camera.isGranted && mic.isGranted;
  }

  void connectSocket() {
    socket = IO.io("http://demo.syspaisa.com/", <String, dynamic>{
      "transports": ["websocket"],
      "autoConnect": false,
    });

    socket!.connect();

    socket!.onConnect((_) {
      print("Connected as Broadcaster");
      socket!.emit("broadcaster");
    });

    // When a new viewer joins
    socket!.on("viewer", (viewerId) async {
      print("Viewer joined: $viewerId");
      await createOfferForViewer(viewerId);
    });

    // When viewer sends answer
    socket!.on("answer", (data) async {
      String viewerId = data["viewerId"];
      String sdpAnswer = data["sdpAnswer"];
      var desc = RTCSessionDescription(sdpAnswer, "answer");
      await viewers[viewerId]?.setRemoteDescription(desc);
    });

    // Handle ICE from viewer
    socket!.on("iceCandidate", (data) async {
      String senderId = data["senderId"];
      var candidate = RTCIceCandidate(
        data["iceCandidate"]["candidate"],
        data["iceCandidate"]["sdpMid"],
        data["iceCandidate"]["sdpMLineIndex"],
      );
      await viewers[senderId]?.addCandidate(candidate);
    });
  }

  Future<void> startStream() async {
    final stream = await navigator.mediaDevices.getUserMedia({
      "video": {
        'facingMode': isFrontCameraSelected ? 'user' : 'environment',
        "width": {"ideal": 1280}, // request HD
        "height": {"ideal": 720},
        "frameRate": {"ideal": 30}, // smoother video
      },
      // "video": true,
      "audio": true,
    });
    _localRenderer.srcObject = stream;
    localStream = stream;
    setState(() {});
  }

  Future<void> createOfferForViewer(String viewerId) async {
    final pc = await createPeerConnection({"iceServers": []});
    localStream?.getTracks().forEach((track) {
      pc.addTrack(track, localStream!);
    });

    pc.onIceCandidate = (candidate) {
      if (candidate != null) {
        socket!.emit("iceCandidate", {
          "targetId": viewerId,
          "iceCandidate": {
            "candidate": candidate.candidate,
            "sdpMid": candidate.sdpMid,
            "sdpMLineIndex": candidate.sdpMLineIndex,
          },
        });
      }
    };

    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    viewers[viewerId] = pc;

    socket!.emit("offer", {"viewerId": viewerId, "sdpOffer": offer.sdp});
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    socket?.disconnect();
    localStream?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Broadcaster")),
      body: Column(
        children: [
          Expanded(
            child: RTCVideoView(_localRenderer, mirror: isFrontCameraSelected),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: _switchCamera,
          ),
        ],
      ),
    );
  }
}
