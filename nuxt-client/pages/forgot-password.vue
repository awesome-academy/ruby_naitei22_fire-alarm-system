<template>
    <div>
        <h2 class="mt-6 text-center text-2xl font-extrabold text-white">
            Forgot Your Password?
        </h2>
        <p class="mt-2 text-center text-sm text-gray-400">
            Enter your email address and we will send you a link to reset your password.
        </p>
        <form class="mt-8 space-y-6" @submit.prevent="handleForgotPassword">
            <div class="rounded-md shadow-sm">
                <div>
                    <label for="email-address" class="sr-only">Email Address</label>
                    <input
                        id="email-address"
                        name="email"
                        type="email"
                        v-model="email"
                        required
                        autocomplete="email"
                        class="appearance-none relative block w-full px-3 py-2 border border-gray-700 bg-gray-800 text-white placeholder-gray-500 rounded-md focus:outline-none focus:ring-orange-500 focus:border-orange-500 sm:text-sm"
                        placeholder="Email Address"
                    />
                </div>
            </div>
            <div class="text-sm text-center">
                <NuxtLink to="/login" class="font-medium text-orange-500 hover:text-orange-400">
                    Back to Log in
                </NuxtLink>
            </div>
            <div>
                <button
                    type="submit"
                    :disabled="loading"
                    class="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-orange-600 hover:bg-orange-700 focus:outline-none"
                >
                    <span class="absolute left-0 inset-y-0 flex items-center pl-3">
                        <PaperAirplaneIcon v-if="!loading" class="h-5 w-5 text-orange-500 group-hover:text-orange-400" />
                    </span>
                    {{ loading ? 'Sending...' : 'Send Reset Link' }}
                </button>
            </div>
        </form>
    </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useApi } from '~/composables/useApi';
import Swal from 'sweetalert2';
import { PaperAirplaneIcon } from '@heroicons/vue/20/solid';

definePageMeta({
    layout: 'auth'
});

const api = useApi();
const email = ref('');
const loading = ref(false);

const handleForgotPassword = async () => {
    loading.value = true;
    try {
        const response = await api.auth.forgotPassword({ email: email.value });
        Swal.fire({
            icon: 'success',
            title: 'Check Your Email',
            text: response.message,
            background: '#1f2937',
            color: '#d1d5db',
            confirmButtonColor: '#f97316',
            customClass: { popup: 'swal2-dark' }
        });
        email.value = '';
    } catch (error: any) {
        Swal.fire({
            icon: 'success',
            title: 'Check Your Email',
            text: "If an account with this email exists, we have sent a password reset link.",
        });
    } finally {
        loading.value = false;
    }
};
</script>
