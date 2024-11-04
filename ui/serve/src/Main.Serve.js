import Mime from 'mime-types'
import Path from 'path'

export const contentTypeFromExtension = f => () => {
  const res = Mime.contentType(Path.basename(f))
  if (typeof res === 'boolean') {
    return null
  } else {
    return res
  }
}
