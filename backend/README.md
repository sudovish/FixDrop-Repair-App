# FixDrop Backend

Local Node.js API server for the FixDrop iOS app. It uses SQLite, so no external database is needed for local development.

## Requirements

- Node.js 18 or later

## First-Time Setup

```bash
cd backend
npm install
cp .env.example .env
npm run dev
```

The server starts at:

```text
http://localhost:3001
```

On first run, the backend creates a SQLite database file, creates the tables, and seeds initial admin/pricing data.

## API Overview

### Auth

| Method | Path | Who | Description |
|---|---|---|---|
| POST | `/api/auth/customer/session` | Customer | Create or update a customer session from name and phone. |
| POST | `/api/auth/technician/login` | Tech/Admin | Sign in with email and password. |

### Repairs

| Method | Path | Who | Description |
|---|---|---|---|
| GET | `/api/repairs` | Auth | Customer sees own repairs; technician sees assigned; admin sees all. |
| POST | `/api/repairs` | Customer | Submit a new repair request. |
| GET | `/api/repairs/open` | Technician | View open repair requests. |
| GET | `/api/repairs/:id` | Auth | Read a single repair detail. |
| PATCH | `/api/repairs/:id/accept` | Technician | Accept an open repair request. |
| PATCH | `/api/repairs/:id/complete` | Technician | Mark a repair as completed. |
| PATCH | `/api/repairs/:id/assign` | Admin | Assign a repair to a technician. |
| PATCH | `/api/repairs/:id/status` | Auth | Update repair lifecycle status. |

### Quotes

| Method | Path | Who | Description |
|---|---|---|---|
| GET | `/api/quotes?repairId=xxx` | Auth | Get quotes for a repair. |
| POST | `/api/quotes` | Technician | Send a quote with guardrail checks. |
| PATCH | `/api/quotes/:id/accept` | Customer | Accept a quote. |
| PATCH | `/api/quotes/:id/reject` | Customer | Reject a quote. |
| PATCH | `/api/quotes/:id/admin-approve` | Admin | Approve an out-of-range quote. |
| PATCH | `/api/quotes/:id/admin-reject` | Admin | Reject an out-of-range quote. |

### Messages

| Method | Path | Who | Description |
|---|---|---|---|
| GET | `/api/messages?repairId=xxx` | Auth | Chat history for a repair. |
| POST | `/api/messages` | Auth | Send a message. |

### Technicians

| Method | Path | Who | Description |
|---|---|---|---|
| GET | `/api/technicians` | Tech/Admin | All technicians for admin, or self for technician. |
| GET | `/api/technicians/me` | Technician | Own profile. |
| PATCH | `/api/technicians/me/duty` | Technician | Toggle on/off duty. |
| PATCH | `/api/technicians/me/radius` | Technician | Set service radius. |
| PATCH | `/api/technicians/me/location` | Technician | Update technician location. |
| POST | `/api/technicians` | Admin | Create a new technician. |
| PATCH | `/api/technicians/:id/approve` | Admin | Approve or suspend technician access. |

### Pricing

| Method | Path | Who | Description |
|---|---|---|---|
| GET | `/api/pricing` | Public | Current pricing configuration. |
| PUT | `/api/pricing` | Admin | Save updated pricing configuration. |

### Appointments

| Method | Path | Who | Description |
|---|---|---|---|
| GET | `/api/appointments?repairId=xxx` | Technician | Appointments for a repair. |
| POST | `/api/appointments` | Technician | Create or confirm an appointment. |

## Realtime Chat

Socket.io runs on the same backend port.

| Event | Direction | Description |
|---|---|---|
| `joinRepair` | client to server | Join a room keyed by repair id. |
| `leaveRepair` | client to server | Leave a repair room. |
| `newMessage` | server to client | Receive a newly posted chat message. |

## Deployment Notes

For public deployment, set environment variables such as:

```text
JWT_SECRET=<long random string>
ADMIN_EMAIL=you@example.com
ADMIN_PASSWORD=<strong password>
```

Do not commit `.env`, SQLite database files, uploaded photos, or production credentials.
