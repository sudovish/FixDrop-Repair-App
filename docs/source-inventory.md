# Source Inventory

This repository is based on the intended local project folder:

```text
/Users/vshnav/Downloads/FixDrop-5-2
```

This is not the earlier workspace copy `FixDrop-5-2-demo`. The Downloads copy contains newer May 5 changes and should be treated as the correct source of truth.

## Local Evidence

The Downloads project contains:

- `APP_REVIEW_BACKEND_PROMPT.md`
- `BACKEND_PORTAL_PROMPT.md`
- `BACKEND_REALTIME_PROMPT.md`
- `BACKEND_SCHEDULING_AND_SALES_PROMPT.md`
- `FixDrop/` SwiftUI app source
- `FixDrop.xcodeproj/` Xcode project
- `FixDrop/FixDrop.entitlements`
- `backend/` Node/SQLite backend source
- `FixDrop.zip`, `FixDrop 2.zip`, and `FixDrop 3.zip` archives

## Local Source Counts

Approximate source footprint found in `/Users/vshnav/Downloads/FixDrop-5-2`:

| Area | Lines |
|---|---:|
| Swift app + backend source/docs | ~12,720 |
| `RepairStore.swift` | 1,992 |
| `AdminViews.swift` | 1,368 |
| `HomeView.swift` | 591 |
| `Models.swift` | 522 |
| Backend source | ~1,200 |

## Newer Files In This Version

The most recent local edits are:

```text
2026-05-05 FixDrop/Views/Customer/CustomerTabView.swift
2026-05-05 FixDrop/Store/RepairStore.swift
2026-05-05 FixDrop/Services/PricingService.swift
2026-05-05 FixDrop/Views/HomeView.swift
2026-05-05 FixDrop/Views/Customer/CustomerOnboardingView.swift
2026-05-05 FixDrop/Views/LaunchView.swift
```

## Important App Files

```text
FixDrop/FixDropApp.swift
FixDrop/ContentView.swift
FixDrop/FixDrop.entitlements
FixDrop/Info.plist
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

## Important Backend Files

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

## Packaging Note

This repo excludes generated build outputs, simulator state, `.DS_Store`, local SQLite databases, secrets, and machine-specific files. The public GitHub repo should represent `/Users/vshnav/Downloads/FixDrop-5-2` as the source of truth.
