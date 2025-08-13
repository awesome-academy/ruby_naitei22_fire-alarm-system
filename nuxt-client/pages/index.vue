<template>
    <div class="flex items-center justify-center min-h-screen bg-gray-900">
        <svg class="animate-spin h-10 w-10 text-orange-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        <p class="ml-4 text-gray-400 text-lg">Redirecting...</p>
    </div>
</template>

<script setup lang="ts">
import { navigateTo } from '#app';
import { useAuth } from '~/composables/useAuth';

definePageMeta({
  middleware: [
    function (to, from) {
      const { isAuthenticated } = useAuth();
      if (isAuthenticated.value) {
        return navigateTo('/dashboard', { replace: true });
      }
      return navigateTo('/login', { replace: true });
    }
  ]
});
</script>

<style scoped>
</style>
