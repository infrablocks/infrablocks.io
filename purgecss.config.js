module.exports = {
  content: ['./build/content/**/*.html', './build/content/**/*.js'],
  css: ['./build/content/**/*.css'],
  defaultExtractor: content => content.match(/[A-Za-z0-9-_:/]+/g) || []
}
