// extract_book.js
// Copies the book data from index.html into book.json.
// It only COPIES. It never changes any text.
//
// Run:  node extract_book.js index.html book.json

const fs = require('fs');
const vm = require('vm');

const [inputPath, outputPath] = process.argv.slice(2);
const html = fs.readFileSync(inputPath, 'utf8');

// 1) Find the <script> part of the page.
const script = html.match(/<script[^>]*>([\s\S]*?)<\/script>/i)[1];

// 2) Keep only the data part (before the page code starts).
const dataPart = script.slice(0, script.indexOf('const chaptersEl'));

// 3) Run that data part safely in an empty sandbox.
//    'const' variables do not become properties of the sandbox,
//    so we add a line at the end to export them.
const sandbox = {};
vm.createContext(sandbox);
vm.runInContext(dataPart + '\n;this.out = { introTabs, chapters };', sandbox);
const { introTabs, chapters } = sandbox.out;

// 4) Save as JSON. Text is copied exactly as it is.
const book = {
  intro: { tabs: introTabs },
  chapters: chapters.map((c) => ({
    num: c.num, title: c.title, desc: c.desc, color: c.color, tabs: c.tabs,
  })),
};
fs.writeFileSync(outputPath, JSON.stringify(book, null, 1), 'utf8');

// 5) Verify: every tab text must be identical in the JSON file.
const back = JSON.parse(fs.readFileSync(outputPath, 'utf8'));
let ok = true, tabCount = 0, chars = 0;
const check = (a, b) => { tabCount++; chars += a.length; if (a !== b) ok = false; };
introTabs.forEach((t, i) => check(t.content, back.intro.tabs[i].content));
chapters.forEach((c, ci) =>
  c.tabs.forEach((t, ti) => check(t.content, back.chapters[ci].tabs[ti].content)));

console.log('Intro tabs:', introTabs.length);
console.log('Chapters:', chapters.length);
chapters.forEach((c) => console.log(' -', c.num, '|', c.title, '| tabs:', c.tabs.length));
console.log('Tabs checked:', tabCount, '| characters:', chars);
console.log(ok ? 'VERIFIED: text is identical' : 'ERROR: text differs!');
