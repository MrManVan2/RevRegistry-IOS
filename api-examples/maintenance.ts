import { NextResponse } from "next/server"
import { getServerSession } from "next-auth"
import { authOptions } from "@/app/api/auth/auth.config"
import { prisma } from "@/lib/prisma"
import { z } from "zod"
import { MaintenanceType, MaintenanceStatus } from "@prisma/client"

const createMaintenanceSchema = z.object({
  vehicleId: z.string(),
  type: z.nativeEnum(MaintenanceType),
  status: z.nativeEnum(MaintenanceStatus),
  date: z.string(),
  mileage: z.number(),
  description: z.string(),
  cost: z.number(),
  serviceProvider: z.string().optional(),
  notes: z.string().optional(),
  attachments: z.array(z.string()).optional(),
})

export async function GET() {
  const session = await getServerSession(authOptions)
  if (!session?.user?.id) {
    return new NextResponse("Unauthorized", { status: 401 })
  }

  try {
    const maintenance = await prisma.maintenance.findMany({
      where: {
        userId: session.user.id,
      },
      include: {
        vehicle: true,
      },
      orderBy: {
        dueDate: "asc",
      },
    })

    return NextResponse.json(maintenance)
  } catch (error) {
    console.error("[MAINTENANCE_GET]", error)
    return new NextResponse("Internal error", { status: 500 })
  }
}

export async function POST(request: Request) {
  const session = await getServerSession(authOptions)
  if (!session?.user?.id) {
    return new NextResponse("Unauthorized", { status: 401 })
  }

  try {
    const body = await request.json()
    const validatedData = createMaintenanceSchema.parse(body)

    // Verify the vehicle belongs to the user
    const vehicle = await prisma.vehicle.findFirst({
      where: {
        id: validatedData.vehicleId,
        userId: session.user.id,
      },
    })

    if (!vehicle) {
      return new NextResponse("Vehicle not found", { status: 404 })
    }

    // Convert date string to Date object
    const serviceDate = new Date(validatedData.date)

    // Combine service provider and notes, and handle attachments in notes
    let combinedNotes = validatedData.notes || ""
    if (validatedData.serviceProvider) {
      combinedNotes = `Service Provider: ${validatedData.serviceProvider}${combinedNotes ? '\n\n' + combinedNotes : ''}`
    }
    if (validatedData.attachments && validatedData.attachments.length > 0) {
      const attachmentSection = `\n\nAttachments:\n${validatedData.attachments.join('\n')}`
      combinedNotes += attachmentSection
    }

    // Create the maintenance record
    const maintenance = await prisma.maintenance.create({
      data: {
        userId: session.user.id,
        vehicleId: validatedData.vehicleId,
        type: validatedData.type,
        status: validatedData.status,
        description: validatedData.description,
        cost: validatedData.cost,
        mileage: validatedData.mileage,
        dueMileage: validatedData.mileage + 5000, // Default: next service in 5000 miles
        notes: combinedNotes || undefined,
        date: serviceDate,
        dueDate: serviceDate,
        completedDate: validatedData.status === MaintenanceStatus.COMPLETED ? serviceDate : undefined,
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      include: {
        vehicle: true,
      },
    })

    return NextResponse.json(maintenance)
  } catch (error) {
    console.error("[MAINTENANCE_POST]", error)
    
    if (error instanceof z.ZodError) {
      return new NextResponse("Invalid request data", { status: 400 })
    }
    
    return new NextResponse("Internal error", { status: 500 })
  }
} 