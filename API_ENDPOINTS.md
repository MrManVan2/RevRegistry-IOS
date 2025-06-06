# RevRegistry API Endpoints Reference

Base URL: `http://localhost:3000/api` (Development) | `https://yourdomain.com/api` (Production)

## Authentication Required
All endpoints require authentication via NextAuth session or valid JWT token.

## 🔐 Authentication Endpoints

### POST /api/auth/signin
Sign in a user with email/password or OAuth provider.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "user": {
    "id": "user_id",
    "email": "user@example.com",
    "name": "John Doe"
  },
  "token": "jwt_token_here"
}
```

### POST /api/auth/register
Register a new user account.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "name": "John Doe"
}
```

### GET /api/auth/session
Get current user session information.

**Response:**
```json
{
  "user": {
    "id": "user_id",
    "email": "user@example.com",
    "name": "John Doe",
    "emailVerified": true,
    "twoFactorEnabled": false
  }
}
```

## 🚗 Vehicle Endpoints

### GET /api/vehicles
Get all vehicles for the authenticated user.

**Response:**
```json
[
  {
    "id": "vehicle_id",
    "make": "Toyota",
    "model": "Camry",
    "year": 2020,
    "vin": "1234567890",
    "licensePlate": "ABC123",
    "mileage": 50000,
    "status": "ACTIVE",
    "imageUrl": "https://example.com/image.jpg",
    "purchaseDate": "2020-01-15T00:00:00.000Z",
    "purchasePrice": 25000.00,
    "createdAt": "2023-01-01T00:00:00.000Z",
    "updatedAt": "2023-01-01T00:00:00.000Z",
    "_count": {
      "expenses": 15,
      "maintenance": 8
    }
  }
]
```

### POST /api/vehicles
Create a new vehicle.

**Request Body:**
```json
{
  "make": "Toyota",
  "model": "Camry",
  "year": 2020,
  "vin": "1234567890",
  "licensePlate": "ABC123",
  "mileage": 50000,
  "status": "ACTIVE",
  "purchaseDate": "2020-01-15",
  "purchasePrice": 25000.00
}
```

### GET /api/vehicles/[id]
Get a specific vehicle by ID.

### PUT /api/vehicles/[id]
Update a vehicle.

### DELETE /api/vehicles/[id]
Delete a vehicle.

## 💰 Expense Endpoints

### GET /api/expenses
Get all expenses for the authenticated user.

**Query Parameters:**
- `vehicleId` (optional): Filter by vehicle ID
- `type` (optional): Filter by expense type
- `startDate` (optional): Filter from date
- `endDate` (optional): Filter to date

**Response:**
```json
[
  {
    "id": "expense_id",
    "vehicleId": "vehicle_id",
    "date": "2023-01-15T00:00:00.000Z",
    "amount": 45.50,
    "description": "Gas fill-up",
    "type": "FUEL",
    "category": "ROUTINE",
    "notes": "Shell station on Main St",
    "mileage": 50250,
    "createdAt": "2023-01-15T00:00:00.000Z",
    "vehicle": {
      "make": "Toyota",
      "model": "Camry"
    }
  }
]
```

### POST /api/expenses
Create a new expense.

**Request Body:**
```json
{
  "vehicleId": "vehicle_id",
  "date": "2023-01-15",
  "amount": 45.50,
  "description": "Gas fill-up",
  "type": "FUEL",
  "category": "ROUTINE",
  "notes": "Shell station on Main St",
  "mileage": 50250
}
```

### GET /api/expenses/[id]
Get a specific expense by ID.

### PUT /api/expenses/[id]
Update an expense.

### DELETE /api/expenses/[id]
Delete an expense.

### GET /api/expenses/export
Export expenses to CSV format.

**Query Parameters:**
- `vehicleId` (optional): Filter by vehicle ID
- `startDate` (optional): From date
- `endDate` (optional): To date

## 🔧 Maintenance Endpoints

### GET /api/maintenance
Get all maintenance records for the authenticated user.

