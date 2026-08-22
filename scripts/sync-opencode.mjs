#!/usr/bin/env node

import { cp, mkdir, readdir, readFile, stat, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";

const args = process.argv.slice(2);

function hasFlag(flag) {
  return args.includes(flag);
}

function valuesFor(flag) {
  const values = [];
  for (let index = 0; index < args.length; index += 1) {
    if (args[index] === flag && args[index + 1]) values.push(args[index + 1]);
  }
  return values;
}

async function exists(target) {
  try {
    await stat(target);
    return true;
  } catch {
    return false;
  }
}

async function walkSkillDirectories(root) {
  if (!(await exists(root))) return [];

  const found = [];
  async function visit(directory) {
    const entries = await readdir(directory, { withFileTypes: true });
    if (entries.some((entry) => entry.isFile() && entry.name === "SKILL.md")) {
      found.push(directory);
    }
    for (const entry of entries) {
      if (entry.isDirectory() && !entry.name.startsWith(".")) {
        await visit(path.join(directory, entry.name));
      }
    }
  }
  await visit(root);
  return found;
}

function frontmatterValue(content, key) {
  const match = content.match(/^---\s*\r?\n([\s\S]*?)\r?\n---/);
  if (!match) return "";
  const line = match[1].match(new RegExp(`^${key}:\\s*(.+)$`, "m"));
  if (!line) return "";
  return line[1].trim().replace(/^['"]|['"]$/g, "");
}

function validSkillName(name) {
  return /^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(name);
}

function tomlString(content, key) {
  const triple = content.match(new RegExp(`^${key}\\s*=\\s*\\"\\"\\"([\\s\\S]*?)\\"\\"\\"`, "m"));
  if (triple) return triple[1].trim();
  const single = content.match(new RegExp(`^${key}\\s*=\\s*([\\"'])(.*?)\\1\\s*$`, "m"));
  return single ? single[2].replace(/\\n/g, "\n").replace(/\\\"/g, '"') : "";
}

function renderTomlAgent(content, fallbackName) {
  const description = tomlString(content, "description") || fallbackName;
  const instructions = tomlString(content, "developer_instructions");
  const readOnly = tomlString(content, "sandbox_mode") === "read-only";
  const lines = [
    "---",
    `description: ${JSON.stringify(description.replace(/\s+/g, " ").trim())}`,
    "mode: subagent",
  ];
  if (readOnly) {
    lines.push("permission:", "  edit: deny", "  bash: deny");
  }
  lines.push("---", instructions || `Imported from Codex agent ${fallbackName}.`);
  return `${lines.join("\n")}\n`;
}

const checkOnly = hasFlag("--check");
const replaceSkills = hasFlag("--replace-skills");
const target = path.resolve(
  valuesFor("--target")[0] ||
    process.env.OPENCODE_CONFIG_DIR ||
    path.join(os.homedir(), ".config", "opencode"),
);
const skillSources = (valuesFor("--skill-source").length > 0
  ? valuesFor("--skill-source")
  : [path.join(process.cwd(), "codex", "skills")]
).map((source) => path.resolve(source));
const agentSources = (valuesFor("--agent-source").length > 0
  ? valuesFor("--agent-source")
  : [path.join(process.cwd(), ".opencode", "agents")]
).map((source) => path.resolve(source));

const skills = new Map();
const skippedSkills = [];
for (const source of skillSources) {
  for (const directory of await walkSkillDirectories(source)) {
    const content = await readFile(path.join(directory, "SKILL.md"), "utf8");
    const name = frontmatterValue(content, "name");
    const description = frontmatterValue(content, "description");
    if (!name || !description || !validSkillName(name)) {
      skippedSkills.push(path.relative(process.cwd(), directory));
      continue;
    }
    if (!skills.has(name)) skills.set(name, directory);
  }
}

const agents = new Map();
for (const source of agentSources) {
  if (!(await exists(source))) continue;
  for (const entry of await readdir(source, { withFileTypes: true })) {
    if (!entry.isFile() || !/\.(md|toml)$/i.test(entry.name)) continue;
    const name = entry.name.replace(/\.(md|toml)$/i, "");
    if (!agents.has(name)) agents.set(name, path.join(source, entry.name));
  }
}

const result = {
  target,
  checkOnly,
  skills: { found: skills.size, copied: [], preserved: [], skipped: skippedSkills },
  agents: { found: agents.size, copied: [], preserved: [] },
};

if (!checkOnly) await mkdir(target, { recursive: true });

for (const [name, source] of skills) {
  const destination = path.join(target, "skills", name);
  if (!replaceSkills && (await exists(destination))) {
    result.skills.preserved.push(name);
    continue;
  }
  if (!checkOnly) {
    await mkdir(path.dirname(destination), { recursive: true });
    await cp(source, destination, { recursive: true, force: true });
  }
  result.skills.copied.push(name);
}

for (const [name, source] of agents) {
  const destination = path.join(target, "agents", `${name}.md`);
  if (await exists(destination)) {
    result.agents.preserved.push(name);
    continue;
  }
  const sourceContent = await readFile(source, "utf8");
  const rendered = source.toLowerCase().endsWith(".toml")
    ? renderTomlAgent(sourceContent, name)
    : sourceContent;
  if (!checkOnly) {
    await mkdir(path.dirname(destination), { recursive: true });
    await writeFile(destination, rendered, "utf8");
  }
  result.agents.copied.push(name);
}

console.log(JSON.stringify(result, null, 2));
