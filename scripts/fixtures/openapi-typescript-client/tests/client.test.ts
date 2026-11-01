import { expect, test } from 'bun:test'
import { make, ClientError } from '../src/index.js'
import type { Fetch } from '../src/index.js'
import * as v from '../src/generated/client/validators.js'

const widget = { id: '1', name: 'One', state: 'active' as const, owner: null }
const input = { name: 'One', state: 'active' as const, owner: null }
test('validators retain the supported schema semantics', () => {
  expect(v.WidgetOutput.parse(widget)).toEqual(widget)
  for (const invalid of [{ ...widget, extra: true }, { ...widget, name: 1 }, { ...widget, name: null },
    { ...widget, state: 'other' }, { ...widget, tag: undefined }, { ...widget, note: undefined },
    { ...widget, secret: 'hidden' }, { id: '1', state: 'active' as const, owner: null }]) {
    expect(v.WidgetOutput.safeParse(invalid).success).toBe(false)
  }
  expect(v.WidgetInput.safeParse({ ...input, id: 'no' }).success).toBe(false)
  expect(v.WidgetInput.safeParse({ ...input, secret: 'allowed' }).success).toBe(true)
  expect(v.WidgetOutput.parse({ ...widget, tag: null }).tag).toBeNull()
  expect(v.WidgetOutput.safeParse({ ...widget, created: 2 }).success).toBe(false)
  expect(v.WidgetOutput.parse({ ...widget, created: '2026-11-01T00:00:00Z' }).created).toBe('2026-11-01T00:00:00Z')
  expect(v.OpenOutput.parse({ value: 'yes', extra: 123 })).toEqual({ value: 'yes', extra: 123 })
  expect(v.TreeOutput.safeParse({ value: 'root', children: [{ value: 'child', children: [{ value: 1 }] }] }).success).toBe(false)
  expect(v.TreeOutput.parse({ value: 'root', children: [{ value: 'child' }] }).children?.[0]?.value).toBe('child')
  expect(v.OverlapOutput.safeParse(1).success).toBe(false)
  expect(v.OverlapOutput.safeParse(1.5).success).toBe(true)
  expect(v.OverlapOutput.safeParse(-1).success).toBe(true)
  expect(v.InclusiveOutput.safeParse(1).success).toBe(true)
  expect(v.CombinedOutput.safeParse({ a: 'yes' }).success).toBe(false)
  expect(v.CombinedOutput.safeParse({ a: 'yes', b: 'no' }).success).toBe(false)
  expect(v.CombinedOutput.parse({ a: 'yes', b: 2, extra: true })).toEqual({ a: 'yes', b: 2, extra: true })
  expect(v.TaggedOutput.safeParse({ kind: 'cat', barks: true }).success).toBe(false)
  expect(v.TaggedOutput.safeParse({ kind: 'cat', meows: true }).success).toBe(true)
})

test('real HTTP serialization, status validation, empty/primitive/array data and isolation', async () => {
  const requests: { url: URL; headers: Headers; body: unknown }[] = []
  const server = Bun.serve({ hostname: '127.0.0.1', port: 0, async fetch(request) {
    const url = new URL(request.url)
    const body = request.method === 'POST' ? await request.json() : undefined
    requests.push({ url, headers: request.headers, body })
    if (url.pathname.endsWith('/primitive')) return Response.json('hello')
    if (url.pathname.endsWith('/array')) return Response.json([widget])
    if (url.pathname.endsWith('/empty') || url.pathname.endsWith('/none')) return new Response(null, { status: 204 })
    if (url.pathname.endsWith('/missing')) return Response.json({ message: 'Not found' }, { status: 404 })
    if (url.pathname.endsWith('/invalid-error')) return Response.json(widget, { status: 404 })
    if (url.pathname.endsWith('/invalid')) return Response.json({ ...widget, name: 1 })
    if (url.pathname.endsWith('/unknown')) return Response.json(widget, { status: 202 })
    if (url.pathname.endsWith('/media')) return new Response(JSON.stringify(widget), { headers: { 'content-type': 'text/plain' } })
    if (url.pathname.endsWith('/json')) return new Response('{', { headers: { 'content-type': 'application/json' } })
    if (body && typeof body === 'object' && 'name' in body && body.name === 'invalid') return Response.json({ message: 'Invalid' }, { status: 422 })
    return Response.json(widget, { status: request.method === 'POST' ? 201 : 200 })
  } })
  try {
    const baseUrl = `http://127.0.0.1:${server.port}/api`
    let injected = 0
    const fetch: Fetch = (url, init) => { injected++; return globalThis.fetch(url, init) }
    const first = make({ baseUrl, fetch, headers: { 'x-client': 'first', 'x-default': 'yes' } })
    const second = make({ baseUrl, headers: { 'x-client': 'second' } })
    const response = await first.getWidget('a/b ?#', { tags: ['a b', 'c/d'], filter: { name: 'One & two' } }, { headers: { 'x-client': 'overridden' } })
    expect(response.status).toBe(200)
    if (response.status === 200) expect(response.data).toEqual(widget)
    const request = requests[0]!
    expect(request.url.pathname).toBe('/api/widgets/a%2Fb%20%3F%23')
    expect(request.url.searchParams.getAll('tags')).toEqual(['a b', 'c/d'])
    expect(request.url.searchParams.get('filter[name]')).toBe('One & two')
    expect(request.headers.get('x-client')).toBe('overridden')
    expect(request.headers.get('x-default')).toBe('yes')
    const created = await first.createWidget(input)
    expect(created.status).toBe(201)
    expect(requests.at(-1)?.body).toEqual(input)
    expect(requests.at(-1)?.headers.get('content-type')).toBe('application/json')
    expect((await first.createWidget({ ...input, name: 'invalid' })).status).toBe(422)
    const missing = await first.getWidget('missing')
    expect(missing.status).toBe(404)
    if (missing.status === 404) expect(missing.data.message).toBe('Not found')
    for (const [id, code] of [['invalid', 'invalid-payload'], ['invalid-error', 'invalid-payload'], ['unknown', 'unsupported-status'], ['media', 'unsupported-media'], ['json', 'invalid-json']] as const) {
      try { await first.getWidget(id); throw new Error('Expected rejection') }
      catch (error) { expect(error).toBeInstanceOf(ClientError); expect((error as ClientError).code).toBe(code) }
    }
    const empty = await first.getWidget('none')
    expect(empty.status).toBe(204)
    expect(empty.data).toBeUndefined()
    expect((await first.getEmpty()).data).toBeUndefined()
    expect((await first.getPrimitive()).data).toBe('hello')
    expect((await first.getArray()).data).toEqual([widget])
    await second.getWidget('1')
    expect(requests.at(-1)?.headers.get('x-client')).toBe('second')
    expect(injected).toBe(requests.length - 1)
    const broken = make({ baseUrl, fetch: async () => { throw new Error('offline') } })
    await expect(broken.getWidget('1')).rejects.toMatchObject({ code: 'transport' })
  } finally { await server.stop(true) }
})
