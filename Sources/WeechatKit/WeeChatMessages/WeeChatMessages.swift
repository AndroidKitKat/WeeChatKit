// Source: https://weechat.org/files/doc/devel/weechat_relay_protocol.en.html#messages

/*
 * length - 4 bytes
 * compression - 1 byte
 *      - 0x00: no compression
 *      - 0x01: zlib
 *      - 0x02: zstd
 *
 * EVERYTHING BELOW COULD BE COMPRESSED!!!
 *
 * id - 4 bytes indicating length
 *      - The actual ID follows the length
 * repeating...
 * type - 3 bytes
 * object - ??? bytes
 */

