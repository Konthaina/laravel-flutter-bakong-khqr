# 🚀 Bakong KHQR POS System (Laravel + Flutter)

A comprehensive guide for integrating the **Bakong KHQR** payment system with a Laravel backend and Flutter Android frontend. Focus on security, best practices, and seamless payment integration.

## 🛠️ Technology Stack

![Laravel](https://img.shields.io/badge/Laravel-FF2D20?style=for-the-badge&logo=laravel&logoColor=white)
![PHP](https://img.shields.io/badge/PHP-777BB4?style=for-the-badge&logo=php&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-00000F?style=for-the-badge&logo=mysql&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)
![REST API](https://img.shields.io/badge/REST%20API-009688?style=for-the-badge&logo=fastapi&logoColor=white)
![QR Code](https://img.shields.io/badge/QR%20Code-000000?style=for-the-badge&logo=qrcode&logoColor=white)

---

## 📋 Table of Contents

- [Overview](#-overview)
- [KHQR Standard](#khqr-standard)
- [Account Setup](#account-setup)
- [Installation](#️-installation)
- [API Integration](#api-integration)
- [Security Best Practices](#-security-best-practices)
- [Documentation](#documentation-resources)

---

## 🔰 Overview

**Bakong KHQR** is a standardized QR code payment system by the National Bank of Cambodia that enables:
- **Single QR Code** for all payment methods (Bakong App, banks, e-wallets)
- **Instant Payments** through mobile banking and Bakong App
- **Retail & Remittance** transactions
- **Interoperability** across payment providers

This project integrates Bakong KHQR with:
- **Backend**: Laravel REST API for QR generation and payment verification
- **Frontend**: Flutter Android app for scanning and payment processing

---

## KHQR Standard

### QR Code Types

| Type | Tag | Use Case | Example |
|------|-----|----------|---------|
| **Individual/Solo** | Tag 29 | Personal merchant | `john_smith@devb` |
| **Corporate** | Tag 30 | Business merchant with ID | Merchant ID + Account |
| **Remittance** | Tag 29 | Cross-border transfer | `khqr@devb` |

### QR Content Structure

```
00020101021229...  Payload Format (EMV Standard)
├── 00: Payload Format Indicator
├── 01: Point of Initiation (01=Static, 02=Dynamic)
├── 29: Merchant Account Info (Tag 29)
│   ├── 00: Bakong Account ID
│   └── 01: Sub-merchant ID (optional)
├── 52: Merchant Category Code (MCC) → 5999
├── 53: Currency Code → 116 (KHR) or 840 (USD)
├── 54: Transaction Amount
├── 58: Country Code → KH
├── 59: Merchant Name
├── 60: Merchant City
├── 62: Additional Data Field
│   ├── 01: Bill Number
│   ├── 03: Mobile Number
│   ├── 07: Store Label
│   └── 08: Terminal Label
├── 99: Timestamp (milliseconds)
└── 63: CRC Checksum
```

### Static vs Dynamic QR

| Feature | Static QR | Dynamic QR |
|---------|-----------|-----------|
| **Amount** | Fixed or prompt | Per transaction |
| **Regeneration** | Same QR always | New QR each time |
| **Use Case** | Stores, tip jars | Invoice, checkout |
| **Point of Initiation** | `010211` | `010212` |

---

## 📱 Account Setup

### 1. Create Bakong Account (Individual)

1. Download **Bakong App** ([App Store](https://apps.apple.com/kh/app/bakong/id1440829141) | [Play Store](https://play.google.com/store/apps/details?id=jp.co.soramitsu.bakong))
2. Create account with KYC verification
3. Wait **1-5 business days** for verification
4. Once verified, your Bakong account becomes your **Merchant Account ID** (e.g., `john_smith@devb`)

> ✅ Your Bakong ID will be in format: `username@bank` (e.g., `merchant@devb` for Development Bank)

### 2. Register Developer Account & Get Token

1. Visit **Developer Portal**: https://api-bakong.nbc.gov.kh/register
2. Create business account
3. Generate **Fixed Token** (API Key)

| Field | Purpose | Note |
|-------|---------|------|
| `BAKONG_MERCHANT_ID` | Bakong account ID | Format: `username@bank` |
| `BAKONG_FIXED_TOKEN` | API authentication token | Keep secret in `.env` only |
| `BAKONG_API_URL` | Production API endpoint | `https://api-bakong.nbc.gov.kh` |

---

## ️ Installation

### Backend (Laravel)

```bash
cd bakong-pos

# Install PHP dependencies
composer install

# Install Node dependencies for frontend assets
npm install

# Generate Laravel app key
cp .env.example .env
php artisan key:generate

# Configure environment
# Update .env with:
# - DB_CONNECTION, DB_HOST, DB_PASSWORD
# - BAKONG_MERCHANT_ID, BAKONG_FIXED_TOKEN, BAKONG_API_URL
# - APP_URL for CORS

# Database setup
php artisan migrate

# Build frontend assets
npm run build
# or development
npm run dev

# Start development server
php artisan serve
```

The API will be available at `http://localhost:8000/api`

### Frontend (Flutter Android)

```bash
cd flutter_app

# Get dependencies
flutter pub get

# Update API endpoint in lib/services/api_service.dart
# const String API_BASE_URL = 'http://10.0.2.2:8000/api'; // Emulator
# const String API_BASE_URL = 'http://<your-pc-ip>:8000/api'; // Physical device

# Run on emulator or device
flutter devices
flutter run -d <device_id>

# Build release APK
flutter build apk --release

# Build for Play Store
flutter build appbundle --release
```

---

## API Integration

### Backend Packages

```bash
composer require endroid/qr-code              # QR Code generation
composer require piseth-chhun/bakong-khqr-php # Bakong KHQR library
```

### Generate KHQR QR Code

**Request** (POST `/api/khqr/generate`)
```json
{
  "merchant_account": "john_smith@devb",
  "merchant_name": "John Smith",
  "merchant_city": "Phnom Penh",
  "amount": 10000,
  "currency": "KHR",
  "bill_number": "INV-001",
  "mobile_number": "85512345678",
  "store_label": "Store 1",
  "terminal_label": "Cashier-01"
}
```

**Response** (Success)
```json
{
  "success": true,
  "data": {
    "qr_code": "00020101021229180014john_smith@devbq5204599953038405...63048A5B",
    "md5_hash": "8a1c5d9f3e2b7a0c9f5d2e8a1c3b6f9e",
    "amount": 10000,
    "currency": "KHR",
    "timestamp": 1688024244618
  }
}
```

### Check Payment Status

**Request** (POST `/api/khqr/check-payment`)
```json
{
  "md5_hash": "8a1c5d9f3e2b7a0c9f5d2e8a1c3b6f9e"
}
```

**Response** (Success)
```json
{
  "success": true,
  "data": {
    "md5_hash": "8a1c5d9f3e2b7a0c9f5d2e8a1c3b6f9e",
    "status": "paid",
    "amount": 10000,
    "currency": "KHR",
    "paid_at": "2023-06-29T10:30:45.000Z",
    "transaction_id": "TXN123456789"
  }
}
```

---

## 🔒 Security Best Practices

### ✅ DO
- **Store credentials server-side only** (`.env` file)
- **Use HTTPS** for all API communication
- **Validate payment signatures** from Bakong webhook
- **Implement rate limiting** on API endpoints
- **Log all transactions** for audit trail
- **Use CORS** to restrict frontend origins
- **Implement webhook verification** with IP whitelist
- **Rotate API tokens** periodically
- **Validate all user inputs** (amount, merchant name)

### ❌ DON'T
- **Expose** `BAKONG_FIXED_TOKEN` in frontend or repository
- **Store** credentials in version control
- **Log** sensitive data (tokens, credentials)
- **Accept** unsigned webhook requests
- **Trust** client-side amount validation
- **Hardcode** merchant ID in frontend
- **Use** development token in production

### Webhook Security

```php
// Verify Bakong webhook signature
$signature = request()->header('X-Bakong-Signature');
$payload = file_get_contents('php://input');
$computed = hash_hmac('sha256', $payload, env('BAKONG_FIXED_TOKEN'));

if (!hash_equals($computed, $signature)) {
    return response()->json(['error' => 'Invalid signature'], 401);
}
```

---

## Documentation Resources

### Official Bakong Documentation
- **Open API Docs**: https://api-bakong.nbc.gov.kh/document
- **KHQR SDK Document** (v2.7): [PDF Download](https://bakong.nbc.gov.kh/download/KHQR/integration/KHQR%20SDK%20Document.pdf)
- **KHQR Content Guideline** (v1.4): [PDF Download](https://bakong.nbc.gov.kh/download/KHQR/integration/KHQR%20Content%20Guideline%20v.1.3.pdf)
- **QR Payment Integration Guide**: [PDF Download](https://bakong.nbc.gov.kh/download/KHQR/integration/QR%20Payment%20Integration.pdf)
- **Developer Registration**: https://api-bakong.nbc.gov.kh/register
- **Bakong Mobile App**: [App Store](https://apps.apple.com/kh/app/bakong/id1440829141) | [Play Store](https://play.google.com/store/apps/details?id=jp.co.soramitsu.bakong)

### API Environments
- **Development**: https://sit-api-bakong.nbc.gov.kh/
- **Production**: https://api-bakong.nbc.gov.kh/

### Related Projects
- **Python SDK**: https://github.com/bsthen/bakong-khqr
- **Laravel QR Code**: `composer require endroid/qr-code`

---

## ⚙️ Required Packages (Laravel/PHP)

```bash
# QR Code generation
composer require endroid/qr-code

# Bakong KHQR PHP SDK (if using community library)
composer require piseth-chhun/bakong-khqr-php
