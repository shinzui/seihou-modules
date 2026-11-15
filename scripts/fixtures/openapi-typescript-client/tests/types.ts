import { make } from "../src/index.js"
const api = make({ baseUrl: "http://localhost" })
// @ts-expect-error required path parameter
void api.getWidget()
// @ts-expect-error required body fields
void api.createWidget({})
async function example() {
  const response = await api.getWidget("one")
  if (response.status === 404) {
    const message: string = response.data.message
    // @ts-expect-error status-specific response type
    void response.data.id
    return message
  }
}
void example
