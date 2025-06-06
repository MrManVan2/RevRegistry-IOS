import { Expense as PrismaExpense, Prisma, ExpenseType, ExpenseCategory } from "@prisma/client"
import { BaseVehicle } from "./vehicle"

const expenseInclude = {
  vehicle: {
    select: {
      id: true,
      make: true,
      model: true,
      year: true,
      mileage: true,
    }
  },
  receipt: {
    select: {
      id: true,
      fileUrl: true,
      fileName: true,
      fileType: true,
    }
  }
} as const

export type ExpenseWithInclude = Prisma.ExpenseGetPayload<{
  include: typeof expenseInclude
}>

export const expenseQueryInclude = expenseInclude

export interface Expense {
  id: string
  type: ExpenseType
  amount: number
  date: Date
  description: string
  vehicleId: string
  userId: string
  receiptId?: string | null
  createdAt: Date
  updatedAt: Date
}

export interface LocalExpense extends ExpenseWithInclude {
  lineItems?: { description: string; cost: number }[]
}

export interface ReceiptInput {
  fileUrl: string
  fileName: string
}
