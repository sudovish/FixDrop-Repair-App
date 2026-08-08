"use strict";
require("dotenv").config();

const express = require("express");
const http = require("http");
const { Server } = require("socket.io");
const cors = require("cors");

const { migrate, seed } = require("./db/database");

const authRoute = require("./routes/auth");
const pricingRoute = require("./routes/pricing");
const repairsRoute = require("./routes/repairs");
const quotesRoute = require("./routes/quotes");
const messagesRoute = require("./routes/messages");
const techniciansRoute = require("./routes/technicians");
const appointmentsRoute = require("./routes/appointments");

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: "*", methods: ["GET", "POST"] },
});

app.use(cors());
app.use(express.json({ limit: "10mb" }));

app.use((req, _res, next) => {
  req.io = io;
  next();
});

app.use("/api/auth", authRoute);
app.use("/api/pricing", pricingRoute);
app.use("/api/repairs", repairsRoute);
app.use("/api/quotes", quotesRoute);
app.use("/api/messages", messagesRoute);
app.use("/api/technicians", techniciansRoute);
app.use("/api/appointments", appointmentsRoute);

app.get("/api/health", (_req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

app.use((_req, res) => res.status(404).json({ error: "Not found" }));

app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({ error: "Internal server error", detail: err.message });
});

io.on("connection", (socket) => {
  socket.on("joinRepair", (repairId) => {
    socket.join(repairId);
    console.log(`  [Socket] ${socket.id} joined repair room: ${repairId}`);
  });

  socket.on("leaveRepair", (repairId) => {
    socket.leave(repairId);
  });
});

const PORT = process.env.PORT || 3001;

console.log("FixDrop API starting up...");
console.log("Initialising database...");
migrate();
console.log("Seeding default data...");
seed();

server.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
  console.log(`GET    http://localhost:${PORT}/api/health`);
  console.log(`POST   http://localhost:${PORT}/api/auth/customer/session`);
  console.log(`POST   http://localhost:${PORT}/api/auth/technician/login`);
  console.log(`GET    http://localhost:${PORT}/api/pricing`);
  console.log(`GET    http://localhost:${PORT}/api/repairs`);
  console.log(`POST   http://localhost:${PORT}/api/repairs`);
  console.log(`GET    http://localhost:${PORT}/api/repairs/open`);
  console.log(`GET    http://localhost:${PORT}/api/messages?repairId=xxx`);
  console.log(`POST   http://localhost:${PORT}/api/messages`);
  console.log(`GET    http://localhost:${PORT}/api/technicians`);
});
