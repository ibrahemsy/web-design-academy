import { chromium } from 'playwright';

const url = process.env.DEPLOYED_URL;
if (!url) throw new Error('DEPLOYED_URL is required');

const browser = await chromium.launch({ headless: true });
try {
  const page = await browser.newPage({ viewport: { width: 1440, height: 1000 } });
  const pageErrors = [];
  const failedRequests = [];
  const failedResponses = [];
  const consoleErrors = [];
  page.on('pageerror', error => pageErrors.push(error.message));
  page.on('console', message => {
    if (message.type() === 'error') consoleErrors.push(message.text());
  });
  page.on('requestfailed', request => failedRequests.push(
    `${request.method()} ${request.url()}: ${request.failure()?.errorText ?? 'request failed'}`,
  ));
  page.on('response', response => {
    if (response.status() >= 400) failedResponses.push(`${response.status()} ${response.url()}`);
  });

  const response = await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
  if (!response || !response.ok()) {
    throw new Error(`Deployed page returned HTTP ${response?.status() ?? 'no response'}`);
  }

  try {
    await page.waitForFunction(() => {
      const host = document.querySelector('flutter-view, flt-glass-pane');
      if (!host) return false;
      const rect = host.getBoundingClientRect();
      return rect.width > 0 && rect.height > 0;
    }, null, { timeout: 60000 });
  } catch {
    const diagnostic = await diagnostics(page);
    throw new Error(`Flutter did not initialize in Chromium: ${JSON.stringify({
      ...diagnostic, pageErrors, consoleErrors, failedRequests, failedResponses,
    })}`);
  }

  await page.waitForTimeout(2000);
  const result = await diagnostics(page);
  if (!result.title.includes('الأكاديمية البرمجية i.z')) {
    throw new Error(`Unexpected deployed page title: ${result.title}`);
  }
  if (pageErrors.length || failedRequests.length || failedResponses.length) {
    throw new Error(`Browser errors: ${JSON.stringify({ pageErrors, failedRequests, failedResponses })}`);
  }
  console.log('PASS: Chromium loaded the deployed I.Z Programming Academy and Flutter created a visible host.');
  console.log(`Flutter render diagnostics: ${JSON.stringify(result)}`);
} finally {
  await browser.close();
}

async function diagnostics(page) {
  return page.evaluate(() => {
    const host = document.querySelector('flutter-view, flt-glass-pane');
    const rect = host?.getBoundingClientRect();
    return {
      title: document.title,
      readyState: document.readyState,
      body: document.body?.innerHTML.slice(0, 2500) ?? '',
      scripts: [...document.scripts].map(script => script.src),
      flutterHost: Boolean(host),
      hostSize: rect ? { width: Math.round(rect.width), height: Math.round(rect.height) } : null,
      canvasCount: document.querySelectorAll('canvas').length,
      customElements: [...document.querySelectorAll('*')]
        .filter(element => element.tagName.includes('-'))
        .slice(0, 25).map(element => element.tagName.toLowerCase()),
    };
  });
}
