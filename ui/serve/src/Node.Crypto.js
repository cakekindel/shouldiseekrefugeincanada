import Crypto from 'crypto'

/** @type {(h: string) => () => Crypto.Hash} */
export const createHashImpl = h => () => Crypto.createHash(h)

/** @type {(h: Crypto.Hash) => (v: string) => () => void} */
export const update = h => v => () => h.update(v)

/** @type {(h: Crypto.Hash) => () => Buffer} */
export const digest = h => () => h.digest()
