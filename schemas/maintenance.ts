import { z } from "zod"

export const MaintenanceType = z.enum([
  "OIL_CHANGE",
  "TIRE_ROTATION",
  "BRAKE_SERVICE",
  "INSPECTION",
  "FLUID_SERVICE",
  "FILTER_CHANGE",
  "BATTERY_SERVICE",
  "TRANSMISSION_SERVICE",
  "ENGINE_SERVICE",
  "ELECTRICAL_SERVICE",
  "AC_SERVICE",
  "EXHAUST_SERVICE",
  "SUSPENSION_SERVICE",
  "WHEEL_ALIGNMENT",
  "SCHEDULED_MAINTENANCE",
  "REPAIR",
  "RECALL",
  "OTHER"
])

export const MaintenanceStatus = z.enum([
  "UPCOMING",
  "DUE",
  "OVERDUE",
  "COMPLETED"
])

export const vehicleSchema = z.object({
  make: z.string(),
  model: z.string(),
  year: z.number()
})

export const maintenanceSchema = z.object({
  id: z.string(),
  vehicleId: z.string(),
  type: MaintenanceType,
  status: MaintenanceStatus,
  date: z.string(),
  mileage: z.number().min(0),
  description: z.string().min(1),
  cost: z.number().min(0),
  serviceProvider: z.string().optional(),
  notes: z.string().optional(),
  attachments: z.array(z.string()).optional(),
  vehicle: vehicleSchema
})

export type MaintenanceType = z.infer<typeof MaintenanceType>
export type MaintenanceStatus = z.infer<typeof MaintenanceStatus>
export type MaintenanceRecord = z.infer<typeof maintenanceSchema>
export type Vehicle = z.infer<typeof vehicleSchema> 