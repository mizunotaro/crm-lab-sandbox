import { serve } from '@hono/node-server'
import customers from './src/customers'

const app = customers

serve({ fetch: app.fetch, port: 3000 })

console.log('Server running on http://localhost:3000')
