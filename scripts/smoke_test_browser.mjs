import { chromium } from 'playwright';

const url = process.env.DEPLOYED_URL;
if (!url) {
  throw new Error('DEPLOYED_URL is required');
}

const browser = await chromium.launch({ headless: true });
try {
  const page = await browser.newPage({ viewport: { width: 1440, height: 1000 } });
  const pageErrors = [];
  const failedRequests = [];
  page.on('pageerror', (error) => pageErrors.push(error.message));
  page.on('requestfailed', (request) => {
    failedRequests.push(`${request.method()} ${request.url()}: ${request.failure()?.errorText ?? 'request failed'}`);
  });

  const response = await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
  if (!response || !response.ok()) {
    throw new Error(`Deployed page returned HTTP ${response?.status() ?? 'no response'}`);
  }

  // Flutter's web renderer may keep its drawing surface inside the flutter-view
  // custom element (including an implementation-owned shadow tree). Requiring
  // a queryable canvas is brittle across renderer and engine versions.
  await page.waitForFunction(() => {
    const host = document.querySelector('flutter-view, flt-glass-pane');
    if (!host) return false;
    const rect = host.getBoundingClientRect();
    return rect.width > 0 && rect.height > 0;
  }, null, { timeout: 60000 });

  await page.waitForTimeout(3000);
  const result = await page.evaluate(() => {
    const host = document.querySelector('flutter-view, flt-glass-pane');
    const rect = host?.getBoundingClientRect();
    const hasCanvas = (root) => {
      if (root.querySelector('canvas')) return true;
      return [...root.querySelectorAll('*')].some(
        (element) => element.shadowRoot && hasCanvas(element.shadowRoot),
      );
    };
    return {
      title: document.title,
      flutterHost: Boolean(host),
      hostTag: host?.tagName ?? null,
      hostSize: rect ? { width: Math.round(rect.width), height: Math.round(rect.height) } : null,
      canvas: hasCanvas(document),
      accessibleShadowRoot: Boolean(host?.shadowRoot),
      semanticsHost: Boolean(document.querySelector('flt-semantics-host, flt-semantics')),
      bodyTextLength: document.body.innerText.trim().length,
      customElements: [...document.querySelectorAll('*')]
        .filter((element) => element.tagName.includes('-'))
        .slice(0, 20)
        .map((element) => element.tagName.toLowerCase()),
    };
  });

  if (!result.title.includes('أكاديمية تصميم الويب')) {
    throw new Error(`Unexpected deployed page title: ${result.title}`);
  }
  if (!result.flutterHost || !result.hostSize ||
      result.hostSize.width < 100 || result.hostSize.height < 100) {
    throw new Error(`Flutter host did not become visible: ${JSON.stringify(result)}`);
  }
  if (pageErrors.length > 0) {
    throw new Error(`Browser runtime errors: ${pageErrors.join(' | ')}`);
  }
  if (failedRequests.length > 0) {
    throw new Error(`Browser network failures: ${failedRequests.join(' | ')}`);
  }

  console.log('PASS: Chromium loaded the deployed academy and Flutter created a visible host.');
  console.log(`PASS: page title: ${result.title}`);
  console.log(`Flutter render diagnostics: ${JSON.stringify(result)}`);
} catch (error) {
  const diagnostics = await pageDiagnostics(browser, url);
  console.error(`Browser smoke test failed. Diagnostics: ${JSON.stringify(diagnostics)}`);
  throw error;
} finally {
  await browser.close();
}

async function pageDiagnostics(browserInstance, targetUrl) {
  const page = await browserInstance.newPage();
  try {
    await page.goto(targetUrl, { waitUntil: 'domcontentloaded', timeout: 15000 });
    return await page.evaluate(() => ({
      title: document.title,
      readyState: document.readyState,
      body: document.body?.innerHTML.slice(0, 4000) ?? '',
      scripts: [...document.scripts].map((script) => script.src),
      flutterViewCount: document.querySelectorAll('flutter-view, flt-glass-pane').length,
    }));
  } catch (error) {
    return { diagnosticError: error.message };
  } finally {
    await page.close();
  }
}
