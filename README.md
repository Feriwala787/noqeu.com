# ⏳ NoQeu

> **Stop Waiting, Start Living.** > A lightweight, QR-based digital token and queue management system designed specifically for local Indian businesses (barbers, clinics, mechanics). 

NoQeu eliminates physical waiting rooms. Instead of a complex calendar, it uses a **"Blind Slot"** token system. Customers scan a QR code, tap one button, and get a probable time slot. Built with a strict **Strike System** to maintain digital discipline and respect for the business owner's time.

---

## ✨ Core Features

- **🔒 Private Connections (QR Only):** Users only see and book shops they have physically visited and scanned. No random internet discovery, no fake bookings.
- **⚡ One-Tap Booking:** No calendars or seat selection. The app calculates the next available slot based on `(Users in Queue / Total Seats)` and gives a direct time window.
- **🚫 The Strike System:** If a customer misses their appointment without canceling 30 mins prior, they get a strike. **2 Strikes = Online booking banned.** They must visit as a walk-in to get unblocked.
- **🔔 Smart Reminders:** Automated push/WhatsApp notifications sent exactly 30 minutes before the allocated slot.
- **💰 Ad-Supported (Free for Shops):** Monetized via Google AdMob (Interstitials & Banners) so the core software remains free for local shop owners.

---

## 🛠️ Tech Stack

**Frontend (Mobile App)**
- Framework: React Native / Flutter
- Auth: Firebase Phone Authentication (OTP)
- Monetization: Google AdMob

**Backend (API & Logic)**
- Runtime: Node.js with Express.js
- Database: MongoDB Atlas (Free Tier)
- Scheduled Tasks: `node-cron` (for 30-min reminders)
- Hosting: Railway.app / Render

---

## 📂 Project Structure

```text
noqeu/
├── /backend                 # Node.js API
│   ├── /models              # Mongoose Schemas (User, Shop, Appointment)
│   ├── /controllers         # Business Logic (Booking engine, Strike system)
│   ├── /routes              # Express API Endpoints
│   ├── /utils               # Cron jobs and Time calculations
│   ├── server.js            # Main entry point
│   └── .env.example         # Environment variables template
│
└── /mobile                  # React Native / Flutter App
    ├── /src
    │   ├── /api             # API service calls
    │   ├── /components      # Reusable UI elements & Ad blocks
    │   ├── /screens         # Auth, Home, ShopDetail, ActiveToken
    │   └── /navigation      # Deep linking logic for QR scans
    └── app.json
