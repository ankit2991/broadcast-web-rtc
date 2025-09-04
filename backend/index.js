// let port = process.env.PORT || 1433;

// let IO = require("socket.io")(port, {
//   cors: {
//     origin: "*",
//     methods: ["GET", "POST"],
//   },
// });

// let broadcaster = null; // store broadcaster socketId

// IO.on("connection", (socket) => {
//   console.log("User Connected:", socket.id);

//   // Broadcaster joins
//   socket.on("broadcaster", () => {
//     broadcaster = socket.id;
//     console.log("Broadcaster is:", broadcaster);
//     // notify all other users
//     socket.broadcast.emit("broadcaster", broadcaster);
//   });

//   // Viewer joins
//   socket.on("viewer", () => {
//     if (broadcaster) {
//       // Tell broadcaster a viewer has joined
//       socket.to(broadcaster).emit("viewer", socket.id);
//     }
//   });

//   // Broadcaster sends SDP offer → forward to viewer
//   socket.on("offer", ({ viewerId, sdpOffer }) => {
//     socket.to(viewerId).emit("offer", {
//       broadcasterId: socket.id,
//       sdpOffer: sdpOffer,
//     });
//   });

//   // Viewer sends SDP answer → forward back to broadcaster
//   socket.on("answer", ({ broadcasterId, sdpAnswer }) => {
//     socket.to(broadcasterId).emit("answer", {
//       viewerId: socket.id,
//       sdpAnswer: sdpAnswer,
//     });
//   });

//   // ICE candidates from both sides
//   socket.on("iceCandidate", ({ targetId, iceCandidate }) => {
//     socket.to(targetId).emit("iceCandidate", {
//       senderId: socket.id,
//       iceCandidate: iceCandidate,
//     });
//   });

//   // Handle disconnect
//   socket.on("disconnect", () => {
//     if (socket.id === broadcaster) {
//       console.log("Broadcaster disconnected");
//       broadcaster = null;
//       socket.broadcast.emit("broadcasterDisconnected");
//     } else {
//       console.log("Viewer disconnected:", socket.id);
//       socket.broadcast.emit("viewerDisconnected", socket.id);
//     }
//   });
// });

const express = require("express");
const http = require("http");
const { Server } = require("socket.io");

const app = express();
const port = process.env.PORT || 80; // IISNode will inject PORT

app.get("/", (req, res) => {
  res.send("Node + Socket.IO server is running 🚀");
});
// Create HTTP server
const server = http.createServer(app);

// Attach Socket.IO to the HTTP server
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"],
  },
});

let broadcaster = null;

// ==========================
// Socket.IO Events
// ==========================
io.on("connection", (socket) => {
  console.log("User Connected:", socket.id);

  // Broadcaster joins
  socket.on("broadcaster", () => {
    broadcaster = socket.id;
    console.log("Broadcaster is:", broadcaster);
    socket.broadcast.emit("broadcaster", broadcaster);
  });

  // Viewer joins
  socket.on("viewer", () => {
    if (broadcaster) {
      socket.to(broadcaster).emit("viewer", socket.id);
    }
  });

  // Broadcaster sends SDP offer → forward to viewer
  socket.on("offer", ({ viewerId, sdpOffer }) => {
    socket.to(viewerId).emit("offer", {
      broadcasterId: socket.id,
      sdpOffer: sdpOffer,
    });
  });

  // Viewer sends SDP answer → forward back to broadcaster
  socket.on("answer", ({ broadcasterId, sdpAnswer }) => {
    socket.to(broadcasterId).emit("answer", {
      viewerId: socket.id,
      sdpAnswer: sdpAnswer,
    });
  });

  // ICE candidates from both sides
  socket.on("iceCandidate", ({ targetId, iceCandidate }) => {
    socket.to(targetId).emit("iceCandidate", {
      senderId: socket.id,
      iceCandidate: iceCandidate,
    });
  });

  // Handle disconnect
  socket.on("disconnect", () => {
    if (socket.id === broadcaster) {
      console.log("Broadcaster disconnected");
      broadcaster = null;
      socket.broadcast.emit("broadcasterDisconnected");
    } else {
      console.log("Viewer disconnected:", socket.id);
      socket.broadcast.emit("viewerDisconnected", socket.id);
    }
  });
});

// ==========================
// Start Server
// ==========================
server.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
