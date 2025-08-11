import { useAuth } from '~/composables/useAuth';

export default defineNuxtRouteMiddleware((to) => {
  const { isAuthenticated } = useAuth();

  if (!isAuthenticated.value) {
    const redirectPath = to.fullPath !== '/' ? to.fullPath : '/dashboard';
    return navigateTo(`/login?redirect=${encodeURIComponent(redirectPath)}`, { replace: true });
  }
});
