import { NextRequest, NextResponse } from "next/server"
import { getServerSession } from "next-auth"
import { authOptions } from "@/app/api/auth/auth.config"
import { prisma } from "@/lib/prisma"
import { ExpenseType, ExpenseCategory } from "@prisma/client"
import * as z from "zod"

const expenseSchema = z.object({
  date: z.string(),
  amount: z.union([z.number(), z.string()]).transform((val) => {
    if (typeof val === 'string') {
      // Remove dollar signs, commas, and whitespace
      const cleaned = val.replace(/[$,\s]/g, '')
      const parsed = parseFloat(cleaned)
      if (isNaN(parsed) || parsed < 0) {
        throw new Error("Invalid amount")
      }
      return Math.round(parsed * 100) / 100
    }
    return val
  }),
  description: z.string().optional(),
  type: z.nativeEnum(ExpenseType),
  category: z.nativeEnum(ExpenseCategory).optional(),
  notes: z.string().optional(),
  mileage: z.union([z.number(), z.string()]).optional().transform((val) => {
    if (val === undefined || val === null || val === '') return undefined
    if (typeof val === 'string') {
      const parsed = parseInt(val, 10)
      return isNaN(parsed) ? undefined : parsed
    }
    return val
  }),
  vehicleId: z.string(),
  receipt: z.object({
    fileUrl: z.string(),
    fileName: z.string(),
  }).optional(),
})

interface SessionUser {
  id: string
  email: string
  name?: string
}

export async function POST(req: NextRequest) {
  try {
    const session = await getServerSession(authOptions)

    if (!session?.user) {
      return new NextResponse(
        JSON.stringify({ message: "Unauthorized" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      )
    }

    const user = session.user as SessionUser
    const json = await req.json()
    const validatedBody = expenseSchema.parse(json)

    // Verify vehicle ownership
    const vehicle = await prisma.vehicle.findUnique({
      where: {
        id: validatedBody.vehicleId,
        userId: user.id,
      },
      select: {
        mileage: true,
      },
    })

    if (!vehicle) {
      return new NextResponse(
        JSON.stringify({ message: "Vehicle not found" }),
        { status: 404, headers: { "Content-Type": "application/json" } }
      )
    }

    // Create expense
    const expense = await prisma.expense.create({
      data: {
        date: new Date(validatedBody.date),
        amount: validatedBody.amount,
        description: validatedBody.description,
        type: validatedBody.type,
        category: validatedBody.category || ExpenseCategory.OTHER,
        notes: validatedBody.notes,
        mileage: validatedBody.mileage || 0,
        userId: user.id,
        vehicleId: validatedBody.vehicleId,
        ...(validatedBody.receipt && {
          receipt: {
            create: {
              fileUrl: validatedBody.receipt.fileUrl,
              fileName: validatedBody.receipt.fileName,
              fileType: validatedBody.receipt.fileName.split('.').pop() ?? 'unknown',
            }
          }
        })
      },
      include: {
        vehicle: {
          select: {
            make: true,
            model: true,
            year: true,
            mileage: true,
            id: true,
          },
        },
        receipt: true,
      },
    })

    // If mileage is higher than current vehicle mileage and mileage is provided, update vehicle
    if (validatedBody.mileage && validatedBody.mileage > vehicle.mileage) {
      await prisma.vehicle.update({
        where: { id: validatedBody.vehicleId },
        data: { mileage: validatedBody.mileage }
      })
    }

    return new NextResponse(JSON.stringify(expense), {
      status: 201,
      headers: { "Content-Type": "application/json" },
    })
  } catch (error) {
    if (error instanceof z.ZodError) {
      const errors = error.errors.map(err => {
        let message = err.message
        if (err.code === "invalid_type") {
          const field = err.path[err.path.length - 1]
          message = `Invalid type for field ${field}`
        }
        return {
          path: err.path,
          message
        }
      })
      return new NextResponse(
        JSON.stringify({ message: "Validation error", errors }),
        { status: 422, headers: { "Content-Type": "application/json" } }
      )
    }

    console.error("[EXPENSE_POST]", error)
    return new NextResponse(
      JSON.stringify({ message: "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    )
  }
}

export async function GET(req: NextRequest) {
  try {
    const session = await getServerSession(authOptions)

    if (!session?.user) {
      return new NextResponse(
        JSON.stringify({ message: "Unauthorized" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      )
    }

    const user = session.user as SessionUser
    const searchParams = req.nextUrl.searchParams
    const minAmount = searchParams.get("minAmount")
    const maxAmount = searchParams.get("maxAmount")
    const startDate = searchParams.get("startDate")
    const endDate = searchParams.get("endDate")
    const category = searchParams.get("category")
    const vehicleId = searchParams.get("vehicleId")

    const where: any = {
      userId: user.id,
    }

    if (minAmount) {
      where.amount = { gte: parseFloat(minAmount) }
    }

    if (maxAmount) {
      where.amount = { ...where.amount, lte: parseFloat(maxAmount) }
    }

    if (startDate) {
      where.date = { gte: new Date(startDate) }
    }

    if (endDate) {
      where.date = { ...where.date, lte: new Date(endDate) }
    }

    if (category) {
      where.category = category as ExpenseCategory
    }

    if (vehicleId) {
      where.vehicleId = vehicleId
    }

    const expenses = await prisma.expense.findMany({
      where,
      include: {
        vehicle: {
          select: {
            make: true,
            model: true,
            year: true,
            mileage: true,
            id: true,
          },
        },
        receipt: true,
      },
      orderBy: {
        date: "desc",
      },
    })

    return new NextResponse(JSON.stringify(expenses), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    })
  } catch (error) {
    console.error("[EXPENSE_GET]", error)
    return new NextResponse(
      JSON.stringify({ message: "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    )
  }
}
