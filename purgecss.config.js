module.exports = {
  content: ['./build/content/**/*.html'],
  css: ['./build/content/css/infrablocks.css'],
  defaultExtractor: content => content.match(/[A-Za-z0-9-_:/]+/g) || []
}
