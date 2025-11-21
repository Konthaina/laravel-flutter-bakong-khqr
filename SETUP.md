# Setup Guide: Bakong KHQR POS System

This guide covers the setup and installation for both the Laravel backend and Flutter mobile application.

## Prerequisites

### Backend (Laravel)
- PHP 8.1+
- Composer
- SQLite or MySQL
- Node.js & npm (for frontend assets)

### Frontend (Flutter - Android)
- Flutter SDK (3.0+)
- Dart SDK (bundled with Flutter)
- Android Studio or Android SDK
- JDK 11+

---

## Backend Setup (Laravel)

### 1. Install Dependencies

```bash
cd bakong-pos
composer install
npm install
```

### 2. Environment Configuration

```bash
cp .env.example .env
php artisan key:generate
```

Update `.env` with your database and Bakong credentials:

```env
DB_CONNECTION=sqlite
# or
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=bakong_pos
DB_USERNAME=root
DB_PASSWORD=

# Bakong KHQR
BAKONG_MERCHANT_ID=your_merchant_id
BAKONG_FIXED_TOKEN=your_fixed_token
BAKONG_API_URL=https://api-bakong.nbc.gov.kh
```

### 3. Database Setup

```bash
php artisan migrate
php artisan db:seed  # optional, if seeders exist
```

### 4. Build Frontend Assets

```bash
npm run build
# or for development
npm run dev
```

### 5. Start Development Server

```bash
php artisan serve
```

The API will be available at `http://localhost:8000`

---

## Frontend Setup (Flutter - Android)

### 1. Install Dependencies

```bash
cd flutter_app
flutter pub get
```

### 2. Configure API Endpoint

Update the API base URL in your Flutter app configuration files:

```dart
// Typically in lib/services/api_service.dart or similar
const String API_BASE_URL = 'http://10.0.2.2:8000/api'; // for Android emulator
// const String API_BASE_URL = 'http://<your-pc-ip>:8000/api'; // for physical device on same network
```

### 3. Run on Android Emulator/Device

```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device_id>

# Or run on default device
flutter run
```

**For Physical Device:**
- Enable USB Debugging on your Android device
- Connect via USB or WiFi
- Device must be on same network as backend server
- Replace `10.0.2.2` with your PC IP address

---

## Testing the Integration

### 1. Test Backend API

```bash
# Test health check
curl http://localhost:8000/api/health

# Test KHQR generation (example)
curl -X POST http://localhost:8000/api/khqr/generate \
  -H "Content-Type: application/json" \
  -d '{"amount": 10000, "merchant_id": "your_merchant_id"}'
```

### 2. Test Flutter Android App

- Ensure Android device/emulator is connected: `flutter devices`
- Run the app: `flutter run`
- Navigate to the KHQR payment screen
- Verify QR code generation and payment status updates

---

## Environment Variables Summary

### Backend (.env)

| Variable | Description | Example |
|----------|-------------|---------|
| `APP_URL` | Application URL | `http://localhost:8000` |
| `DB_CONNECTION` | Database type | `sqlite` or `mysql` |
| `BAKONG_MERCHANT_ID` | Merchant ID from Bakong | `your_merchant_id` |
| `BAKONG_FIXED_TOKEN` | API token from Bakong Portal | `your_fixed_token` |
| `BAKONG_API_URL` | Bakong API endpoint | `https://api-bakong.nbc.gov.kh` |

### Frontend (Flutter)

| Variable | Description | Example |
|----------|-------------|---------|
| `API_BASE_URL` | Backend API base URL | `http://localhost:8000/api` |
| `TIMEOUT` | API request timeout | `30000` (ms) |

---

## Troubleshooting

### Backend Issues

**Port 8000 already in use:**
```bash
php artisan serve --port=8001
```

**Database connection error:**
- Verify database credentials in `.env`
- Ensure database server is running
- Run `php artisan migrate:refresh` to reset migrations

**Bakong API errors:**
- Verify `BAKONG_MERCHANT_ID` and `BAKONG_FIXED_TOKEN` are correct
- Check Bakong API status at https://api-bakong.nbc.gov.kh/status
- Review official documentation: https://api-bakong.nbc.gov.kh/document

### Frontend Issues

**Cannot connect to backend:**
- Ensure backend server is running (`php artisan serve`)
- On Android emulator, use `10.0.2.2` instead of `localhost`
- Check firewall settings allowing port 8000
- Verify API endpoint in Flutter code matches backend URL

**Build errors:**
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

---

## Deployment

### Backend (Production)

1. Use environment variables for sensitive data
2. Set `APP_DEBUG=false` in `.env`
3. Run `php artisan config:cache`
4. Set up HTTPS with SSL certificate
5. Configure proper database (MySQL recommended)

### Frontend - Android (Production)

1. Build release APK:
   ```bash
   flutter build apk --release
   ```

2. Build release App Bundle (for Play Store):
   ```bash
   flutter build appbundle --release
   ```

3. Sign and upload to Google Play Store

---

## Additional Resources

- [Laravel Documentation](https://laravel.com/docs)
- [Flutter Documentation](https://flutter.dev/docs)
- [Bakong API Documentation](https://api-bakong.nbc.gov.kh/document)
- [Bakong Registration Portal](https://api-bakong.nbc.gov.kh/register)

---

## Support

For issues or questions:
1. Check this setup guide
2. Review the official README files in `bakong-pos/` and `flutter_app/` directories
3. Consult Bakong API documentation
4. Check project issues on GitHub
