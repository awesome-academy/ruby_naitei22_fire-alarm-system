export default defineNuxtConfig({
  compatibilityDate: '2024-11-01',
  devtools: { enabled: true },
  modules: [
    '@nuxtjs/tailwindcss'
  ],
  ssr: true,
  runtimeConfig: {
    public: {
      apiBase: process.env.NUXT_PUBLIC_API_BASE,
    }
  },
  app: {
    head: {
      charset: 'utf-8',
      viewport: 'width=device-width, initial-scale=1',
      title: 'FireWolf',
      meta: [
        { name: 'description', content: 'A real-time fire monitoring and warning system for Data Centers.' }
      ],
      link: [
        { rel: 'icon', type: 'image/png', href: 'https://res.cloudinary.com/dbonwxmgl/image/upload/v1744813436/nincpcscjdqufgdfunit.png' }
      ]
    }
  }
})
