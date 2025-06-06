import { MaintenanceType as PrismaMaintenanceType, MaintenanceStatus as PrismaMaintenanceStatus } from '@prisma/client'

// Use Prisma's enum values directly
export const MaintenanceType = {
  OIL_CHANGE: 'OIL_CHANGE',
  TIRE_ROTATION: 'TIRE_ROTATION',
  BRAKE_SERVICE: 'BRAKE_SERVICE',
  AIR_FILTER: 'AIR_FILTER',
  TRANSMISSION: 'TRANSMISSION',
  INSPECTION: 'INSPECTION',
  OTHER: 'OTHER'
} as const

export type MaintenanceType = PrismaMaintenanceType

export type MaintenanceStatus = PrismaMaintenanceStatus

export const MaintenanceStatusEnum = {
  UPCOMING: 'UPCOMING',
  DUE: 'DUE',
  OVERDUE: 'OVERDUE',
  IN_PROGRESS: 'IN_PROGRESS',
  COMPLETED: 'COMPLETED',
  SKIPPED: 'SKIPPED',
  CANCELLED: 'CANCELLED',
} as const

export const Priority = {
  HIGH: 'HIGH',
  MEDIUM: 'MEDIUM',
  LOW: 'LOW'
} as const

export type Priority = (typeof Priority)[keyof typeof Priority]

export type Maintenance = {
  id: string
  vehicleId: string
  userId: string
  type: MaintenanceType
  status: MaintenanceStatus
  date: Date
  mileage: number
  dueMileage: number // Match Prisma schema field name
  description: string | null
  notes: string | null
  cost: number | null
  priority: Priority
  dueDate: Date | null
  completedDate: Date | null
  createdAt: Date
  updatedAt: Date
}

export type MaintenanceWithVehicle = Maintenance & {
  vehicle: {
    id: string
    make: string
    model: string
    year: number
    mileage: number
  }
}

export type Part = {
  id: string
  maintenanceId: string
  name: string
  partNumber?: string
  quantity: number
  price: number
  url?: string
  vendor?: string
  priority: Priority
  purchased: boolean
  installed: boolean
  notes?: string
  createdAt: Date
  updatedAt: Date
}
