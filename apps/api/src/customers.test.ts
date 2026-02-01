import { describe, it, expect } from 'vitest'
import { testClient } from 'hono/testing'
import customers from './customers'

describe('Customer API - Tags', () => {
  const client = testClient(customers)

  it('should create customer with tags', async () => {
    const response = await (client as any).customers.$post({
      json: {
        email: 'test@example.com',
        name: 'Test Customer',
        tags: ['vip', 'priority']
      }
    })

    expect(response.status).toBe(201)
    const json = await response.json()
    expect(json.tags).toEqual(['vip', 'priority'])
  })

  it('should create customer without tags (defaults to empty array)', async () => {
    const response = await (client as any).customers.$post({
      json: {
        email: 'test2@example.com',
        name: 'Test Customer 2'
      }
    })

    expect(response.status).toBe(201)
    const json = await response.json()
    expect(json.tags).toEqual([])
  })

  it('should update customer tags', async () => {
    const response = await (client as any).customers[':id'].$put({
      param: { id: 'test-id' },
      json: {
        tags: ['new-tag', 'updated-tag']
      }
    })

    const json = await response.json()
    expect(json.tags).toEqual(['new-tag', 'updated-tag'])
  })

  it('should list customers filtered by tag', async () => {
    const response = await (client as any).customers.$get({
      query: { tag: 'vip' }
    })

    const json = await response.json()
    expect(json.filter).toEqual({ tag: 'vip' })
    expect(json.customers).toEqual([])
  })

  it('should reject invalid email format', async () => {
    const response = await (client as any).customers.$post({
      json: {
        email: 'invalid-email',
        name: 'Test Customer',
        tags: ['vip']
      }
    })

    expect(response.status).toBe(400)
  })

  it('should reject empty name', async () => {
    const response = await (client as any).customers.$post({
      json: {
        email: 'test@example.com',
        name: '',
        tags: ['vip']
      }
    })

    expect(response.status).toBe(400)
  })
})
