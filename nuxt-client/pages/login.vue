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
                <div class="text-sm">
                    <a href="#" class="font-medium text-orange-500 hover:text-orange-400"> Forgot password? </a>
                </div>
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
import { navigateTo } from '#app';

definePageMeta({
    layout: 'auth',
    middleware: 'guest'
});

const { login } = useAuth();

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
</script>

<style scoped>
</style>
