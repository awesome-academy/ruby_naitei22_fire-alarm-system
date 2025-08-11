<template>
    <div>
        <ul v-if="!loading && alerts && alerts.length > 0" role="list" class="divide-y divide-gray-700">
            <li v-for="alert in alerts" :key="alert.id" class="py-3 sm:py-4 px-1 hover:bg-gray-800 rounded transition-colors">
                <NuxtLink :to="`/alerts`" class="flex items-center space-x-3">
                    <div class="flex-shrink-0">
                        <span class="p-1.5 rounded-full" :class="getAlertIconBg(alert.status)">
                            <BellAlertIcon v-if="alert.status === AlertStatus.PENDING" class="h-4 w-4 text-red-400" />
                            <CheckCircleIcon v-else-if="alert.status === AlertStatus.RESOLVED" class="h-4 w-4 text-green-400" />
                            <ExclamationTriangleIcon v-else class="h-4 w-4 text-yellow-400" />
                        </span>
                    </div>
                    <div class="flex-1 min-w-0">
                        <p class="text-sm font-medium text-white truncate" :title="alert.message">
                            {{ alert.message }}
                        </p>
                        <p class="text-xs text-gray-400 truncate">
                            {{ alert.sensor?.name ?? 'N/A' }} - {{ formatDateTime(alert.createdAt) }}
                        </p>
                    </div>
                    <div class="flex-shrink-0">
                        <AlertStatusBadge :status="alert.status" />
                    </div>
                </NuxtLink>
            </li>
        </ul>
        <div v-else-if="loading" class="space-y-4 animate-pulse">
            <div v-for="i in 3" :key="i" class="flex items-center space-x-3 py-3">
                <div class="h-7 w-7 bg-gray-700 rounded-full"></div>
                <div class="flex-1 space-y-2">
                    <div class="h-3 bg-gray-700 rounded w-3/4"></div>
                    <div class="h-2 bg-gray-700 rounded w-1/2"></div>
                </div>
                <div class="h-5 w-16 bg-gray-700 rounded-full"></div>
            </div>
        </div>
        <div v-else class="text-center text-gray-500 py-8 text-sm">
            No recent alerts.
        </div>
    </div>
</template>

<script setup lang="ts">
import { defineProps, type PropType } from 'vue';
import { BellAlertIcon, CheckCircleIcon, ExclamationTriangleIcon } from '@heroicons/vue/20/solid';
import { type AlertWithRelations, AlertStatus } from '~/types/api';
import AlertStatusBadge from './AlertStatusBadge.vue';

const props = defineProps({
    alerts: {
        type: Array as PropType<AlertWithRelations[]>,
        default: () => []
    },
    loading: {
        type: Boolean,
        default: false,
    }
});

const formatDateTime = (dateTimeString: string | Date): string => {
    if (!dateTimeString) return 'N/A';
    try {
        const date = new Date(dateTimeString);
        if (isNaN(date.getTime())) return 'Invalid';
        return date.toLocaleString('en-US', { hour: '2-digit', minute: '2-digit', day: '2-digit', month: '2-digit' });
    } catch (e) {
        return 'Error';
    }
};

const getAlertIconBg = (status: AlertStatus) => {
    switch (status) {
        case AlertStatus.PENDING: return 'bg-red-900/50';
        case AlertStatus.RESOLVED: return 'bg-green-900/50';
        case AlertStatus.IGNORED: return 'bg-yellow-900/50';
        default: return 'bg-gray-700';
    }
};
</script>