import { useAuth } from '~/composables/useAuth';

export default defineNuxtRouteMiddleware((to) => {
  const { isAuthenticated, isInitialized } = useAuth();

  if (!isInitialized.value) {
    return;
  }

  if (!isAuthenticated.value) {
    const redirectPath = to.fullPath !== '/' ? to.fullPath : '/dashboard';
    return navigateTo(`/login?redirect=${encodeURIComponent(redirectPath)}`, { replace: true });
  }
});
