"use strict";
const express = require("express");
const bcrypt = require("bcryptjs");
const { v4: uuidv4 } = require("uuid");
const router = express.Router();

const { getDb } = require("../db/database");
const { signToken } = require("../middleware/auth");
const { normalizePhone } = require("../services/phone");

router.post("/customer/session", (req, res) => {
  const phone = normalizePhone(req.body.phone);
  const firstName = String(req.body.firstName || "").trim();
  const lastName = String(req.body.lastName || "").trim();
  if (!phone || !firstName || !lastName) {
    return res.status(400).json({ error: "phone, firstName and lastName are required" });
  }

  const db = getDb();
  let customer = db.prepare("SELECT * FROM customers WHERE phone=?").get(phone);

  if (!customer) {
    const id = uuidv4();
    db.prepare("INSERT INTO customers (id,first_name,last_name,phone) VALUES (?,?,?,?)")
      .run(id, firstName, lastName, phone);
    customer = db.prepare("SELECT * FROM customers WHERE id=?").get(id);
  } else if (customer.first_name !== firstName || customer.last_name !== lastName) {
    db.prepare("UPDATE customers SET first_name=?, last_name=? WHERE id=?")
      .run(firstName, lastName, customer.id);
    customer = db.prepare("SELECT * FROM customers WHERE id=?").get(customer.id);
  }

  const token = signToken({ id: customer.id, role: "customer", phone });
  res.json({
    token,
    customer: {
      id: customer.id,
      firstName: customer.first_name,
      lastName: customer.last_name,
      phone: customer.phone,
    },
  });
});

router.post("/technician/login", (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) return res.status(400).json({ error: "email and password required" });

  const db = getDb();
  const tech = db.prepare("SELECT * FROM technicians WHERE email=?").get(email.toLowerCase());
  if (!tech) return res.status(401).json({ error: "Invalid credentials" });

  const match = bcrypt.compareSync(password, tech.password_hash);
  if (!match) return res.status(401).json({ error: "Invalid credentials" });
  if (!tech.is_approved) return res.status(403).json({ error: "Account not approved" });

  const token = signToken({ id: tech.id, role: tech.role, name: tech.name });
  res.json({ token, technician: formatTech(tech) });
});

function formatTech(t) {
  return {
    id: t.id,
    name: t.name,
    email: t.email,
    role: t.role,
    isOnDuty: !!t.is_on_duty,
    isApproved: !!t.is_approved,
    radiusKm: t.radius_km,
    specialties: JSON.parse(t.specialties || "[]"),
    region: t.region,
    rating: t.rating,
    jobsCompleted: t.jobs_completed,
    lat: t.lat,
    lng: t.lng,
  };
}

module.exports = router;
