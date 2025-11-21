# Login API Test Examples

## 1. Register New User

### cURL
```bash
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "SecurePass@123456"
  }'
```

### Response (201 Created)
```json
{
  "message": "Registration successful",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "created_at": "2024-11-20T10:30:00.000000Z",
    "updated_at": "2024-11-20T10:30:00.000000Z"
  },
  "token": "1|abcdefghijklmnopqrstuvwxyz123456"
}
```

---

## 2. Login with Email & Password

### cURL
```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "SecurePass@123456"
  }'
```

### Response (200 OK)
```json
{
  "message": "Login successful",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "role": "user",
    "profile": null,
    "created_at": "2024-11-20T10:30:00.000000Z",
    "updated_at": "2024-11-20T10:30:00.000000Z"
  },
  "token": "2|abcdefghijklmnopqrstuvwxyz123456"
}
```

---

## 3. Login with Invalid Credentials

### cURL
```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "WrongPassword"
  }'
```

### Response (401 Unauthorized)
```json
{
  "message": "Invalid credentials"
}
```

---

## 4. Access Protected Route (List Users - Admin Only)

### Without Token
```bash
curl -X GET http://localhost:8000/api/users
```

### Response (401)
```json
{
  "message": "Unauthenticated."
}
```

### With Token (Regular User)
```bash
curl -X GET http://localhost:8000/api/users \
  -H "Authorization: Bearer 2|abcdefghijklmnopqrstuvwxyz123456"
```

### Response (403)
```json
{
  "message": "Unauthorized. Admin access required."
}
```

### With Token (Admin User)
```bash
curl -X GET http://localhost:8000/api/users \
  -H "Authorization: Bearer 2|abcdefghijklmnopqrstuvwxyz123456"
```

### Response (200)
```json
[
  {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "role": "admin",
    "created_at": "2024-11-20T10:30:00.000000Z",
    "updated_at": "2024-11-20T10:30:00.000000Z",
    "profile": null
  }
]
```

---

## 5. Create Admin User for Testing

```bash
# Register as regular user first
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Admin User",
    "email": "admin@example.com",
    "password": "AdminPass@123456"
  }'

# Then update role to admin via database
php artisan tinker
# In tinker shell:
# $user = App\Models\User::where('email', 'admin@example.com')->first();
# $user->update(['role' => 'admin']);
```

Or directly insert via Tinker:
```php
php artisan tinker
```

```php
\App\Models\User::create([
  'name' => 'Admin User',
  'email' => 'admin@example.com',
  'password' => bcrypt('AdminPass@123456'),
  'role' => 'admin'
]);
```

---

## 6. Test All Authentication Tests

```bash
php artisan test tests/Feature/AuthTest.php
```

## 7. Test All Admin Middleware Tests

```bash
php artisan test tests/Feature/AdminMiddlewareTest.php
```

## 8. Test All Auth Middleware Tests

```bash
php artisan test tests/Feature/AuthMiddlewareTest.php
```

---

## Quick Start

1. **Start Laravel Server**
   ```bash
   php artisan serve
   ```

2. **Run Migrations** (to add role column)
   ```bash
   php artisan migrate
   ```

3. **Register User**
   ```bash
   curl -X POST http://localhost:8000/api/auth/register \
     -H "Content-Type: application/json" \
     -d '{"name":"Test User","email":"test@example.com","password":"SecurePass@123456"}'
   ```

4. **Login & Get Token**
   ```bash
   curl -X POST http://localhost:8000/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"SecurePass@123456"}'
   ```

5. **Use Token for Protected Routes**
   ```bash
   curl -X GET http://localhost:8000/api/users \
     -H "Authorization: Bearer YOUR_TOKEN_HERE"
   ```

---

## Postman Collection

Import this into Postman:

```json
{
  "info": {
    "name": "Bakong POS API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Register",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\"name\":\"John Doe\",\"email\":\"john@example.com\",\"password\":\"SecurePass@123456\"}"
        },
        "url": {
          "raw": "{{base_url}}/api/auth/register",
          "host": ["{{base_url}}"],
          "path": ["api", "auth", "register"]
        }
      }
    },
    {
      "name": "Login",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\"email\":\"john@example.com\",\"password\":\"SecurePass@123456\"}"
        },
        "url": {
          "raw": "{{base_url}}/api/auth/login",
          "host": ["{{base_url}}"],
          "path": ["api", "auth", "login"]
        }
      }
    },
    {
      "name": "Get Users (Admin Only)",
      "request": {
        "method": "GET",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer {{token}}"
          }
        ],
        "url": {
          "raw": "{{base_url}}/api/users",
          "host": ["{{base_url}}"],
          "path": ["api", "users"]
        }
      }
    }
  ],
  "variable": [
    {
      "key": "base_url",
      "value": "http://localhost:8000"
    },
    {
      "key": "token",
      "value": ""
    }
  ]
}
```

Set `{{base_url}}` and `{{token}}` variables in Postman after logging in.
