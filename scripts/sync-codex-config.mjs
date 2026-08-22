import fs from "node:fs"
import fsp from "node:fs/promises"
import os from "node:os"
import path from "node:path"

function valueAfter(flag, fallback) {
  const index = process.argv.indexOf(flag)
  return index >= 0 && process.argv[index + 1] ? process.argv[index + 1] : fallback
}

const repo = path.resolve(process.env.AGENT_SETUP_REPO || process.cwd())
const sourcePath = path.resolve(valueAfter("--source", path.join(repo, ".codex", "config.toml")))
const codexHome = process.env.CODEX_HOME || path.join(os.homedir(), ".codex")
const targetPath = path.resolve(valueAfter("--target", path.join(codexHome, "config.toml")))
const checkOnly = process.argv.includes("--check")

function sections(text) {
  const matches = [...text.matchAll(/^\[([^\]]+)\]\s*$/gm)]
  return new Map(matches.map((match, index) => {
    const start = match.index
    const end = matches[index + 1]?.index ?? text.length
    return [match[1], { start, end, text: text.slice(start, end) }]
  }))
}

function sectionKeys(sectionText) {
  return new Set([...sectionText.matchAll(/^([A-Za-z0-9_-]+)\s*=/gm)].map((match) => match[1]))
}

function rootAssignments(text) {
  const firstSection = text.search(/^\[/m)
  const root = firstSection === -1 ? text : text.slice(0, firstSection)
  return [...root.matchAll(/^([A-Za-z0-9_-]+)\s*=.*$/gm)].map((match) => ({ key: match[1], line: match[0] }))
}

function insertBeforeNextSection(text, sectionName, line) {
  const current = sections(text).get(sectionName)
  if (!current) return text
  const insertion = current.end > 0 && text[current.end - 1] !== "\n" ? `\n${line}\n` : `${line}\n`
  return `${text.slice(0, current.end)}${insertion}${text.slice(current.end)}`
}

function merge(source, target) {
  const sourceSections = sections(source)
  const sourceRoot = rootAssignments(source)
  if (!target.trim()) {
    return {
      merged: source,
      addedSections: [...sourceSections.keys()],
      addedKeys: sourceRoot.map((item) => `root.${item.key}`),
      preservedSections: [],
    }
  }

  let merged = target
  const addedSections = []
  const addedKeys = []
  const preservedSections = []

  const targetRootKeys = new Set(rootAssignments(merged).map((item) => item.key))
  const missingRoot = sourceRoot.filter((item) => !targetRootKeys.has(item.key))
  if (missingRoot.length) {
    merged = `${missingRoot.map((item) => item.line).join("\n")}\n\n${merged}`
    for (const item of missingRoot) addedKeys.push(`root.${item.key}`)
  }

  for (const [name, sourceSection] of sourceSections) {
    const targetSection = sections(merged).get(name)
    if (!targetSection) {
      merged = `${merged.replace(/\s*$/, "")}\n\n${sourceSection.text.trim()}\n`
      addedSections.push(name)
      continue
    }

    preservedSections.push(name)
    if (name !== "features") continue
    const existingKeys = sectionKeys(targetSection.text)
    for (const line of sourceSection.text.split(/\r?\n/)) {
      const match = line.match(/^([A-Za-z0-9_-]+)\s*=/)
      if (!match || existingKeys.has(match[1])) continue
      merged = insertBeforeNextSection(merged, name, line)
      existingKeys.add(match[1])
      addedKeys.push(`${name}.${match[1]}`)
    }
  }

  return { merged, addedSections, addedKeys, preservedSections }
}

async function main() {
  if (!fs.existsSync(sourcePath)) throw new Error(`Source config not found: ${sourcePath}`)
  const source = await fsp.readFile(sourcePath, "utf8")
  const target = fs.existsSync(targetPath) ? await fsp.readFile(targetPath, "utf8") : ""
  const result = merge(source, target)
  const changed = result.merged !== target

  if (changed && !checkOnly) {
    await fsp.mkdir(path.dirname(targetPath), { recursive: true })
    await fsp.writeFile(targetPath, result.merged, "utf8")
  }

  console.log(JSON.stringify({
    source: sourcePath,
    target: targetPath,
    changed,
    mode: checkOnly ? "check" : "apply",
    addedSections: result.addedSections,
    addedKeys: result.addedKeys,
    preservedSections: result.preservedSections,
  }, null, 2))
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error))
  process.exitCode = 1
})
