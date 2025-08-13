<template>
    <aside class="w-64 flex-shrink-0 bg-gray-900 text-gray-300 flex flex-col h-screen fixed left-0 top-0 z-10">
        <div class="h-16 flex items-center justify-center px-4 border-b border-gray-700 flex-shrink-0">
            <NuxtLink to="/dashboard" class="flex items-center space-x-2">
                <img src="https://res.cloudinary.com/dbonwxmgl/image/upload/v1744813436/nincpcscjdqufgdfunit.png" alt="FireWolf Logo" class="h-8 w-8" />
                <span class="text-xl font-bold text-white">FireWolf</span>
            </NuxtLink>
        </div>

        <nav class="flex-1 overflow-y-auto py-4 space-y-1">
            <ul>
                <li v-for="item in navigation" :key="item.name">
                    <NuxtLink
                        :to="item.href"
                        class="flex items-center px-4 py-2.5 text-sm font-medium rounded-md mx-2 transition-colors duration-150 ease-in-out hover:bg-gray-800 hover:text-white group"
                        :class="{
                            'bg-gray-800 text-orange-500 font-semibold': $route.path.startsWith(item.activePath || item.href),
                            'text-gray-300': !$route.path.startsWith(item.activePath || item.href)
                        }"
                    >
                        <component
                            :is="item.icon"
                            class="mr-3 flex-shrink-0 h-5 w-5 transition-colors duration-150 ease-in-out"
                            :class="{
                                'text-orange-500': $route.path.startsWith(item.activePath || item.href),
                                'text-gray-400 group-hover:text-gray-300': !$route.path.startsWith(item.activePath || item.href)
                            }"
                            aria-hidden="true"
                        />
                        {{ item.name }}
                    </NuxtLink>
                </li>
            </ul>

            <div class="pt-6 px-4 space-y-1" v-if="isAdmin">
                <h3 class="px-2 text-xs font-semibold text-gray-500 uppercase tracking-wider">
                    Management
                </h3>
                <ul>
                    <li v-for="item in adminNavigation" :key="item.name">
                        <NuxtLink
                            :to="item.href"
                            class="flex items-center px-4 py-2.5 text-sm font-medium rounded-md mx-2 transition-colors duration-150 ease-in-out hover:bg-gray-800 hover:text-white group"
                            :class="{
                                'bg-gray-800 text-orange-500 font-semibold': $route.path.startsWith(item.activePath || item.href),
                                'text-gray-300': !$route.path.startsWith(item.activePath || item.href)
                            }"
                        >
                            <component
                                :is="item.icon"
                                class="mr-3 flex-shrink-0 h-5 w-5 transition-colors duration-150 ease-in-out"
                                :class="{
                                    'text-orange-500': $route.path.startsWith(item.activePath || item.href),
                                    'text-gray-400 group-hover:text-gray-300': !$route.path.startsWith(item.activePath || item.href)
                                }"
                                aria-hidden="true"
                            />
                            {{ item.name }}
                        </NuxtLink>
                    </li>
                </ul>
            </div>
        </nav>
    </aside>
</template>

<script setup>
import {
    ChartBarIcon,
    FireIcon,
    MapIcon,
    VideoCameraIcon,
    BellAlertIcon,
    FolderIcon,
    UsersIcon,
    Cog6ToothIcon,
    MapPinIcon
} from '@heroicons/vue/24/outline';

const isAdmin = ref(true);

const navigation = [
    { name: 'Dashboard', href: '/dashboard', icon: ChartBarIcon },
    { name: 'Alerts', href: '/alerts', icon: BellAlertIcon, activePath: '/alerts' },
    { name: 'Map', href: '/map', icon: MapIcon },
    { name: 'Cameras', href: '/cameras', icon: VideoCameraIcon, activePath: '/cameras' }
];

const adminNavigation = [
    { name: 'Manage Alerts', href: '/alerts', icon: FolderIcon, activePath: '/alerts' },
    { name: 'Manage Sensors', href: '/sensors', icon: Cog6ToothIcon },
    { name: 'Manage Cameras', href: '/cameras', icon: VideoCameraIcon },
    { name: 'Manage Zones', href: '/zones', icon: MapPinIcon },
    { name: 'Manage Users', href: '/users', icon: UsersIcon }
];
</script>

<style scoped>
</style>
