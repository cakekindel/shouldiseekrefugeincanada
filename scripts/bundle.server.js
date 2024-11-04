import Esbuild from 'esbuild'
import * as Bundle from './bundle.common.js'

const built = await Bundle.build({ prod: true, modules: ['Main.Serve'] })

await Esbuild.build({
  entryPoints: built,
  bundle: true,
  outdir: 'dist',
  platform: 'node',
  loader: {
    '.node': 'file',
  },
  format: 'esm',
  sourcemap: true,
  external: ['bun'],
  banner: {
    js: "import __module from 'module';import __path from 'path';import __url from 'url';const require = __module.createRequire(import.meta.url);const __dirname = __path.dirname(__url.fileURLToPath(import.meta.url));const __filename=new URL(import.meta.url).pathname",
  },
})
