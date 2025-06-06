export enum VehicleStatus {
  ACTIVE = "ACTIVE",
  SOLD = "SOLD",
  INACTIVE = "INACTIVE"
}

export interface BaseVehicle {
  id: string
  make: string
  model: string
  year: number
  mileage: number
}

export interface Vehicle extends BaseVehicle {
  id: string
  userId: string
  make: string
  model: string
  year: number
  vin?: string | null
  licensePlate?: string | null
  mileage: number
  purchaseDate: Date
  purchasePrice: number
  imageUrl?: string | null
  status: VehicleStatus
  createdAt: Date
  updatedAt: Date
}

export interface VehicleWithMaintenance extends BaseVehicle {
  maintenances: {
    id: string
    type: string
    status: string
    mileageDue: number
    description?: string | null
  }[]
}

export interface VehicleWithExpenses extends BaseVehicle {
  expenses: {
    id: string
    type: string
    amount: number
    date: Date
    description?: string | null
  }[]
}

export interface VehicleWithMaintenanceAndExpenses extends BaseVehicle {
  maintenances: {
    id: string
    type: string
    status: string
    mileageDue: number
    description?: string | null
  }[]
  expenses: {
    id: string
    type: string
    amount: number
    date: Date
    description?: string | null
  }[]
}
