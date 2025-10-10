## ចាប់ផ្តើមរហ័ស (Bakong KHQR)

### 1) បង្កើតគណនី និង Verify ក្នុង App Bakong
បើក App **Bakong** → បង្កើត **Account** → ធ្វើការ **Verify Account**។  
ពេលរង់ចាំ Verify ប្រហែល **១–៥ ថ្ងៃ** (អាស្រ័យលើម៉ោងធ្វើការ/ក្រុមហ៊ុន)។  
បន្ទាប់ពី Verify សម្រេច អ្នកនឹងអាចទទួល/ប្រើ **BAKONG_MERCHANT_ID** (សម្រាប់ KHQR)។  

> **ចំណាំ**: រក្សាទុក Merchant ID/Token ជាចម្ងាយ និងកុំបង្ហាញក្នុង frontend/repo សាធារណៈ។

### 2) ចុះឈ្មោះលើ Web Portal ដើម្បីយក Fixed Token
ចូលទៅកាន់ព័រតាល់ផ្លូវការ → បង្កើតគណនី/ចុះឈ្មោះ → យក **BAKONG_FIXED_TOKEN**:
- Register: <https://api-bakong.nbc.gov.kh/register>

### 3) អានឯកសារ API និងតំឡើង Package តាមភាសាអភិវឌ្ឍន៍
ពិនិត្យឯកសារ API ផ្លូវការ សម្រាប់ endpoints/parameters/flow:
- Docs: <https://api-bakong.nbc.gov.kh/document>

**Laravel/PHP (ឧទាហរណ៍ packages):**
```bash
composer require "piseth chhun/bakong-khqr-php"
composer require endroid/qr-code