**Query Parameters:**
- `vehicleId` (optional): Filter by vehicle ID
- `status` (optional): Filter by status
- `type` (optional): Filter by maintenance type

**Response:**
```json
[
  {
    "id": "maintenance_id",
    "vehicleId": "vehicle_id",
    "type": "OIL_CHANGE",
    "status": "COMPLETED",
    "date": "2023-01-15T00:00:00.000Z",
    "mileage": 50000,
    "dueMileage": 53000,
    "description": "Regular oil change service",
    "notes": "Used synthetic oil",
    "cost": 75.00,
    "priority": "MEDIUM",
    "serviceProvider": "Quick Lube Plus",
    "createdAt": "2023-01-15T00:00:00.000Z",
    "vehicle": {
      "make": "Toyota",
      "model": "Camry"
    }
  }
]
```

### POST /api/maintenance
Create a new maintenance record.

**Request Body:**
```json
{
  "vehicleId": "vehicle_id",
  "type": "OIL_CHANGE",
  "status": "UPCOMING",
  "date": "2023-02-15",
  "mileage": 50000,
  "dueMileage": 53000,
  "description": "Regular oil change service",
  "priority": "MEDIUM"
}
```

### GET /api/maintenance/upcoming
Get upcoming maintenance items.

### GET /api/maintenance/[id]
Get a specific maintenance record by ID.

### PUT /api/maintenance/[id]
Update a maintenance record.

### DELETE /api/maintenance/[id]
Delete a maintenance record.

## ⛽ Fuel Entry Endpoints

### GET /api/fuel
Get fuel entries for the authenticated user.

**Response:**
```json
[
  {
    "id": "fuel_id",
    "vehicleId": "vehicle_id",
    "date": "2023-01-15T00:00:00.000Z",
    "mileage": 50250,
    "gallons": 12.5,
    "pricePerGallon": 3.65,
    "totalCost": 45.625,
    "fuelType": "REGULAR",
    "stationName": "Shell",
    "location": "Main St",
    "notes": "Full tank",
    "vehicle": {
      "make": "Toyota",
      "model": "Camry"
    }
  }
]
```

### POST /api/fuel
Create a new fuel entry.

## 📊 Dashboard & Analytics Endpoints

### GET /api/dashboard/overview
Get dashboard overview data.

**Response:**
```json
{
  "totalVehicles": 3,
  "totalExpenses": 1250.75,
  "upcomingMaintenance": 5,
  "recentActivity": [
    {
      "type": "expense",
      "description": "Gas fill-up",
      "amount": 45.50,
      "date": "2023-01-15T00:00:00.000Z"
    }
  ]
}
```

### GET /api/dashboard/stats
Get detailed statistics.

### GET /api/analytics/events
Get analytics events.

## 📤 Upload Endpoints

### POST /api/upload
Upload files (receipts, vehicle images).

**Request:** Multipart form data
- `file`: File to upload
- `type`: "receipt" | "vehicle_image"
- `entityId`: Related entity ID

**Response:**
```json
{
  "url": "https://example.com/uploads/filename.jpg",
  "publicId": "cloudinary_public_id"
}
```

### DELETE /api/upload/delete
Delete uploaded file.

## 👤 Account Management Endpoints

### GET /api/account/profile
Get user profile information.

### PUT /api/account/profile
Update user profile.

### GET /api/account/preferences
Get user preferences.

### PUT /api/account/preferences
Update user preferences.

### POST /api/account/password
Change password.

### DELETE /api/account/delete
Delete user account.

## 🔔 Notification Endpoints

### GET /api/account/notifications
Get user notifications.

### POST /api/account/notifications/test
Send test notification.

## Error Responses

All endpoints may return these error responses:

### 401 Unauthorized
```json
{
  "error": "Unauthorized",
  "message": "Authentication required"
}
```

### 422 Validation Error
```json
{
  "error": "Validation failed",
  "details": [
    {
      "field": "make",
      "message": "Make is required"
    }
  ]
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal Server Error",
  "message": "Something went wrong"
}
``` 