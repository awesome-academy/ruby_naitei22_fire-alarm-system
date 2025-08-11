<template>
    <div class="min-h-screen flex items-center justify-center bg-gray-900 py-12 px-4 sm:px-6 lg:px-8">
        <div class="max-w-md w-full space-y-8">
            <div>
                <NuxtLink to="/" class="flex justify-center items-center mb-6">
                    <FireIcon class="h-12 w-auto text-orange-500" />
                    <span class="ml-3 text-3xl font-bold text-white">FireWolf</span>
                </NuxtLink>
                <slot />
            </div>
        </div>
    </div>
</template>

<script setup>
import { FireIcon } from '@heroicons/vue/24/solid';
</script>

<style scoped>
</style>
