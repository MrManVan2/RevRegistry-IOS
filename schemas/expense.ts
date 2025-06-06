import * as z from "zod"
import { ExpenseType, ExpenseCategory } from "@prisma/client"

// Helper function to parse amount strings with dollar signs and decimals
const parseAmount = (value: string): number => {
  // Remove dollar signs, commas, and whitespace
  const cleaned = value.replace(/[$,\s]/g, '')
  const parsed = parseFloat(cleaned)
  
  if (isNaN(parsed) || parsed < 0) {
    throw new Error("Invalid amount")
  }
  
  return Math.round(parsed * 100) / 100 // Round to 2 decimal places
}

const baseExpenseSchema = z.object({
  type: z.nativeEnum(ExpenseType),
  amount: z.string()
    .min(1, "Amount is required")
    .refine((value) => {
      try {
        parseAmount(value)
        return true
      } catch {
        return false
      }
    }, "Please enter a valid amount"),
  date: z.string().min(1, "Date is required"),
  description: z.string().optional(),
  vendor: z.string().optional(),
  mileage: z.string().optional(),
  category: z.nativeEnum(ExpenseCategory).optional(),
  tags: z.array(z.string()).default([]),
  vehicleId: z.string().min(1, "Vehicle is required"),
  maintenanceId: z.string().optional(),
  receipt: z.object({
    fileUrl: z.string(),
    fileName: z.string(),
  }).optional(),
})

export const expenseFormSchema = baseExpenseSchema.transform((data) => ({
  ...data,
  amount: parseAmount(data.amount),
  date: new Date(data.date).toISOString(),
  mileage: data.mileage ? parseInt(data.mileage, 10) : undefined,
}))

export type ExpenseFormData = z.infer<typeof baseExpenseSchema>
