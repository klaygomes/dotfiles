#!/usr/bin/env node
import { readFileSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { homedir } from 'node:os';
import { join } from 'node:path';

const [input, output] = process.argv.slice(2);
if (!input || !output || input === output) { console.error('usage: math.mjs <page.src.html> <page.html>'); process.exit(1); }

const home = process.env.LEARNING_LADDER_HOME || join(homedir(), '.local/share/klay-learning-ladder');
const temml = createRequire(join(home, 'node', 'package.json'))('temml');

let count = 0, failed = 0;
const render = (tex, displayMode) => {
  count++;
  try { return temml.renderToString(tex, { displayMode, throwOnError: true, annotate: true }); }
  catch (err) { failed++; console.error(`math error in "${tex.slice(0, 60)}": ${err.message}`); return tex; }
};

const convert = text => text
  .replace(/\\\[([\s\S]+?)\\\]/g, (_, tex) => render(tex.trim(), true))
  .replace(/\\\(([\s\S]+?)\\\)/g, (_, tex) => render(tex.trim(), false));

const html = readFileSync(input, 'utf8')
  .split(/(<(script|style)\b[\s\S]*?<\/\2>)/i)
  .map((part, i) => (i % 3 === 0 ? convert(part) : i % 3 === 1 ? part : ''))
  .join('');

writeFileSync(output, html);
console.log(`${count} formulas, ${failed} failed -> ${output}`);
process.exit(failed ? 2 : 0);
