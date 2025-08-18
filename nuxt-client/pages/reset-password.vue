<template>
    <div>
        <h2 class="mt-6 text-center text-2xl font-extrabold text-white">
            Reset Your Password
        </h2>
        <p class="mt-2 text-center text-sm text-gray-400">
            Enter your new password below. Make sure it's secure!
        </p>
        <form class="mt-8 space-y-6" @submit.prevent="handleResetPassword">
            <input type="hidden" name="token" :value="token" />
            <div class="rounded-md shadow-sm flex flex-col gap-4">
                <div>
                    <label for="password" class="sr-only">New Password</label>
                    <input
                        id="password"
                        v-model="passwords.password"
                        type="password"
                        required
                        autocomplete="new-password"
                        class="appearance-none relative block w-full px-3 py-2 border border-gray-700 bg-gray-800 text-white placeholder-gray-500 rounded-md focus:outline-none focus:ring-orange-500 focus:border-orange-500 sm:text-sm"
                        placeholder="New Password"
                    />
                </div>
                <div>
                    <label for="password_confirmation" class="sr-only">Confirm New Password</label>
                    <input
                        id="password_confirmation"
                        v-model="passwords.password_confirmation"
                        type="password"
                        required
                        autocomplete="new-password"
                        class="appearance-none relative block w-full px-3 py-2 border border-gray-700 bg-gray-800 text-white placeholder-gray-500 rounded-md focus:outline-none focus:ring-orange-500 focus:border-orange-500 sm:text-sm"
                        placeholder="Confirm New Password"
                    />
                </div>
            </div>
            <div>
                <button
                    type="submit"
                    :disabled="loading || !token"
                    class="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-orange-600 hover:bg-orange-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-900 focus:ring-orange-500 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                    <span class="absolute left-0 inset-y-0 flex items-center pl-3">
                        <KeyIcon v-if="!loading" class="h-5 w-5 text-orange-500 group-hover:text-orange-400" aria-hidden="true" />
                        <svg v-if="loading" class="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </svg>
                    </span>
                    {{ loading ? 'Resetting...' : 'Reset Password' }}
                </button>
            </div>
        </form>
    </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useApi } from '~/composables/useApi'
import Swal from 'sweetalert2'
import { useRoute, navigateTo } from '#app'
import { KeyIcon } from '@heroicons/vue/20/solid'

definePageMeta({
    layout: 'auth',
})

const api = useApi()
const route = useRoute()
const token = ref('')

const passwords = reactive({
    password: '',
    password_confirmation: ''
})
const loading = ref(false)

onMounted(() => {
    const queryToken = route.query.token as string | undefined
    if (queryToken && typeof queryToken === 'string' && queryToken.trim() !== '') {
        token.value = queryToken
    } else {
        Swal.fire({
            icon: 'error',
            title: 'Invalid Link',
            text: 'The password reset link is invalid or the token is missing.',
            background: '#1f2937',
            color: '#d1d5db',
            confirmButtonColor: '#f97316',
            customClass: { popup: 'swal2-dark' },
        }).then(() => {
            navigateTo('/login')
        })
    }
})

const handleResetPassword = async () => {
    if (passwords.password.length < 6) {
        Swal.fire({ icon: 'error', title: 'Error', text: 'Password must be at least 6 characters long.' })
        return
    }
    if (passwords.password !== passwords.password_confirmation) {
        Swal.fire({ icon: 'error', title: 'Error', text: 'Passwords do not match!' })
        return
    }

    loading.value = true
    try {
        const response = await api.auth.resetPassword({
            token: token.value,
            password: passwords.password,
            password_confirmation: passwords.password_confirmation
        })

        await Swal.fire({
            icon: 'success',
            title: 'Password Reset!',
            text: response.message,
            background: '#1f2937',
            color: '#d1d5db',
            confirmButtonColor: '#f97316',
            customClass: { popup: 'swal2-dark' },
        })

        await navigateTo('/login')
    } catch (error: any) {
        const errorMessage = error.data?.errors?.join(', ') || 'An unexpected error occurred.'
        Swal.fire({
            icon: 'error',
            title: 'Error',
            text: errorMessage,
            background: '#1f2937',
            color: '#d1d5db',
            confirmButtonColor: '#f97316',
            customClass: { popup: 'swal2-dark' },
        })
    } finally {
        loading.value = false
    }
}
</script>
