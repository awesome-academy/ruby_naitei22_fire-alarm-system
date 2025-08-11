import { useAuth } from '~/composables/useAuth'

export default defineNuxtPlugin(async () => {
    const { fetchUser } = useAuth()
    await fetchUser()
})
