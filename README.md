# Pharmion - Pharmacy Management System

Pharmion is a comprehensive digital platform for pharmacy management, designed to modernize and centralize pharmacy operations including prescription management, inventory tracking, patient management, and medication reservations.

---

## System Architecture

| Role | Interface | Responsibilities |
|------|-----------|-----------------|
| Pharmacist | Desktop App (Flutter for Windows) | Manage prescriptions, reservations, patients, exceptions |
| Administrator | Desktop App | Full system control, CRUD for all reference data, reports |
| Patient | Mobile App (Flutter) | Browse products, create reservations, manage profile |

### Key Infrastructure
- **Backend API** - .NET (C#) with REST architecture
- **Database** - Microsoft SQL Server 2022
- **Messaging** - RabbitMQ for async notifications (email on reservation events)
- **Recommendation Engine** - ML.NET collaborative filtering + popularity-based fallback
- **Containerization** - Docker + Docker Compose
- **Auth** - JWT Token-based with refresh token support
- **Payments** - Stripe (sandbox)

---

## Setup & Running the Application

### Prerequisites
- Docker Desktop
- Android Emulator (AVD) - for mobile app testing
- Stripe CLI - for webhook testing

### 1. Prepare Backend

Unpack `.env-tajne.zip` (password provided on DL system) and place the `.env` file in the `pharmion-backend` folder.

> ⚠️ **Important - Stripe Webhook:**
> Every time you start the Stripe CLI, a new webhook secret is generated.
> You must update `Stripe__WebhookSecret` in `.env` and rebuild the API container.
> See [Stripe Webhook Setup](#stripe-webhook-setup) section below.

Navigate to the backend folder and start all services:

```bash
cd pharmion-backend
docker compose up --build
```

This will start:
- SQL Server (port 1433)
- RabbitMQ (port 5672, management UI on port 15672)
- Pharmion API (port 5081)
- Pharmion Subscriber (email notification worker)

Verify API is running: [http://localhost:5081/swagger](http://localhost:5081/swagger)

---

### 2. Desktop Application (Windows)

Download `fit-build-2026-05-31.zip` from [GitHub Releases](https://github.com/amilatucovic/Pharmion/releases/tag/predaja-2026-05-31) and extract it. Navigate to the `Release/` folder and run `pharmion_desktop.exe`.

**API Base URL:** `http://localhost:5081`

---

### 3. Mobile Application (Android)

Download `fit-build-2026-05-31.zip` from [GitHub Releases](https://github.com/amilatucovic/Pharmion/releases/tag/predaja-2026-05-31) and extract it. Find `app-release.apk` in the extracted folder.

- Open Android Emulator (AVD)
- Drag & drop `app-release.apk` into the emulator to install
- Launch the app

**API Base URL:** `http://10.0.2.2:5081`

---

### Running Mobile App from Source Code

If you want to run the mobile app from source code instead of the pre-built APK,
you need to provide build-time configuration via `--dart-define`.

1. Copy the example launch configuration:
```bash
cp pharmion_mobile/.vscode/launch.json.example pharmion_mobile/.vscode/launch.json
```

2. Fill in your values in `launch.json`, or run directly from terminal:
```bash
flutter run \
  --dart-define=API_URL=http://10.0.2.2:5081 \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_your_key_here
```

> The actual `launch.json` with real values is excluded from the repository via `.gitignore`.


---

## Test Accounts

### Desktop Application

| Role | Username | Password |
|------|----------|----------|
| Pharmacist | pharmacist | Test123! |
| Administrator | admin | Test123! |

### Mobile Application

| Role | Username | Password |
|------|----------|----------|
| Patient | patient | Test123! |

---

## Stripe Webhook Setup

Stripe webhook secret is generated dynamically each time the Stripe CLI starts and cannot be predefined.

> **Note:** Webhook setup is optional. The app uses direct Stripe API verification as a fallback, so payments will work even without
> the webhook. Setting up the webhook provides faster payment confirmation.

**Steps before testing payments (optional):**

1. Start Stripe CLI in a separate terminal:
```bash
stripe listen --forward-to http://localhost:5081/webhook/stripe
```

2. Copy the webhook secret displayed:
```
> Ready! Your webhook signing secret is whsec_xxxxxxxxxxxx
```

3. Update `.env` file:
```env
Stripe__WebhookSecret=whsec_xxxxxxxxxxxx
```

4. Rebuild the API container:
```bash
docker compose up --build pharmion-api
```

5. Payments are now ready to test.

### Test Card Details

| Field | Value |
|-------|-------|
| Card Number | 4242 4242 4242 4242 |
| Expiry Date | Any future date (e.g. 12/26) |
| CVC | Any 3 digits (e.g. 123) |
| ZIP | Any 5 digits (e.g. 12345) |

> These are Stripe's standard test card credentials. No real charges will be made.

---

## RabbitMQ Management UI

Access RabbitMQ management interface at:
```
http://localhost:15672
Username: guest
Password: guest
```

---

## Features

### Desktop (Pharmacist / Administrator)
- Prescription management (create, edit, cancel)
- Inventory tracking and stock management
- Patient management with chronic disease tracking
- Reservation management with state machine (Draft → Submitted → Approved → Ready → Picked Up)
- Early dispense exception management - pharmacist reviews and approves/rejects patient requests for early medication refills
- Product management
- Pharmacists management
- Pharmacy and city management
- Reports in PDF format
- Polling notifications for reservation updates

### Mobile (Patient)
- Browse and search products with recommendations
- Create and track reservations
- Early dispense exception requests - if therapy is still active, patient can submit a justified request for early refill
- View prescriptions and therapies
- Profile management
- Payment processing via Stripe
- Polling notifications for reservation updates
- Discovering pharmacies in your city

---

## Recommendation System

See [recommender-dokumentacija.md](./recommender-dokumentacija.md) for full documentation.

**Approach:**
- **Collaborative filtering** (Matrix Factorization via ML.NET) - recommends supplements 
  based on co-reservation patterns among patients. If patients with similar histories 
  reserved supplement A and B together, a new patient who reserved A will get B recommended.
- **Popularity-based fallback** - when a patient has no reservation history, 
  the most frequently reserved supplements across all patients are suggested.

Recommendations include an explanation shown to the user.

---

## Academic Context

This project was developed as part of the **Software Development II** (*Razvoj softvera II*)
course at the **Faculty of Information Technologies, University "Džemal Bijedić" of Mostar**.

**Author:** Amila Tucović  
**Academic Year:** 2025/2026

---
