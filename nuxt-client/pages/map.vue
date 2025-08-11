<template>
    <div class="flex flex-col h-[calc(100vh-4rem)]">
        <div class="flex-shrink-0 h-1/3 md:h-2/5 lg:h-1/3 bg-gray-850 border-b border-gray-700 overflow-hidden p-4 flex flex-col">
            <h2 class="text-xl font-semibold text-white mb-3 flex-shrink-0">Details & Status</h2>
            <div class="flex-shrink-0 mb-3 border-b border-gray-700">
                <nav class="-mb-px flex space-x-4" aria-label="Tabs">
                    <button
                        @click="setActiveTab('sensors')"
                        :class="[
                            activeTab === 'sensors'
                                ? 'border-orange-500 text-orange-400'
                                : 'border-transparent text-gray-500 hover:text-gray-300 hover:border-gray-500',
                            'whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm'
                        ]"
                    >
                        Sensors ({{ sensors.length }})
                        <span
                            v-if="alertedSensorIds.size > 0"
                            class="ml-1.5 inline-flex items-center px-1.5 py-0.5 rounded-full text-xs font-medium bg-red-600 text-white"
                            >{{ alertedSensorIds.size }}</span
                        >
                    </button>
                    <button
                        @click="setActiveTab('cameras')"
                        :class="[
                            activeTab === 'cameras'
                                ? 'border-orange-500 text-orange-400'
                                : 'border-transparent text-gray-500 hover:text-gray-300 hover:border-gray-500',
                            'whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm'
                        ]"
                    >
                        Cameras ({{ cameras.length }})
                    </button>
                    <button
                        @click="setActiveTab('alerts')"
                        :class="[
                            activeTab === 'alerts'
                                ? 'border-orange-500 text-orange-400'
                                : 'border-transparent text-gray-500 hover:text-gray-300 hover:border-gray-500',
                            'whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm'
                        ]"
                    >
                        Pending Alerts ({{ activeAlerts.length }})
                    </button>
                    <button
                        @click="() => refresh()"
                        :disabled="pending"
                        title="Refresh Data"
                        class="ml-auto p-1.5 rounded-full text-gray-500 hover:bg-gray-700 hover:text-white disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                    >
                        <ArrowPathIcon class="h-4 w-4" :class="{ 'animate-spin': pending }" />
                    </button>
                </nav>
            </div>
            <div class="flex-1 overflow-y-auto custom-scrollbar pr-1">
                <div v-if="pending && !mapData" class="text-center py-10 text-gray-500">
                    <AppSpinner class="inline-block" /> Loading map data...
                </div>
                <div v-if="error && !pending" class="text-center py-10 text-red-400">
                    {{ 'Failed to load map data.' }}
                </div>
                <div v-show="activeTab === 'sensors' && mapData">
                    <MapSensorInfoTable
                        :sensors="sensors"
                        :alerted-ids="alertedSensorIds"
                        :selected-id="selectedItem?.type === 'Sensor' ? selectedItem.id : null"
                        @row-click="handleRowClick"
                    />
                </div>
                <div v-show="activeTab === 'cameras' && mapData">
                    <MapCameraInfoTable
                        :cameras="cameras"
                        :selected-id="selectedItem?.type === 'Camera' ? selectedItem.id : null"
                        @row-click="handleRowClick"
                    />
                </div>
                <div v-show="activeTab === 'alerts' && mapData">
                    <MapAlertInfoTable :alerts="activeAlerts" @row-click="handleRowClick" />
                </div>
            </div>
        </div>
        <div class="flex-1 relative border-t border-gray-700">
            <div
                v-if="pending"
                class="absolute inset-0 flex items-center justify-center bg-gray-800 bg-opacity-75 z-20 pointer-events-none"
            >
                <div class="text-center">
                    <AppSpinner />
                    <p class="text-gray-400 mt-2">Loading map...</p>
                </div>
            </div>
            <div v-else-if="error" class="absolute inset-0 flex items-center justify-center text-red-400">
                Map data could not be loaded.
            </div>
            <ClientOnly>
                <MapLeaflet
                    v-if="initialCoords"
                    ref="mapLeafletRef"
                    :sensors="sensors"
                    :cameras="cameras"
                    :active-alerts="activeAlerts"
                    :initial-center="initialCoords"
                    :initial-zoom="16"
                    :selected-item-id="selectedItem?.id"
                    @item-select="handleItemSelectFromMap"
                />
                <template #fallback>
                    <div class="h-full bg-gray-800 flex items-center justify-center"><AppSpinner /></div>
                </template>
            </ClientOnly>
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref, computed, nextTick } from 'vue';
import { useApi } from '~/composables/useApi';
import { useAsyncData } from '#app';
import MapLeaflet from '~/components/map/MapLeaflet.vue';
import MapSensorInfoTable from '~/components/map/MapSensorInfoTable.vue';
import MapCameraInfoTable from '~/components/map/MapCameraInfoTable.vue';
import MapAlertInfoTable from '~/components/map/MapAlertInfoTable.vue';
import AppSpinner from '~/components/ui/AppSpinner.vue';
import { ArrowPathIcon } from '@heroicons/vue/20/solid';
import type { Zone, Sensor, Camera, Alert } from '~/types/api';
import type { Map } from 'leaflet';
import L from 'leaflet';

