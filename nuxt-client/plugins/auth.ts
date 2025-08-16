export default defineNuxtPlugin(async (nuxtApp) => {
    const { initAuth } = useAuth();
    await initAuth();
});
