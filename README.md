# 🚀 Bakong KHQR Integration (Laravel/PHP)

សៀវភៅណែនាំសម្រាប់ភ្ជាប់ប្រព័ន្ធបង់ប្រាក់ **Bakong KHQR** ជាមួយ Backend (ឧ. Laravel/PHP) — ផ្តោតលើសុវត្ថិភាព និងលំហូរ (flow) ងាយយល់។

---

## 📋 មាតិកា
- [🔰 សង្ខេប](#-សង្ខេប)
- [📱 បង្កើតគណនី & Verify ក្នុង App Bakong](#-បង្កើតគណនី--verify-ក្នុង-app-bakong)
- [🌐 ចុះឈ្មោះ Portal ដើម្បីយក Fixed Token](#-ចុះឈ្មោះ-portal-ដើម្បីយក-fixed-token)
- [📘 ឯកសារ API ផ្លូវការ](#-ឯកសារ-api-ផ្លូវការ)
- [⚙️ តំឡើង Package (Laravel/PHP)](#️-តំឡើង-package-laravelphp)


---

## 🔰 សង្ខេប
- **Merchant ID** និង **Fixed Token** គួរត្រូវបានរក្សាទុក **server-side** (ឧ. `.env`) ប៉ុណ្ណោះ  
- **កុំបង្ហាញ** credentials ក្នុង frontend ឬ repo សាធារណៈ  
- ប្រើ **HTTPS**, **signature verification**, និង **webhook** មានសុវត្ថិភាព  

---

## 📱 បង្កើតគណនី & Verify ក្នុង App Bakong
1) បើក App **Bakong** → **Create Account**  
2) បំពេញព័ត៌មាន → ផ្ញើស្នើសុំ **Verify**  
3) ⏳ រង់ចាំ **១–៥ ថ្ងៃធ្វើការ** (អាស្រ័យលើម៉ោងក្រុមហ៊ុន/ធនាគារ)  
4) បន្ទាប់ពី Verify ជោគជ័យ ➜ អាចប្រើ **BAKONG_MERCHANT_ID** សម្រាប់ **KHQR**  

> 🔒 **សុវត្ថិភាព**: Merchant ID/Token **កុំដាក់** នៅ client-side / frontend / repo public។

---

## 🌐 ចុះឈ្មោះ Portal ដើម្បីយក Fixed Token
ចូល Portal ផ្លូវការ → បង្កើតគណនី/ចុះឈ្មោះ → ទទួល **BAKONG_FIXED_TOKEN**  
- Register: https://api-bakong.nbc.gov.kh/register

> 💡 សូមបើក **2FA/MFA** លើ Portal ដើម្បីបន្ថែមសុវត្ថិភាព។

---

## 📘 ឯកសារ API ផ្លូវការ
សូមអានជាទីបំផុត៖ authentication, endpoints, parameters, signature/hash និង callback/notification  
- Docs: https://api-bakong.nbc.gov.kh/document

---

## ⚙️ តំឡើង Package (Laravel/PHP)
```bash

composer require endroid/qr-code
composer require piseth chhun/bakong-khqr-php
