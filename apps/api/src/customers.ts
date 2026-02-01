import { Hono } from 'hono'
import { z } from 'zod'
import { HTTPException } from 'hono/http-exception'

const app = new Hono()

const customerSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1),
  tags: z.array(z.string()).optional().default([])
})

const customerUpdateSchema = z.object({
  email: z.string().email().optional(),
  name: z.string().min(1).optional(),
  tags: z.array(z.string()).optional()
})

const listQuerySchema = z.object({
  tag: z.string().optional()
})

app.post('/customers', async (c) => {
  try {
    const body = await c.req.json()
    const validated = customerSchema.parse(body)
    
    c.status(201)
    return c.json({
      id: 'temp-id',
      ...validated,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    })
  } catch (error) {
    if (error instanceof z.ZodError) {
      throw new HTTPException(400, { message: 'Validation error' })
    }
    throw error
  }
})

app.put('/customers/:id', async (c) => {
  try {
    const id = c.req.param('id')
    const body = await c.req.json()
    const validated = customerUpdateSchema.parse(body)
    
    return c.json({
      id,
      ...validated,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    })
  } catch (error) {
    if (error instanceof z.ZodError) {
      throw new HTTPException(400, { message: 'Validation error' })
    }
    throw error
  }
})

app.get('/customers', async (c) => {
  try {
    const { tag } = listQuerySchema.parse(c.req.query())
    
    return c.json({
      customers: [],
      ...(tag && { filter: { tag } })
    })
  } catch (error) {
    if (error instanceof z.ZodError) {
      throw new HTTPException(400, { message: 'Validation error' })
    }
    throw error
  }
})

app.get('/customers/:id', async (c) => {
  const id = c.req.param('id')
  
  return c.json({
    id,
    email: 'example@test.com',
    name: 'Test Customer',
    tags: [],
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  })
})

export default app
