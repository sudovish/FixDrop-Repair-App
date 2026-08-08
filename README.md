# FixDrop Demo 2

<p align="center">
  <img src="docs/assets/fixdrop-logo.svg" alt="FixDrop app logo" width="140" />
</p>

<p align="center">
  <strong>On-demand phone repair app with customer booking, technician dispatch, quotes, chat, scheduling, admin pricing, and a local backend.</strong>
</p>

<p align="center">
  <img src="docs/assets/app-preview.svg" alt="FixDrop app screen previews" width="100%" />
</p>

## Overview

FixDrop Demo 2 is a full-stack repair-service prototype for handling phone repair requests from customer intake through technician completion. The app is designed around a practical local repair workflow: a customer submits a device issue, a technician reviews and accepts the request, a quote is generated, both sides coordinate through chat and scheduling, and an admin can manage pricing and technician operations.

This repository is a GitHub portfolio snapshot of the most complete FixDrop demo found in the local workspace: `FixDrop-5-2-demo`. I did not find a separate `5_4` folder locally. There was a `FixDrop 2.zip`, but the unpacked demo folder beside it contained newer edits, so this repo presents the complete Demo 2 code path with the latest local app/backend evidence.

## Product Highlights

- Customer-facing SwiftUI iPhone app
- Technician-facing workflow inside the same iOS app
- Admin views for repair operations and pricing control
- Multi-step repair request intake
- Device, issue, photo, location, and extra-detail collection
- Phone-number customer session flow
- Repair request tracking and status timeline
- Technician login and job acceptance
- Quote builder with line items and pricing guardrails
- Customer quote review and acceptance
- In-app chat tied to repair requests
- Scheduling and appointment coordination
- Local notifications for important repair events
- Node.js/Express backend with SQLite persistence
- Socket.io support for real-time repair chat rooms

## App Surfaces

| Surface | What it does |
|---|---|
| Customer App | Lets customers submit repair requests, review quotes, chat, schedule appointments, and view repair history. |
| Technician App | Lets technicians log in, review open jobs, accept repairs, create quotes, update job status, and coordinate with customers. |
| Admin Panel | Supports technician management, pricing configuration, quote guardrails, and repair oversight. |
| Backend API | Handles customer sessions, technicians, repairs, quotes, messages, appointments, and pricing data. |

## Customer Flow

1. Launch FixDrop.
2. Choose the customer role.
3. Select a phone brand/model and issue type.
4. Add symptoms, notes, photos, location, urgency, and schedule preferences.
5. Submit the request.
6. Track the repair status from the customer repairs tab.
7. Chat with the technician after acceptance.
8. Review and accept a quote.
9. Confirm scheduling and completion.

## Technician Flow

1. Log in as a technician or admin.
2. Review open repair requests.
3. Accept jobs within operating radius and availability.
4. View customer issue details, images, and location information.
5. Build a quote with parts, labor, travel fees, and notes.
6. Chat with the customer.
7. Schedule service and update job status.
8. Mark jobs complete.

## Backend Features

The backend is a local Node.js API server using Express, SQLite, JWT authentication, and Socket.io.

Main route areas:

- `POST /api/auth/customer/session`
- `POST /api/auth/technician/login`
- `GET /api/repairs`
- `POST /api/repairs`
- `GET /api/repairs/open`
- `PATCH /api/repairs/:id/accept`
- `PATCH /api/repairs/:id/status`
- `GET /api/quotes`
- `POST /api/quotes`
- `PATCH /api/quotes/:id/accept`
- `GET /api/messages`
- `POST /api/messages`
- `GET /api/technicians`
- `PATCH /api/technicians/me/duty`
- `GET /api/pricing`
- `PUT /api/pricing`
- `POST /api/appointments`

## Tech Stack

| Layer | Technology |
|---|---|
| iOS App | Swift, SwiftUI, Combine, UIKit photo support, UserNotifications |
| Backend | Node.js, Express, Socket.io |
| Database | SQLite with `better-sqlite3` |
| Auth | JWT for technician/admin access, phone-based customer session |
| Realtime | Socket.io repair chat rooms |
| Local Dev | Xcode + local backend on port `3001` |

## Repository Layout

```text
.
├── README.md
├── docs/
│   └── assets/
│       ├── fixdrop-logo.svg
│       └── app-preview.svg
├── ios/
│   └── FixDrop/
│       ├── FixDropApp.swift
│       ├── ContentView.swift
│       ├── Models/
│       ├── Services/
│       └── Store/
└── backend/
    ├── README.md
    ├── package.json
    ├── server.js
    ├── db/
    ├── middleware/
    ├── routes/
    └── services/
```

## Running The Backend

```bash
cd backend
npm install
npm run dev
```

The local server runs at:

```text
http://localhost:3001
```

On first run, the backend initializes the SQLite database and seeds default admin/pricing data.

## Running The iOS App

Open the Xcode project from the full local source snapshot:

```text
FixDrop.xcodeproj
```

For local simulator testing, the app can point to the local backend/proxy. For device or public testing, update the API base URL in the app configuration/service layer.

## Portfolio Notes

This repo is organized for employers and reviewers to quickly understand the product, architecture, and implementation work. It excludes local build outputs, `.xcuserdata`, simulator state, generated databases, secrets, and machine-specific files.

The visual images in this README are professional SVG previews created for the repository presentation, based on the app's actual implemented flows: request intake, technician dashboard, chat/quotes, and admin pricing.
