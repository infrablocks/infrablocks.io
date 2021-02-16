module.exports = {
  theme: {
    inset: {
      '0': 0,
      auto: 'auto',
      '2': '0.5rem',
      '4': '1rem',
      '7': '1.75rem'
    },
    extend: {
      typography: {
        DEFAULT: {
          css: {
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
