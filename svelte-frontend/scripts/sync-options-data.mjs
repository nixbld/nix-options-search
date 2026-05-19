import fs from 'node:fs';
import path from 'node:path';

const cwd = process.cwd();
const sourceArg = process.argv[2] || '../result';
const sourceRoot = path.resolve(cwd, sourceArg);
const outDir = path.resolve(cwd, 'public/data');

const wanted = ['options-25.11.json', 'options-unstable.json'];

function findFile(root, fileName) {
  const stack = [root];
  while (stack.length) {
    const dir = stack.pop();
    let entries;
    try {
      entries = fs.readdirSync(dir, { withFileTypes: true });
    } catch {
      continue;
    }

    for (const entry of entries) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        stack.push(full);
      } else if (entry.isFile() && entry.name === fileName) {
        return full;
      }
    }
  }
  return null;
}

if (!fs.existsSync(sourceRoot)) {
  console.error(`Source path does not exist: ${sourceRoot}`);
  process.exit(1);
}

fs.mkdirSync(outDir, { recursive: true });

let copied = 0;
for (const name of wanted) {
  const found = findFile(sourceRoot, name);
  if (!found) {
    console.warn(`Missing: ${name} (searched in ${sourceRoot})`);
    continue;
  }
  const dest = path.join(outDir, name);
  fs.copyFileSync(found, dest);
  console.log(`Copied ${name} <- ${found}`);
  copied += 1;
}

if (copied === 0) {
  console.error('No options JSON files were copied.');
  process.exit(1);
}

console.log(`Done. Copied ${copied} file(s) to ${outDir}`);
