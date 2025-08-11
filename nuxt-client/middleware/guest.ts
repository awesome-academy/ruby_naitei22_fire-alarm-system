import { useAuth } from '~/composables/useAuth';

export default defineNuxtRouteMiddleware((to) => {
  const { isAuthenticated } = useAuth();

  if (isAuthenticated.value) {
    console.log('[Middleware: Guest] Authenticated, redirecting to dashboard.');
    return navigateTo('/dashboard', { replace: true });
  }

  console.log('[Middleware: Guest] Not authenticated, allowing navigation to', to.path);
});
