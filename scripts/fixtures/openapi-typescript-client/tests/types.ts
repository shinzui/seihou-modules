import { make } from '../src/index.js'
import type { WidgetInput, WidgetOutput, TaggedOutput } from '../src/index.js'
const api = make({ baseUrl: 'http://localhost' })
const input: WidgetInput = { name: 'A', state: 'active', owner: null }
void api.createWidget(input)
void api.getWidget('id', { tags: ['a', 'b'], filter: { name: 'A' } })
// @ts-expect-error required path parameter
void api.getWidget()
// @ts-expect-error required body fields
void api.createWidget({ name: 'A' })
// @ts-expect-error invalid enum
void api.createWidget({ ...input, state: 'other' })
// @ts-expect-error owner is nullable, name is not
void api.createWidget({ ...input, name: null })
// @ts-expect-error exact optional property
const bad: WidgetInput = { ...input, note: undefined }
// @ts-expect-error nullable optional is still exact
const nullableBad: WidgetInput = { ...input, tag: undefined }
// @ts-expect-error readOnly id is excluded from requests
void api.createWidget({ ...input, id: 'server-owned' })
// @ts-expect-error response writeOnly field is excluded
const response: WidgetOutput = { id: '1', ...input, secret: 'hidden' }
// @ts-expect-error discriminated union branch
const tagged: TaggedOutput = { kind: 'cat', barks: true }
async function narrowing() {
  const result = await api.getWidget('id')
  if (result.status === 200) {
    const id: string = result.data.id
    // @ts-expect-error wrong response branch
    result.data.message
    return id
  }
  if (result.status === 404) {
    const message: string = result.data.message
    // @ts-expect-error wrong response branch
    result.data.id
    return message
  }
  const empty: void = result.data
  return empty
}
void narrowing
