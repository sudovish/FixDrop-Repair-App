"use strict";

function parseJSON(value, fallback) {
  try {
    return JSON.parse(value || JSON.stringify(fallback));
  } catch {
    return fallback;
  }
}

function formatQuoteRow(q) {
  const lineItems = parseJSON(q.line_items, []);
  return {
    id: q.id,
    repairId: q.repair_id,
    technicianId: q.technician_id,
    technicianName: q.technician_name,
    lineItems,
    status: q.status,
    requiresApproval: !!q.requires_approval,
    adminNote: q.admin_note,
    revisionNote: q.revision_note,
    sentAt: q.sent_at,
    total: lineItems.reduce((sum, item) => sum + (item.amount || 0), 0),
  };
}

function formatMessageRow(m) {
  return {
    id: m.id,
    repairId: m.repair_id,
    senderId: m.sender_id,
    senderName: m.sender_name,
    body: m.body,
    isSystem: !!m.is_system,
    isFromCustomer: !!m.is_from_customer,
    sentAt: m.sent_at,
  };
}

function formatAppointmentRow(a) {
  if (!a) return null;
  return {
    id: a.id,
    repairId: a.repair_id,
    scheduledAt: a.scheduled_at,
    mode: a.mode,
    note: a.note,
    confirmed: !!a.confirmed,
    createdAt: a.created_at,
  };
}

function formatRepair(db, repair) {
  const quotes = db.prepare("SELECT * FROM quotes WHERE repair_id=? ORDER BY sent_at ASC").all(repair.id).map(formatQuoteRow);
  const messages = db.prepare("SELECT * FROM messages WHERE repair_id=? ORDER BY sent_at ASC").all(repair.id).map(formatMessageRow);
  const appointment = db.prepare("SELECT * FROM appointments WHERE repair_id=? ORDER BY scheduled_at DESC LIMIT 1").get(repair.id);

  return {
    id: repair.id,
    brand: repair.brand,
    model: repair.model,
    issue: repair.issue,
    symptoms: parseJSON(repair.symptoms, []),
    additionalDescription: repair.description,
    phoneNumber: repair.phone_number,
    location: repair.location,
    preferredDays: parseJSON(repair.preferred_days, []),
    preferredTime: repair.preferred_time,
    additionalNote: repair.additional_note,
    isUrgent: !!repair.is_urgent,
    isTradeIn: !!repair.is_trade_in,
    status: repair.status,
    assignedTechnicianId: repair.technician_id,
    assignedTechnicianName: repair.technician_name,
    submittedAt: repair.submitted_at,
    updatedAt: repair.updated_at,
    customerId: repair.customer_id,
    quotes,
    messages,
    appointment: formatAppointmentRow(appointment),
  };
}

function canAccessRepair(user, repair) {
  if (!user || !repair) return false;
  if (user.role === "admin") return true;
  if (user.role === "technician") return repair.technician_id === user.id;
  return repair.customer_id === user.id;
}

function canManageRepairAsTechnician(user, repair) {
  if (!user || !repair) return false;
  if (user.role === "admin") return true;
  return user.role === "technician" && repair.technician_id === user.id;
}

module.exports = {
  canAccessRepair,
  canManageRepairAsTechnician,
  formatAppointmentRow,
  formatMessageRow,
  formatQuoteRow,
  formatRepair,
};
