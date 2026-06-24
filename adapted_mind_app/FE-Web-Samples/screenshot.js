const puppeteer = require('puppeteer');
(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  await page.goto('file:///Users/isara/4Y 1S/RP/FE-RP/01-select-student.html', {waitUntil: 'networkidle0'});
  await page.screenshot({path: '01.png'});
  await page.goto('file:///Users/isara/4Y 1S/RP/FE-RP/02-dashboard.html', {waitUntil: 'networkidle0'});
  await page.screenshot({path: '02.png'});
  await page.goto('file:///Users/isara/4Y 1S/RP/FE-RP/03-level-map.html', {waitUntil: 'networkidle0'});
  await page.screenshot({path: '03.png'});
  await browser.close();
})();
