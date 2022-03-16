module.exports = {
  content: [
    './src/_includes/*.html',
    './src/_includes/components/*.html',
    './src/_includes/docs/*.html',
    './src/_includes/landing/*.html',
    './src/_layouts/*.html',
    './src/docs/*.md',
    './src/_drafts/*.md',
    './src/ts/*.ts',
    './src/index.md',
    './src/404.html'
  ],
  theme: {
    extend: {
      inset: {
        '0': 0,
        auto: 'auto',
        '2': '0.5rem',
        '4': '1rem',
        '7': '1.75rem'
      },
      typography: {
        DEFAULT: {
          css: {
            maxWidth: '80ch',
            h1: {
              fontWeight: '700'
            },
            h2: {
              fontWeight: '600'
            },
            h3: {
              fontWeight: '500'
            },
            h4: {
              fontWeight: '400'
            },
            code: {
              fontWeight: '400'
            },
            a: {
              fontWeight: '400'
            },
            strong: {
              fontWeight: '500'
            },
            blockquote: {
              fontWeight: '400'
            },
            thead: {
              fontWeight: '500'
            },
            'code::before': {
              content: 'none',
            },
            'code::after': {
              content: 'none',
            }
          }
        }
      }
    }
  },
  plugins: [
    require('@tailwindcss/typography')
  ],
}
