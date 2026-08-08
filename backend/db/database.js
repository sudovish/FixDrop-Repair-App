"use strict";
const Database = require("better-sqlite3");
const bcrypt = require("bcryptjs");
const { v4: uuidv4 } = require("uuid");
const path = require("path");

const DB_PATH = process.env.DB_PATH || "./fixdrop.db";
let db;

function getDb() {
  if (!db) {
    db = new Database(path.resolve(DB_PATH));
    db.pragma("journal_mode = WAL");
    db.pragma("foreign_keys = ON");
  }
  return db;
}

function migrate() {
  const db = getDb();

  db.exec(`
    CREATE TABLE IF NOT EXISTS customers (
      id TEXT PRIMARY KEY,
      first_name TEXT NOT NULL,
      last_name TEXT NOT NULL,
      phone TEXT NOT NULL UNIQUE,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS technicians (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      role TEXT NOT NULL DEFAULT 'technician',
      is_approved INTEGER NOT NULL DEFAULT 1,
      is_on_duty INTEGER NOT NULL DEFAULT 0,
      radius_km REAL NOT NULL DEFAULT 25,
      specialties TEXT NOT NULL DEFAULT '[]',
      region TEXT NOT NULL DEFAULT '',
      rating REAL NOT NULL DEFAULT 5.0,
      jobs_completed INTEGER NOT NULL DEFAULT 0,
      lat REAL,
      lng REAL,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS repairs (
      id TEXT PRIMARY KEY,
      customer_id TEXT REFERENCES customers(id),
      brand TEXT NOT NULL,
      model TEXT NOT NULL,
      issue TEXT NOT NULL,
      symptoms TEXT NOT NULL DEFAULT '[]',
      description TEXT NOT NULL DEFAULT '',
      phone_number TEXT NOT NULL DEFAULT '',
      location TEXT NOT NULL DEFAULT '',
      preferred_days TEXT NOT NULL DEFAULT '[]',
      preferred_time TEXT NOT NULL DEFAULT '',
      additional_note TEXT NOT NULL DEFAULT '',
      is_urgent INTEGER NOT NULL DEFAULT 0,
      is_trade_in INTEGER NOT NULL DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'submitted',
      technician_id TEXT REFERENCES technicians(id),
      technician_name TEXT,
      submitted_at TEXT NOT NULL DEFAULT (datetime('now')),
      updated_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS quotes (
      id TEXT PRIMARY KEY,
      repair_id TEXT NOT NULL REFERENCES repairs(id),
      technician_id TEXT NOT NULL REFERENCES technicians(id),
      technician_name TEXT NOT NULL,
      line_items TEXT NOT NULL DEFAULT '[]',
      status TEXT NOT NULL DEFAULT 'pending',
      requires_approval INTEGER NOT NULL DEFAULT 0,
      admin_note TEXT NOT NULL DEFAULT '',
      revision_note TEXT NOT NULL DEFAULT '',
      sent_at TEXT NOT NULL DEFAULT (datetime('now')),
      updated_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS messages (
      id TEXT PRIMARY KEY,
      repair_id TEXT NOT NULL REFERENCES repairs(id),
      sender_id TEXT NOT NULL,
      sender_name TEXT NOT NULL,
      body TEXT NOT NULL,
      is_system INTEGER NOT NULL DEFAULT 0,
      is_from_customer INTEGER NOT NULL DEFAULT 0,
      sent_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS appointments (
      id TEXT PRIMARY KEY,
      repair_id TEXT NOT NULL REFERENCES repairs(id),
      scheduled_at TEXT NOT NULL,
      mode TEXT NOT NULL DEFAULT 'Onsite Repair',
      note TEXT NOT NULL DEFAULT '',
      confirmed INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS pricing (
      id INTEGER PRIMARY KEY DEFAULT 1,
      config TEXT NOT NULL,
      updated_at TEXT NOT NULL DEFAULT (datetime('now'))
    );
  `);
}

function seed() {
  const db = getDb();

  const existingPricing = db.prepare("SELECT id FROM pricing WHERE id = 1").get();
  if (!existingPricing) {
    const defaultConfig = {
      estimateRanges: {
        Screen: { low: 60, high: 210 },
        Battery: { low: 65, high: 100 },
        "Back Glass": { low: 70, high: 95 },
        "Speaker / Mic": { low: 60, high: 100 },
        Crashing: { low: 50, high: 90 },
        "Software Issue": { low: 40, high: 80 },
        Buttons: { low: 55, high: 95 },
        Other: { low: 50, high: 200 },
      },
      guardrails: { belowThreshold: 20, aboveThreshold: 60 },
      travelFees: [
        { maxKm: 10, fee: 15, label: "0-10 km" },
        { maxKm: 30, fee: 25, label: "10-30 km" },
        { maxKm: 150, fee: 40, label: "30+ km" },
      ],
      priorityFees: { asapMin: 30, asapMax: 60, bypassMin: 15, bypassMax: 25, asapTimeoutMin: 30 },
      defaultLineItems: {
        Screen: [{ label: "Screen Replacement", amount: 140 }, { label: "Labor", amount: 45 }, { label: "Travel Fee", amount: 20 }],
        Battery: [{ label: "Battery Replacement", amount: 85 }, { label: "Labor", amount: 30 }, { label: "Travel Fee", amount: 20 }],
        "Back Glass": [{ label: "Back Glass Repair", amount: 95 }, { label: "Labor", amount: 40 }, { label: "Travel Fee", amount: 20 }],
        "Speaker / Mic": [{ label: "Speaker/Mic Repair", amount: 75 }, { label: "Labor", amount: 30 }, { label: "Travel Fee", amount: 20 }],
        "Software Issue": [{ label: "Software Repair", amount: 60 }, { label: "Labor", amount: 25 }, { label: "Travel Fee", amount: 20 }],
        Other: [{ label: "Diagnostic & Repair", amount: 80 }, { label: "Labor", amount: 35 }, { label: "Travel Fee", amount: 20 }],
      },
      lastUpdated: new Date().toISOString(),
    };

    db.prepare("INSERT INTO pricing (id, config, updated_at) VALUES (1, ?, datetime('now'))").run(JSON.stringify(defaultConfig));
  }

  const adminEmail = process.env.ADMIN_EMAIL || "admin@fixdrop.com";
  const existingAdmin = db.prepare("SELECT id FROM technicians WHERE email = ?").get(adminEmail);
  if (!existingAdmin) {
    const hash = bcrypt.hashSync(process.env.ADMIN_PASSWORD || "admin123", 10);
    db.prepare(`
      INSERT INTO technicians (id, name, email, password_hash, role, is_approved, is_on_duty, radius_km, specialties, region, rating)
      VALUES (?, 'Admin User', ?, ?, 'admin', 1, 1, 150, '[]', 'Metro Vancouver', 5.0)
    `).run(uuidv4(), adminEmail, hash);
  }
}

module.exports = { getDb, migrate, seed };
