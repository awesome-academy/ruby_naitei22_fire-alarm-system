<template>
    <div>
        <h2 class="mt-6 text-center text-2xl font-extrabold text-white">
            Log in to your account
        </h2>
        <form class="mt-8 space-y-6" @submit.prevent="handleLogin">
            <div v-if="errorMessage" class="rounded-md bg-red-50 p-4 border border-red-200">
                <div class="flex">
                    <div class="flex-shrink-0">
                        <XCircleIcon class="h-5 w-5 text-red-400" aria-hidden="true" />
                    </div>
                    <div class="ml-3">
                        <p class="text-sm font-medium text-red-800">{{ errorMessage }}</p>
                    </div>
                </div>
            </div>

            <input type="hidden" name="remember" value="true" />
            <div class="rounded-md shadow-sm -space-y-px flex flex-col gap-4">
                <div>
                    <label for="email-address" class="sr-only">Email Address</label>
                    <input
                        id="email-address"
                        name="email"
                        type="email"
                        v-model="credentials.email"
                        required
                        autocomplete="email"
                        class="appearance-none relative block w-full px-3 py-2 border border-gray-700 bg-gray-800 text-white placeholder-gray-500 rounded-md focus:outline-none focus:ring-orange-500 focus:border-orange-500 focus:z-10 sm:text-sm"
                        placeholder="Email Address"
                    />
                </div>
                <div>
                    <label for="password" class="sr-only">Password</label>
                    <input
                        id="password"
                        name="password"
                        type="password"
                        v-model="credentials.password"
                        required
                        autocomplete="current-password"
                        class="appearance-none relative block w-full px-3 py-2 border border-gray-700 bg-gray-800 text-white placeholder-gray-500 rounded-md focus:outline-none focus:ring-orange-500 focus:border-orange-500 focus:z-10 sm:text-sm"
                        placeholder="Password"
                    />
                </div>
            </div>

            <div class="flex items-center justify-between">
                <div class="flex items-center">
                    <input id="remember-me" name="remember-me" type="checkbox" class="h-4 w-4 text-orange-600 focus:ring-orange-500 border-gray-600 bg-gray-700 rounded" />
                    <label for="remember-me" class="ml-2 block text-sm text-gray-400"> Remember me </label>
                </div>
                <NuxtLink
                    to="/forgot-password"
                    class="font-medium text-orange-500 hover:text-orange-400"
                >
                    Forgot password?
                </NuxtLink>
            </div>

            <div>
                <button
                    type="submit"
                    :disabled="loading"
                    class="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-orange-600 hover:bg-orange-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-900 focus:ring-orange-500 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                    <span class="absolute left-0 inset-y-0 flex items-center pl-3">
                        <LockClosedIcon v-if="!loading" class="h-5 w-5 text-orange-500 group-hover:text-orange-400" aria-hidden="true" />
                        <svg v-if="loading" class="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </svg>
                    </span>
                    {{ loading ? 'Processing...' : 'Log in' }}
                </button>
                <div class="mt-6 text-center">
                    <p class="text-sm text-gray-400">Or log in with</p>
                    <button
                        @click="handleGoogleLogin"
                        type="button"
                        class="mt-2 w-full inline-flex justify-center py-2 px-4 border border-gray-700 rounded-md shadow-sm bg-gray-800 text-white hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-orange-500"
                    >
                        <!-- Icon Google -->
                        <svg class="h-5 w-5 mr-2" viewBox="0 0 533.5 544.3">
                        <path fill="#4285F4" d="M533.5 278.4c0-17.5-1.5-34.4-4.4-50.9H272v95.9h146.9c-6.3 33.9-25.4 62.7-54.3 82l87.7 68c51.2-47.2 81.2-116.6 81.2-195.9z"/>
                        <path fill="#34A853" d="M272 544.3c73.6 0 135.4-24.3 180.6-65.9l-87.7-68c-24.4 16.4-55.6 26-92.9 26-71.4 0-131.9-48.2-153.5-113.1l-89.3 69.1c44.9 88.5 137.3 151.9 242.8 151.9z"/>
                        <path fill="#FBBC05" d="M118.2 320.3c-10.1-30.3-10.1-62.9 0-93.2l-89.3-69.1C-27.1 232.1-27.1 312.1 29 382.2l89.2-61.9z"/>
                        <path fill="#EA4335" d="M272 107.7c38.4-.6 74 13.2 101.5 39l76-76C407.4 24.6 345.6 0 272 0 166.5 0 74.1 63.4 29.1 151.9l89.2 69.1c21.5-64.9 82-113.3 153.7-113.3z"/>
                        </svg>
                        Google
                    </button>
                </div>
                <div class="mt-4 text-sm text-center">
                    <NuxtLink to="/register" class="font-medium text-orange-500 hover:text-orange-400">
                        Don't have an account? Sign up now
                    </NuxtLink>
                </div>
            </div>
        </form>
    </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue';
import { LockClosedIcon, XCircleIcon } from '@heroicons/vue/20/solid';
import { useAuth } from '~/composables/useAuth';
import { navigateTo, useRoute, useRouter } from '#app';
import { nextTick } from 'vue';
const route = useRoute();
const router = useRouter();

definePageMeta({
    layout: 'auth',
    middleware: 'guest'
});

const { login,loginWithGoogle } = useAuth();

const credentials = reactive({
    email: '',
    password: '',
});
const loading = ref(false);
const errorMessage = ref<string | null>(null);

const handleLogin = async () => {
    loading.value = true;
    errorMessage.value = null;

    try {
        const result = await login({
            identifier: credentials.email,
            password: credentials.password
        });

        if (result.success) {
            const route = useRoute();
            const redirect = route.query.redirect as string | undefined;
            await navigateTo(redirect || '/dashboard', { replace: true });
        } else {
            errorMessage.value = result.error || 'Login failed.';
        }
    } catch (err: any) {
        console.error('Unexpected login error in component:', err);
        errorMessage.value = 'An unexpected error occurred.';
    } finally {
        loading.value = false;
    }
};
const handleGoogleLogin = async () => {
  loading.value = true;
  errorMessage.value = null;
  try {
    const result = await loginWithGoogle();
    if (result.success) {
        await router.push('/dashboard'); 
    } else {
      errorMessage.value = result.error;
    }
  } catch (err) {
    console.error(err);
    errorMessage.value = 'Unexpected error.';
  } finally {
    loading.value = false;
  }
};
</script>

<style scoped>
</style>
