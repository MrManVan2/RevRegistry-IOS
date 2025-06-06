import { NextResponse } from "next/server"
import { getServerSession } from "next-auth"
import { authOptions } from "@/app/api/auth/auth.config"
import { prisma } from "@/lib/prisma"
import { createVehicleSchema } from "@/schemas/vehicle"
import { z } from "zod"
import { VehicleStatus } from "@prisma/client"

export async function POST(req: Request) {
  try {
    const session = await getServerSession(authOptions)
    if (!session?.user?.id) {
      return new NextResponse("Unauthorized", { status: 401 })
    }

    const json = await req.json()
    const body = createVehicleSchema.parse(json)

    // Remove empty strings for optional fields
    const data = {
      ...body,
      userId: session.user.id,
      vin: body.vin || undefined,
      licensePlate: body.licensePlate || undefined,
      imageUrl: body.imageUrl || undefined,
      status: body.status || VehicleStatus.ACTIVE,
      purchaseDate: body.purchaseDate ? new Date(body.purchaseDate) : null
    }

    const vehicle = await prisma.vehicle.create({
      data
    })

    return NextResponse.json(vehicle)
  } catch (error) {
    if (error instanceof z.ZodError) {
      console.error("[VEHICLES_POST_VALIDATION]", error.errors)
      return new NextResponse(JSON.stringify(error.errors), { 
        status: 422,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    console.error("[VEHICLES_POST]", error)
    if (error instanceof Error) {
      return new NextResponse(error.message, { status: 400 })
    }
    return new NextResponse("Internal error", { status: 500 })
  }
}

export async function GET() {
  try {
    const session = await getServerSession(authOptions)
    if (!session?.user?.id) {
      return new NextResponse("Unauthorized", { status: 401 })
    }

    const vehicles = await prisma.vehicle.findMany({
      where: {
        userId: session.user.id  // Critical: Only return vehicles owned by the current user
      },
      orderBy: {
        createdAt: 'desc'
      },
      include: {
        _count: {
          select: {
            expenses: true,
            maintenance: true
          }
        }
      }
    })

    return NextResponse.json(vehicles)
  } catch (error) {
    console.error("[VEHICLES_GET]", error)
    return new NextResponse("Internal Server Error", { status: 500 })
  }
}
