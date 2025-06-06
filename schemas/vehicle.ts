import { z } from "zod"
import { VehicleStatus } from "@prisma/client"

// VIN validation regex
const vinRegex = /^[A-HJ-NPR-Z0-9]{17}$/

// License plate validation (basic format, can be customized)
const licensePlateRegex = /^[A-Z0-9 -]{1,10}$/

export const createVehicleSchema = z.object({
  imageUrl: z.string().url().nullable().optional(),
  make: z.string().trim().min(1, "Make is required"),
  model: z.string().trim().min(1, "Model is required"),
  year: z.union([
    z.string()
      .trim()
      .min(1, "Year is required")
      .regex(/^\d{4}$/, "Must be a valid year")
      .transform(Number),
    z.number()
  ])
  .refine((val) => val >= 1900 && val <= new Date().getFullYear() + 1, {
    message: "Year must be between 1900 and next year",
  }),
  vin: z.string()
    .trim()
    .regex(vinRegex, "Invalid VIN format (17 characters, no I, O, or Q)")
    .optional()
    .or(z.literal("")),
  licensePlate: z.string()
    .trim()
    .regex(licensePlateRegex, "Invalid license plate format")
    .optional()
    .or(z.literal("")),
  mileage: z.union([
    z.string()
      .trim()
      .min(1, "Mileage is required")
      .regex(/^\d+$/, "Must be a number")
      .transform(Number),
    z.number()
  ])
  .refine((val) => val >= 0, {
    message: "Mileage cannot be negative",
  }),
  purchaseDate: z.string()
    .trim()
    .min(1, "Purchase date is required")
    .transform((date: string) => {
      const parsed = new Date(date)
      if (isNaN(parsed.getTime())) {
        throw new Error("Invalid date format")
      }
      // Check if date is in the future
      if (parsed > new Date()) {
        throw new Error("Purchase date cannot be in the future")
      }
      return parsed
    }),
  purchasePrice: z.union([
    z.string()
      .trim()
      .min(1, "Purchase price is required")
      .regex(/^\d+(\.\d{1,2})?$/, "Must be a valid price")
      .transform(Number),
    z.number()
  ])
  .refine((val) => val >= 0, {
    message: "Purchase price cannot be negative",
  }),
  status: z.nativeEnum(VehicleStatus).default(VehicleStatus.ACTIVE),
})

export type CreateVehicleInput = z.input<typeof createVehicleSchema>
export type CreateVehicleOutput = z.output<typeof createVehicleSchema>

export const vehiclePatchSchema = z.object({
  imageUrl: z.string().url().nullable().optional(),
  make: z.string().trim().min(1).optional(),
  model: z.string().trim().min(1).optional(),
  year: z.number().min(1900).max(new Date().getFullYear() + 1).optional(),
  vin: z.string()
    .trim()
    .regex(vinRegex, "Invalid VIN format (17 characters, no I, O, or Q)")
    .optional()
    .or(z.literal("")),
  licensePlate: z.string()
    .trim()
    .regex(licensePlateRegex, "Invalid license plate format")
    .optional()
    .or(z.literal("")),
  mileage: z.number().min(0).optional(),
  purchaseDate: z.date().refine(
    (date) => date <= new Date(),
    "Purchase date cannot be in the future"
  ).optional(),
  purchasePrice: z.number().min(0).optional(),
  status: z.nativeEnum(VehicleStatus).optional(),
})

export type VehiclePatchInput = z.input<typeof vehiclePatchSchema>
