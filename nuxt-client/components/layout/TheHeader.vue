<template>
    <header class="bg-gray-900 shadow-sm border-b border-gray-700 h-16 flex-shrink-0">
        <div class="container mx-auto px-4 sm:px-6 lg:px-8 h-full">
            <div class="flex justify-between items-center h-full">
                <div></div>
                <div class="flex items-center space-x-4">
                    <div v-if="isAuthenticated" class="relative">
                        <button @click="toggleUserMenu" class="max-w-xs bg-gray-800 rounded-full flex items-center text-sm focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-800 focus:ring-white">
                            <span class="sr-only">Open user menu</span>
                            <UserCircleIcon class="h-8 w-8 rounded-full text-gray-400" />
                            <span class="ml-2 text-sm font-medium text-gray-300 hidden sm:block">
                                {{ user?.name || 'User' }}
                            </span>
                            <ChevronDownIcon class="ml-1 h-4 w-4 text-gray-400 hidden sm:block" />
                        </button>
                        <transition
                            enter-active-class="transition ease-out duration-100"
                            enter-from-class="transform opacity-0 scale-95"
                            enter-to-class="transform opacity-100 scale-100"
                            leave-active-class="transition ease-in duration-75"
                            leave-from-class="transform opacity-100 scale-100"
                            leave-to-class="transform opacity-0 scale-95"
                        >
                            <div v-if="isUserMenuOpen" class="origin-top-right absolute right-0 mt-2 w-48 rounded-md shadow-lg py-1 bg-white ring-1 ring-black ring-opacity-5 focus:outline-none z-20">
                                <a href="/profile" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">Profile</a>
                                <a href="#" @click.prevent="handleLogout" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                                    Logout
                                </a>
                            </div>
                        </transition>
                    </div>
                    <div v-else>
                        <NuxtLink to="/login" class="text-sm font-medium text-gray-300 hover:text-white">
                            Login
                        </NuxtLink>
                    </div>
                </div>
            </div>
        </div>
    </header>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { UserCircleIcon, ChevronDownIcon } from '@heroicons/vue/24/outline';
import { useAuth } from '~/composables/useAuth';
import { navigateTo } from '#app';

const isUserMenuOpen = ref(false);
const { user, isAuthenticated, logout: authLogout } = useAuth();

const toggleUserMenu = () => {
    isUserMenuOpen.value = !isUserMenuOpen.value;
};

const handleLogout = async () => {
    isUserMenuOpen.value = false;
    await authLogout();
    await navigateTo('/login', { replace: true });
};
</script>

<style scoped>
</style>
