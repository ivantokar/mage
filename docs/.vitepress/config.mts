import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'Mage CLI',
  description: 'Clean Layered DDD architecture scaffolding for Vapor projects',
  base: '/',
  lastUpdated: true,
  themeConfig: {
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Getting Started', link: '/guide/getting-started' },
      { text: 'Architecture', link: '/guide/architecture' },
      { text: 'Commands', link: '/api/commands' }
    ],
    sidebar: [
      {
        text: 'Start',
        items: [
          { text: 'Getting Started', link: '/guide/getting-started' },
          { text: 'Installation', link: '/guide/installation' }
        ]
      },
      {
        text: 'Concepts',
        items: [
          { text: 'DDD Architecture', link: '/guide/architecture' },
          { text: 'Configuration (.magerc.yml)', link: '/guide/configuration' }
        ]
      },
      {
        text: 'Reference',
        items: [
          { text: 'Commands', link: '/api/commands' }
        ]
      }
    ],
    socialLinks: [
      { icon: 'github', link: 'https://github.com/ivantokar/mage' }
    ],
    search: {
      provider: 'local'
    },
    footer: {
      message: 'Released under MIT License.',
      copyright: 'Copyright © 2026-present Ivan Tokar'
    }
  },
  head: [
    ['meta', { name: 'theme-color', content: '#c0392b' }],
    ['meta', { name: 'og:type', content: 'website' }],
    ['meta', { name: 'og:site_name', content: 'Mage CLI' }],
    ['meta', { name: 'og:image', content: '/mage-banner.png' }]
  ]
})
