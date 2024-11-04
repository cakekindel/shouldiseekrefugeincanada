import Fs from 'fs/promises'
import Path from 'path'

export const rootDir = Path.resolve(__dirname, '..')

export const packageDirs = async () => {
  const ents = await Fs.readdir(rootDir, { withFileTypes: true })
  const dirs = ents.flatMap(e =>
    e.isDirectory() ? [Path.resolve(rootDir, e.path, e.name)] : [],
  )
  const packages = []
  for (const dir of dirs) {
    try {
      const fs = await Fs.readdir(dir)
      if (fs.some(f => f === 'spago.yaml')) {
        packages.push(dir)
      }
    } catch {}
  }

  return packages
}

export const packageSources = async () => {
  const packages = await packageDirs()
  const sources = []
  for (const p of packages) {
    const files = await Fs.readdir(p, { recursive: true, withFileTypes: true })
    sources.push(
      ...files.flatMap(e =>
        e.isFile() ? [Path.resolve(rootDir, e.path, e.name)] : [],
      ),
    )
  }
  return sources
}
