"use strict";
const express = require("express");
const router = express.Router();
const { getDb } = require("../db/database");
const { requireAdmin } = require("../middleware/auth");

router.get("/", (req, res) => {
  const db = getDb();
  const row = db.prepare("SELECT config FROM pricing WHERE id=1").get();
  if (!row) return res.status(404).json({ error: "Pricing not configured" });
  res.json(JSON.parse(row.config));
});

router.put("/", requireAdmin, (req, res) => {
  const config = req.body;
  if (!config.estimateRanges || !config.guardrails || !config.travelFees) {
    return res.status(400).json({ error: "Invalid pricing config structure" });
  }
  config.lastUpdated = new Date().toISOString();

  const db = getDb();
  db.prepare("UPDATE pricing SET config=?, updated_at=datetime('now') WHERE id=1").run(JSON.stringify(config));

  res.json({ success: true, lastUpdated: config.lastUpdated });
});

router.get("/model/:model", (req, res) => {
  const db = getDb();
  const row = db.prepare("SELECT config FROM pricing WHERE id=1").get();
  if (!row) return res.status(404).json({ error: "Pricing not configured" });

  const config = JSON.parse(row.config);
  const modelPricing = config.modelPricing || {};
  const entry = modelPricing[req.params.model];

  if (!entry) return res.json({ found: false });

  const safeEntry = {
    found: true,
    screen: (entry.screen || []).map((screen) => ({ quality: screen.quality, quote: screen.quote })),
    battery: { quote: entry.battery?.quote ?? null },
    backglass: { quote: entry.backglass?.quote ?? null },
  };
  res.json(safeEntry);
});

module.exports = router;
