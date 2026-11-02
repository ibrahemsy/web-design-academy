import { chromium } from 'playwright';

const url = process.env.DEPLOYED_URL;
if (!url) {
  throw new Error('DEPLOYED_URL is required');
}

const browser = await chromium.launch({ headless: true });
try {
  const page = await browser.newPage();
  const pageErrors = [];
  page.on('pageerror', (error) => pageErrors.push(error.message));

  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForFunction(
    () => {
      const hasCanvas = (root) => {
        if (root.querySelector('canvas')) return true;
        return [...root.querySelectorAll('*')].some(
          (element) => element.shadowRoot && hasCanvas(element.shadowRoot),
        );
      };
      const host = document.querySelector('flutter-view, flt-glass-pane');
      return Boolean(host && hasCanvas(document));
    },
    null,
    { timeout: 60000 },
  );

  const result = await page.evaluate(() => {
    const hasCanvas = (root) => {
      if (root.querySelector('canvas')) return true;
      return [...root.querySelectorAll('*')].some(
        (element) => element.shadowRoot && hasCanvas(element.shadowRoot),
      );
    };
    return {
      title: document.title,
      flutterHost: Boolean(document.querySelector('flutter-view, flt-glass-pane')),
      canvas: hasCanvas(document),
    };
  });

  if (!result.title.includes('أكاديمية تصميم الويب')) {
    throw new Error(`Unexpected deployed page title: ${result.title}`);
  }
  if (!result.flutterHost || !result.canvas) {
    throw new Error('Flutter web renderer did not initialize its canvas host');
  }
  if (pageErrors.length > 0) {
    throw new Error(`Browser runtime errors: ${pageErrors.join(' | ')}`);
  }

  console.log('PASS: Chromium opened the deployed academy and Flutter rendered its canvas.');
  console.log(`PASS: page title: ${result.title}`);
} finally {
  await browser.close();
}
