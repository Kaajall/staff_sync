# 📍 StaffSync Application

StaffSync is a role-based mobile application built using Flutter and Node.js, designed to help organizations monitor staff movements, assign daily tasks, and receive real-time geo-tagged reports.

---

## 🚀 Features

- 📍 Real-time location tracking of staff
- 🗺️ Mission drawer with Google Maps integration
- 📸 Geo-tagged photo & remark submissions
- 🧾 Visit history & analytics for admins
- 🔐 Role-based login for staff and admin

---

## 🛠️ Tech Stack

| Layer      | Technology            |
|------------|------------------------|
| Frontend   | Flutter, Dart          |
| Backend    | Node.js, Express.js    |
| Database   | MySQL (via MySQL Workbench) |
| APIs       | Google Maps API        |
| Tools      | GitHub, Postman        |

---

## 🧰 Installation & Setup

### 1. Clone the Repository

```bash
git clone https://github.com/YourUsername/StaffSync-App.git
cd StaffSync
```

### 2. Backend Setup

```bash
cd backend
npm install
```

Set up a `.env` file:

```env
PORT=5000
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=staffsync
JWT_SECRET=your_secret_key
```

Start the backend server:

```bash
node index.js
```

### 3. Flutter Frontend Setup

```bash
cd ../flutter_app
flutter pub get
flutter run
```

Make sure your emulator or device is connected.

---

## 📂 Folder Structure

```
StaffSync-App/
├── flutter_backend/
│   ├── routes/
│   ├── controllers/
│   └── utils/
├──  lib/
│   ├── screens/
│   ├── widgets/
│   └── main.dart
└── README.md
```

---

## 💡 Future Improvements

- Offline sync mode for remote locations
- Push notifications for mission updates
- Web admin dashboard for expanded analytics

---
