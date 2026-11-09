import { test, expect } from "@playwright/test"
test("production hydration, local fonts, themes and exact code copy", async ({ page, context }) => {
  const errors: string[] = []
  const fonts: string[] = []
  const assets: { url: string; status: number; type: string | null }[] = []
  page.on("requestfailed", (request) =>
    errors.push(`${request.url()}: ${request.failure()?.errorText}`),
  )
  page.on("console", (message) => {
    if (message.type() === "error") errors.push(message.text())
  })
  page.on("pageerror", (e) => errors.push(e.message))
  page.on("response", (r) => {
    if (r.url().includes("/assets/"))
      assets.push({ url: r.url(), status: r.status(), type: r.headers()["content-type"] ?? null })
    if (r.url().includes(".woff2")) {
      expect(r.status()).toBe(200)
      fonts.push(r.url())
    }
  })
  await page.goto("/docs/content/docs/index")
  await expect(page.locator("html")).toHaveAttribute("data-theme", /light|dark/)
  await expect(page.getByRole("heading", { name: "Welcome", exact: true })).toBeVisible()
  expect(
    await page.evaluate(async () => {
      const serif = await document.fonts.load('18px "Geist Serif"')
      const mono = await document.fonts.load('14px "Paper Mono"')
      return (
        serif.length > 0 &&
        mono.length > 0 &&
        document.fonts.check('18px "Geist Serif"') &&
        document.fonts.check('14px "Paper Mono"')
      )
    }),
    JSON.stringify({ errors, assets }),
  ).toBe(true)
  expect(
    await page
      .locator("article p")
      .first()
      .evaluate((e) => getComputedStyle(e).fontFamily),
  ).toContain("Geist Serif")
  expect(
    await page
      .locator("pre code")
      .first()
      .evaluate((e) => getComputedStyle(e).fontFamily),
  ).toContain("Paper Mono")
  expect(fonts.length).toBeGreaterThanOrEqual(2)
  expect(fonts.every((url) => new URL(url).origin === new URL(page.url()).origin)).toBe(true)
  const example = page.getByRole("region", { name: "typescript example" })
  const source = await example.locator("code").textContent()
  const token = example.locator("code span span").first()
  const light = await token.evaluate((e) => getComputedStyle(e).color)
  await page.getByRole("button", { name: "Toggle theme" }).click()
  await expect(page.locator("html")).toHaveAttribute("data-theme", "dark")
  expect(await token.evaluate((e) => getComputedStyle(e).color)).not.toBe(light)
  await example.getByRole("button", { name: "Copy", exact: true }).click()
  await expect(example.getByRole("button", { name: "Copied", exact: true })).toBeVisible()
  expect(await page.evaluate(() => navigator.clipboard.readText())).toBe(source)
  await expect(page.locator("pre literal-markup")).toHaveCount(0)
  await expect(
    page.getByRole("region", { name: "unknown-language example" }).locator("code"),
  ).toHaveText("<literal-markup>Keep this source intact.</literal-markup>\n")
  expect(errors).toEqual([])
  void context
})
test("keyboard search and missing document", async ({ page }) => {
  await page.goto("/")
  await expect(page.locator("html")).toHaveAttribute("data-theme", /light|dark/)
  const search = page.getByRole("searchbox", { name: "Search documents" })
  await search.focus()
  await search.fill("Welcome")
  await page.keyboard.press("Tab")
  await page.keyboard.press("Enter")
  await expect(page).toHaveURL(/\/docs\/content\/docs\/index$/)
  const response = await page.goto("/docs/missing")
  expect(response?.status()).toBe(404)
  await expect(page.getByRole("heading", { name: "Document not found" })).toBeVisible()
})
test("small screen navigation dialog", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await page.goto("/")
  await expect(page.locator("html")).toHaveAttribute("data-theme", /light|dark/)
  await page.getByRole("button", { name: "Open navigation" }).click()
  const dialog = page.getByRole("dialog", { name: "Navigation" })
  await expect(dialog).toBeVisible()
  await dialog.getByRole("link", { name: "Welcome", exact: true }).click()
  await expect(dialog).not.toBeVisible()
  await expect(page).toHaveURL(/\/docs\/content\/docs\/index$/)
})
