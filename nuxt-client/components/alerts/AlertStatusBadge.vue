<template>
    <span :class="badgeClass" class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium">
        {{ formattedStatus }}
    </span>
</template>

<script setup lang="ts">
import { computed, defineProps, type PropType } from 'vue';
import type { AlertStatus } from '~/types/api';

const props = defineProps({
    status: {
        type: String as PropType<AlertStatus>,
        required: true,
    },
});

const badgeClass = computed(() => {
    switch (props.status) {
        case 'PENDING':
            return 'bg-red-100 text-red-800 border border-red-300';
        case 'RESOLVED':
            return 'bg-green-100 text-green-800 border border-green-300';
        case 'IGNORED':
            return 'bg-yellow-100 text-yellow-800 border border-yellow-300';
        default:
            return 'bg-gray-100 text-gray-800 border border-gray-300';
    }
});

const formattedStatus = computed(() => {
    switch (props.status) {
        case 'PENDING':
            return 'Pending';
        case 'RESOLVED':
            return 'Resolved';
        case 'IGNORED':
            return 'Ignored';
        default:
            return props.status;
    }
});
</script>

<style scoped>
</style>
