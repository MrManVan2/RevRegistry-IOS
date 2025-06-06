import { z } from "zod"
import { FuelType } from "@prisma/client"

export const fuelFormSchema = z.object({
  vehicleId: z.string().min(1, "Vehicle is required"),
  date: z.string().min(1, "Date is required"),
  mileage: z.coerce
    .number()
    .min(0, "Mileage must be greater than 0")
    .max(999999, "Mileage too high"),
  volume: z.coerce
    .number()
    .min(0, "Volume must be greater than 0")
    .max(100, "Volume too high (max 100 gallons)"),
  cost: z.coerce
    .number()
    .min(0, "Cost must be greater than 0")
    .max(9999, "Cost too high"),
  fuelType: z.nativeEnum(FuelType),
  location: z.string().optional(),
  isTankFilled: z.boolean().default(true),
  notes: z.string().optional()
})

export type FuelFormData = z.infer<typeof fuelFormSchema>

export type FuelEntry = {
  id: string
  vehicleId: string
  date: Date
  mileage: number
  volume: number
  cost: number
  fuelType: FuelType
  location?: string | null
  isTankFilled: boolean
  notes?: string | null
  createdAt: Date
  updatedAt: Date
  vehicle: {
    make: string
    model: string
  }
} 