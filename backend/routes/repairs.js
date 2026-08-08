"use strict";
const express = require("express");
const { v4: uuidv4 } = require("uuid");
const router = express.Router();
const { getDb } = require("../db/database");
const {
  requireAuth,
  requireTechnician,
  requireCustomer,
  requireAdmin,
} = require("../middleware/auth");
const {
  canAccessRepair,
  canManageRepairAsTechnician,
  formatRepair,
} = require("../services/repairAccess");
const { normalizePhone } = require("../services/phone");

function insertSystemMessage(db, repairId, body) {
  db.prepare(`
    INSERT INTO messages (id,repair_id,sender_id,sender_name,body,is_system,is_from_customer)
    VALUES (?,?,?,?,?,1,0)
  `).run(uuidv4(), repairId, "system", "FixDrop", body);
}

function loadRepair(db, repairId) {
  return db.prepare("SELECT * FROM repairs WHERE id=?").get(repairId);
}

router.get("/", requireAuth, (req, res) => {
  const db = getDb();
  let rows;

  if (req.user.role === "admin") {
    rows = db.prepare("SELECT * FROM repairs ORDER BY submitted_at DESC").all();
  } else if (req.user.role === "technician") {
    rows = db.prepare("SELECT * FROM repairs WHERE technician_id=? ORDER BY submitted_at DESC").all(req.user.id);
  } else {
    rows = db.prepare("SELECT * FROM repairs WHERE customer_id=? ORDER BY submitted_at DESC").all(req.user.id);
  }

  res.json(rows.map((repair) => formatRepair(db, repair)));
});

router.get("/open", requireTechnician, (req, res) => {
  const db = getDb();
  const rows = db.prepare(`
    SELECT * FROM repairs
    WHERE status IN ('submitted','dispatching') AND technician_id IS NULL
    ORDER BY is_urgent DESC, submitted_at ASC
  `).all();
  res.json(rows.map((repair) => formatRepair(db, repair)));
});

router.get("/:id", requireAuth, (req, res) => {
  const db = getDb();
  const repair = loadRepair(db, req.params.id);
  if (!repair) return res.status(404).json({ error: "Repair not found" });
  if (!canAccessRepair(req.user, repair)) {
    return res.status(403).json({ error: "You do not have access to this repair" });
  }
  res.json(formatRepair(db, repair));
});

router.post("/", requireCustomer, (req, res) => {
  const db = getDb();
  const {
    brand,
    model,
    issue,
    symptoms = [],
    additionalDescription = "",
    phoneNumber = "",
    location = "",
    preferredDays = [],
    preferredTime = "",
    additionalNote = "",
    isUrgent = false,
    isTradeIn = false,
  } = req.body;

  if (!brand || !model || !issue) {
    return res.status(400).json({ error: "brand, model and issue are required" });
  }

  const id = uuidv4();
  const normalizedPhone = normalizePhone(phoneNumber || req.user.phone || "");
  db.prepare(`
    INSERT INTO repairs
      (id,customer_id,brand,model,issue,symptoms,description,phone_number,location,
       preferred_days,preferred_time,additional_note,is_urgent,is_trade_in,status)
    VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,'dispatching')
  `).run(
    id,
    req.user.id,
    brand,
    model,
    issue,
    JSON.stringify(symptoms),
    additionalDescription,
    normalizedPhone,
    location,
    JSON.stringify(preferredDays),
    preferredTime,
    additionalNote,
    isUrgent ? 1 : 0,
    isTradeIn ? 1 : 0
  );

  insertSystemMessage(db, id, "Your request has been submitted. Finding a technician near you...");

  const repair = loadRepair(db, id);
  res.status(201).json(formatRepair(db, repair));
});

router.patch("/:id/status", requireAuth, (req, res) => {
  const db = getDb();
  const repair = loadRepair(db, req.params.id);
  if (!repair) return res.status(404).json({ error: "Repair not found" });

  const { status } = req.body;
  const allowed = ["submitted", "dispatching", "accepted", "inProgress", "quoted", "scheduled", "completed", "cancelled"];
  if (!allowed.includes(status)) {
    return res.status(400).json({ error: `Invalid status: ${status}` });
  }

  if (req.user.role === "customer") {
    if (repair.customer_id !== req.user.id) {
      return res.status(403).json({ error: "You do not have access to this repair" });
    }
    if (status !== "cancelled") {
      return res.status(403).json({ error: "Customers can only cancel their own repairs" });
    }
  } else if (!canManageRepairAsTechnician(req.user, repair)) {
    return res.status(403).json({ error: "Only the assigned technician or admin can update this repair" });
  }

  db.prepare("UPDATE repairs SET status=?, updated_at=datetime('now') WHERE id=?").run(status, repair.id);
  res.json(formatRepair(db, loadRepair(db, repair.id)));
});

router.patch("/:id/accept", requireTechnician, (req, res) => {
  const db = getDb();
  const repair = loadRepair(db, req.params.id);
  if (!repair) return res.status(404).json({ error: "Repair not found" });
  if (repair.technician_id) return res.status(409).json({ error: "Already assigned to another technician" });
  if (!["submitted", "dispatching"].includes(repair.status)) {
    return res.status(409).json({ error: "This repair is no longer available to accept" });
  }

  const tech = db.prepare("SELECT name FROM technicians WHERE id=?").get(req.user.id);
  if (!tech) return res.status(404).json({ error: "Technician not found" });

  db.prepare(`
    UPDATE repairs
    SET status='accepted', technician_id=?, technician_name=?, updated_at=datetime('now')
    WHERE id=?
  `).run(req.user.id, tech.name, repair.id);

  insertSystemMessage(db, repair.id, `${tech.name} has accepted your request.`);
  res.json(formatRepair(db, loadRepair(db, repair.id)));
});

router.patch("/:id/complete", requireTechnician, (req, res) => {
  const db = getDb();
  const repair = loadRepair(db, req.params.id);
  if (!repair) return res.status(404).json({ error: "Repair not found" });
  if (!canManageRepairAsTechnician(req.user, repair)) {
    return res.status(403).json({ error: "Only the assigned technician or admin can complete this repair" });
  }

  db.prepare("UPDATE repairs SET status='completed', updated_at=datetime('now') WHERE id=?").run(req.params.id);

  const technicianId = repair.technician_id || req.user.id;
  if (technicianId) {
    db.prepare("UPDATE technicians SET jobs_completed=jobs_completed+1 WHERE id=?").run(technicianId);
  }

  insertSystemMessage(db, req.params.id, "Repair completed. Payment recorded.");
  res.json(formatRepair(db, loadRepair(db, req.params.id)));
});

router.patch("/:id/assign", requireAdmin, (req, res) => {
  const db = getDb();
  const repair = loadRepair(db, req.params.id);
  const { technicianId } = req.body;
  if (!repair) return res.status(404).json({ error: "Repair not found" });

  const tech = db.prepare("SELECT * FROM technicians WHERE id=?").get(technicianId);
  if (!tech) return res.status(404).json({ error: "Technician not found" });
  if (!tech.is_approved) return res.status(409).json({ error: "Technician is not approved" });

  db.prepare(`
    UPDATE repairs
    SET status='accepted', technician_id=?, technician_name=?, updated_at=datetime('now')
    WHERE id=?
  `).run(tech.id, tech.name, req.params.id);

  insertSystemMessage(db, req.params.id, `Assigned to ${tech.name} by admin.`);
  res.json(formatRepair(db, loadRepair(db, req.params.id)));
});

module.exports = router;