definePageMeta({ layout: 'default', middleware: ['auth'] });

type SelectedItem = {
    id: string;
    type: 'Zone' | 'Sensor' | 'Camera' | 'Alert';
    name: string;
    lat?: number | null;
    lon?: number | null;
};

const api = useApi();

const mapLeafletRef = ref<{ mapInstance: Map | null } | null>(null);
const selectedItem = ref<SelectedItem | null>(null);
const activeTab = ref<'sensors' | 'cameras' | 'alerts'>('sensors');

const { data: mapData, pending, error, refresh } = useAsyncData(
    'map-all-data',
    async () => {
        const [sensorsRes, camerasRes, alertsRes, zonesRes] = await Promise.allSettled([
            api.sensors.getAll(),
            api.cameras.getAll(),
            api.alerts.getAll({ status: 'PENDING', limit: 100 }),
            api.zones.getAll({ limit: 50 })
        ]);
        const sensors = sensorsRes.status === 'fulfilled' ? sensorsRes.value : [];
        const cameras = camerasRes.status === 'fulfilled' ? camerasRes.value : [];
        const activeAlerts = alertsRes.status === 'fulfilled' ? alertsRes.value.data : [];
        const zones = zonesRes.status === 'fulfilled' ? zonesRes.value : [];
        return { sensors, cameras, activeAlerts, zones };
    },
    { server: false, lazy: true }
);

const sensors = computed<Sensor[]>(() => mapData.value?.sensors || []);
const cameras = computed<Camera[]>(() => mapData.value?.cameras || []);
const activeAlerts = computed<Alert[]>(() => mapData.value?.activeAlerts || []);
const alertedSensorIds = computed(() => new Set(activeAlerts.value.map(alert => alert.sensorId).filter(Boolean)));
const initialCoords = computed<[number, number] | null>(() => {
    if (!mapData.value) return null;
    const firstValidZone = mapData.value.zones.find(z => z.latitude != null && z.longitude != null);
    return firstValidZone ? [firstValidZone.latitude!, firstValidZone.longitude!] : [10.7769, 106.7009];
});

const setActiveTab = (tabName: 'sensors' | 'cameras' | 'alerts') => {
    activeTab.value = tabName;
    clearSelection();
};

const handleItemSelectFromMap = (item: SelectedItem) => {
    selectedItem.value = item;
    if (item.type === 'Sensor') setActiveTab('sensors');
    else if (item.type === 'Camera') setActiveTab('cameras');
};

const handleRowClick = async (item: SelectedItem) => {
    selectedItem.value = item;
    const map = mapLeafletRef.value?.mapInstance;
    await nextTick();
    if (map && item.lat != null && item.lon != null) {
        map.flyTo([item.lat, item.lon], 18, { animate: true, duration: 0.8 });
        setTimeout(() => {
            mapLeafletRef.value?.mapInstance?.eachLayer(layer => {
                if (layer.options?.itemId === item.id && typeof layer.openPopup === 'function') {
                    layer.openPopup();
                }
            });
        }, 900);
    }
};

const clearSelection = () => {
    selectedItem.value = null;
};
</script>

<style scoped>
.custom-scrollbar::-webkit-scrollbar {
    width: 6px;
}
.custom-scrollbar::-webkit-scrollbar-track {
    background: #374151;
    border-radius: 3px;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
    background: #6b7280;
    border-radius: 3px;
}
.custom-scrollbar::-webkit-scrollbar-thumb:hover {
    background: #9ca3af;
}
</style>
