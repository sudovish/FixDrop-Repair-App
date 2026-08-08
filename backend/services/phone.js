"use strict";

function normalizePhone(input) {
  const raw = String(input || "").trim();
  const digits = raw.replace(/\D/g, "");

  if (!digits) return "";
  if (digits.length === 10) return `+1${digits}`;
  if (digits.length === 11 && digits.startsWith("1")) return `+${digits}`;
  if (raw.startsWith("+")) return `+${digits}`;
  return `+${digits}`;
}

module.exports = { normalizePhone };
