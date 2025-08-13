<template>
    <div>
        <h2 class="mt-6 text-center text-2xl font-extrabold text-white">
            Create a New Account
        </h2>
        <form class="mt-8 space-y-6" @submit.prevent="handleRegister">
            <div v-if="message" :class="messageType === 'error' ? 'bg-red-50 border-red-200' : 'bg-green-50 border-green-200'" class="rounded-md p-4 border">
                <div class="flex">
                    <div class="flex-shrink-0">
                        <XCircleIcon v-if="messageType === 'error'" class="h-5 w-5 text-red-400" aria-hidden="true" />
                        <CheckCircleIcon v-else class="h-5 w-5 text-green-400" aria-hidden="true" />
                    </div>
                    <div class="ml-3">
                        <p :class="messageType === 'error' ? 'text-red-800' : 'text-green-800'" class="text-sm font-medium">{{ message }}</p>
                    </div>
                </div>
            </div>

            <div class="rounded-md shadow-sm flex flex-col gap-4">
                <div>
                    <label for="name" class="sr-only">Name</label>
                    <input id="name" name="name" v-model="formData.name" type="text" autocomplete="name" required placeholder="Full Name" class="appearance-none relative block w-full px-3 py-2 border border-gray-700 bg-gray-800 text-white placeholder-gray-500 rounded-md focus:outline-none focus:ring-orange-500 focus:border-orange-500 sm:text-sm" />
                </div>
                <div>
                    <label for="email-address" class="sr-only">Email</label>
                    <input id="email-address" name="email" v-model="formData.email" type="email" autocomplete="email" required placeholder="Email Address" class="appearance-none relative block w-full px-3 py-2 border border-gray-700 bg-gray-800 text-white placeholder-gray-500 rounded-md focus:outline-none focus:ring-orange-500 focus:border-orange-500 sm:text-sm" />
                </div>
                <div>
                    <label for="phone" class="sr-only">Phone Number</label>
                    <input id="phone" name="phone" v-model="formData.phone" type="tel" autocomplete="tel" required placeholder="Phone Number" class="appearance-none relative block w-full px-3 py-2 border border-gray-700 bg-gray-800 text-white placeholder-gray-500 rounded-md focus:outline-none focus:ring-orange-500 focus:border-orange-500 sm:text-sm" />
                </div>
                <div>
                    <label for="password" class="sr-only">Password</label>
                    <input id="password" name="password" v-model="formData.password" type="password" autocomplete="new-password" required placeholder="Password" class="appearance-none relative block w-full px-3 py-2 border border-gray-700 bg-gray-800 text-white placeholder-gray-500 rounded-md focus:outline-none focus:ring-orange-500 focus:border-orange-500 sm:text-sm" />
                </div>
                <div>
                    <label for="confirm-password" class="sr-only">Confirm Password</label>
                    <input id="confirm-password" name="confirm-password" v-model="formData.confirmPassword" type="password" autocomplete="new-password" required placeholder="Confirm Password" class="appearance-none relative block w-full px-3 py-2 border border-gray-700 bg-gray-800 text-white placeholder-gray-500 rounded-md focus:outline-none focus:ring-orange-500 focus:border-orange-500 sm:text-sm" />
                </div>
            </div>

            <div class="text-sm text-center">
                <NuxtLink to="/login" class="font-medium text-orange-500 hover:text-orange-400">
                    Already have an account? Log in
                </NuxtLink>
            </div>

            <div>
                <button type="submit" :disabled="loading" class="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-orange-600 hover:bg-orange-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-900 focus:ring-orange-500 disabled:opacity-50 disabled:cursor-not-allowed">
                    <span class="absolute left-0 inset-y-0 flex items-center pl-3">
                        <UserPlusIcon v-if="!loading" class="h-5 w-5 text-orange-500 group-hover:text-orange-400" aria-hidden="true" />
                        <svg v-if="loading" class="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </svg>
                    </span>
                    {{ loading ? 'Processing...' : 'Register' }}
                </button>
            </div>
        </form>
    </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue';
import { UserPlusIcon, XCircleIcon, CheckCircleIcon } from '@heroicons/vue/20/solid';
import { useAuth } from '~/composables/useAuth';
import { navigateTo } from '#app';

definePageMeta({
    layout: 'auth',
    middleware: 'guest',
});

const { signup } = useAuth();

const formData = reactive({
    name: '',
    email: '',
    phone: '',
    password: '',
    confirmPassword: '',
});
const loading = ref(false);
const message = ref<string | null>(null);
const messageType = ref<'success' | 'error'>('error');

const handleRegister = async () => {
    loading.value = true;
    message.value = null;

    if (formData.password !== formData.confirmPassword) {
        message.value = 'Password and confirm password do not match.';
        messageType.value = 'error';
        loading.value = false;
        return;
    }

    try {
        const result = await signup({
            name: formData.name,
            email: formData.email,
            phone: formData.phone,
            password: formData.password,
        });

        if (result.success) {
            message.value = 'Registration successful! You will be redirected to the login page.';
            messageType.value = 'success';
            formData.name = '';
            formData.email = '';
            formData.phone = '';
            formData.password = '';
            formData.confirmPassword = '';

            setTimeout(() => {
                navigateTo('/login');
            }, 2500);
        } else {
            message.value = result.error || 'Registration failed.';
            messageType.value = 'error';
        }
    } catch (err: any) {
        console.error('Unexpected registration error in component:', err);
        message.value = 'An unexpected error occurred.';
        messageType.value = 'error';
    } finally {
        loading.value = false;
    }
};
</script>

<style scoped>
input {
    appearance: none;
    position: relative;
    display: block;
    width: 100%;
    padding-left: 0.75rem;
    padding-right: 0.75rem;
    padding-top: 0.5rem;
    padding-bottom: 0.5rem;
    border-width: 1px;
    border-color: #4a5568;
    background-color: #2d3748;
    color: #ffffff;
    border-radius: 0.375rem;
}
input::placeholder {
    color: #718096;
}
input:focus {
    outline: 2px solid transparent;
    outline-offset: 2px;
    --tw-ring-color: #dd6b20;
    box-shadow: var(--tw-ring-inset) 0 0 0 calc(1px + var(--tw-ring-offset-width)) var(--tw-ring-color);
    border-color: #dd6b20;
    z-index: 10;
}
</style>
