# Source Inventory

This repository is based on the local workspace folder:

```text
FixDrop-5-2-demo
```

A separate archive named `FixDrop 2.zip` also exists locally, but the unpacked `FixDrop-5-2-demo` folder contains later edits than the zip. This repo presents the project as `FixDrop Demo 2` while using the newer unpacked source evidence.

## Local Source Counts

Approximate source footprint found locally:

| Area | Files | Lines |
|---|---:|---:|
| iOS Swift app + backend source/docs | 46 | ~9,800 |
| Swift app source only | 31 | ~8,600 |
| Node/SQLite backend | 14 | ~1,200 |

## Important Local App Files

```text
FixDrop/FixDropApp.swift
FixDrop/ContentView.swift
FixDrop/Models/Models.swift
FixDrop/Models/PricingModels.swift
FixDrop/Services/PricingService.swift
FixDrop/Store/RepairStore.swift
FixDrop/Views/Admin/AdminViews.swift
FixDrop/Views/Components/SharedComponents.swift
FixDrop/Views/Customer/CalendarTabView.swift
FixDrop/Views/Customer/CustomerOnboardingView.swift
FixDrop/Views/Customer/CustomerRepairsView.swift
FixDrop/Views/Customer/CustomerRequestDetailView.swift
FixDrop/Views/Customer/CustomerTabView.swift
FixDrop/Views/HomeView.swift
FixDrop/Views/LaunchView.swift
FixDrop/Views/RequestFlow/RequestFlowView.swift
FixDrop/Views/RequestFlow/Step1DeviceView.swift
FixDrop/Views/RequestFlow/Step2IssueView.swift
FixDrop/Views/RequestFlow/Step3DescribeView.swift
FixDrop/Views/RequestFlow/Step4PhotosView.swift
FixDrop/Views/RequestFlow/Step5LocationView.swift
FixDrop/Views/RequestFlow/Step6ExtraView.swift
FixDrop/Views/Shared/ChatView.swift
FixDrop/Views/Shared/QuoteReviewView.swift
FixDrop/Views/Shared/SchedulingView.swift
FixDrop/Views/Technician/QuoteBuilderView.swift
FixDrop/Views/Technician/TechMapOrderView.swift
FixDrop/Views/Technician/TechOrderDetailView.swift
FixDrop/Views/Technician/TechOtherViews.swift
FixDrop/Views/Technician/TechnicianLoginView.swift
FixDrop/Views/Technician/TechnicianTabView.swift
```

## Important Local Backend Files

```text
backend/server.js
backend/db/database.js
backend/middleware/auth.js
backend/routes/appointments.js
backend/routes/auth.js
backend/routes/messages.js
backend/routes/pricing.js
backend/routes/quotes.js
backend/routes/repairs.js
backend/routes/technicians.js
backend/services/phone.js
backend/services/repairAccess.js
```

## Repository Packaging Note

This GitHub repo excludes generated build outputs, simulator state, user-specific Xcode data, zip archives, local SQLite databases, and secrets. It focuses on making the project readable as a professional portfolio artifact with the main app architecture, backend architecture, source excerpts, and visual presentation assets.
