<template>
    <div class="bg-gray-850 overflow-hidden shadow rounded-lg border" :class="borderColor">
        <div class="p-5">
            <div class="flex items-center">
                <div class="flex-shrink-0 p-3 rounded-full" :class="iconBgColor">
                    <component :is="icon" class="h-6 w-6" :class="iconColor" aria-hidden="true" />
                </div>
                <div class="ml-5 w-0 flex-1">
                    <dl>
                        <dt class="text-sm font-medium text-gray-400 truncate">{{ title }}</dt>
                        <dd>
                            <slot name="value">
                                <div class="text-lg font-medium text-white">{{ value }}</div>
                            </slot>
                        </dd>
                    </dl>
                </div>
            </div>
        </div>
        <div v-if="link && linkText" class="bg-gray-800 px-5 py-3">
            <div class="text-sm">
                <NuxtLink :to="link" class="font-medium text-orange-500 hover:text-orange-400">{{ linkText }}</NuxtLink>
            </div>
        </div>
    </div>
</template>

<script setup lang="ts">
import { defineProps, type FunctionalComponent, type HTMLAttributes, type VNodeProps } from 'vue';

defineProps({
    title: { type: String, required: true },
    value: { type: [String, Number], default: 'N/A' },
    icon: { type: Object as () => FunctionalComponent<HTMLAttributes & VNodeProps>, required: true },
    iconColor: { type: String, default: 'text-orange-500' },
    iconBgColor: { type: String, default: 'bg-gray-700' },
    borderColor: { type: String, default: 'border-gray-700 hover:border-orange-500/50' },
    link: { type: String, default: null },
    linkText: { type: String, default: 'View all' },
});
</script>
