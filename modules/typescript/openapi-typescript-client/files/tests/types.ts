import { make } from "../src/index.js"
const api = make({ baseUrl: "http://localhost" })
void api.createWidget({ name: "One" })
// @ts-expect-error required path parameter
void api.getWidget()
// @ts-expect-error required body field
void api.createWidget({})
// @ts-expect-error exact optional property
void api.createWidget({ name: "One", note: undefined })
// @ts-expect-error readOnly field is excluded from requests
void api.createWidget({ id: "server-owned", name: "One" })
async function example() {
  const response = await api.getWidget("one")
  if (response.status === 404) {
    const message: string = response.data.message
    // @ts-expect-error wrong status branch
    void response.data.id
    return message
  }
  return response.data.id
}
void example
