"use strict";
const jwt = require("jsonwebtoken");

const SECRET = process.env.JWT_SECRET || "dev_secret_change_me";

function signToken(payload) {
  return jwt.sign(payload, SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || "30d",
  });
}

function requireAuth(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith("Bearer ")) {
    return res.status(401).json({ error: "Missing or invalid Authorization header" });
  }
  try {
    req.user = jwt.verify(header.slice(7), SECRET);
    next();
  } catch {
    return res.status(401).json({ error: "Token invalid or expired" });
  }
}

function requireTechnician(req, res, next) {
  requireAuth(req, res, () => {
    if (req.user.role !== "technician" && req.user.role !== "admin") {
      return res.status(403).json({ error: "Technician access required" });
    }
    next();
  });
}

function requireCustomer(req, res, next) {
  requireAuth(req, res, () => {
    if (req.user.role !== "customer") {
      return res.status(403).json({ error: "Customer access required" });
    }
    next();
  });
}

function requireAdmin(req, res, next) {
  requireAuth(req, res, () => {
    if (req.user.role !== "admin") {
      return res.status(403).json({ error: "Admin access required" });
    }
    next();
  });
}

module.exports = { signToken, requireAuth, requireTechnician, requireCustomer, requireAdmin };
