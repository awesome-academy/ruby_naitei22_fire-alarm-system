<template>
    <div>
        <div class="flex justify-between items-center mb-6">
            <h1 class="text-2xl font-semibold text-white">System Overview</h1>
            <div class="flex items-center space-x-2">
                <select
                    v-model="selectedSensorId"
                    @change="() => fetchChartData()"
                    class="py-1 px-2 border border-gray-600 bg-gray-700 text-white text-sm rounded-md focus:outline-none focus:ring-orange-500 focus:border-orange-500 h-9"
                >
                    <option value="" disabled>-- Select Sensor --</option>
                    <optgroup label="Active">
                        <option
                            v-for="sensor in availableSensors.filter(s => s.status === SensorStatus.ACTIVE)"
                            :key="sensor.id"
                            :value="sensor.id"
                        >
                            {{ sensor.name }}
                        </option>
                    </optgroup>
                    <optgroup
                        label="Others (Inactive, Error...)"
                        v-if="availableSensors.some(s => s.status !== SensorStatus.ACTIVE)"
                    >
                        <option
                            v-for="sensor in availableSensors.filter(s => s.status !== SensorStatus.ACTIVE)"
                            :key="sensor.id"
                            :value="sensor.id"
                            class="text-gray-400"
                        >
                            {{ sensor.name }} ({{ sensor.status }})
                        </option>
                    </optgroup>
                    <option v-if="availableSensors.length === 0" disabled>No sensors available</option>
                </select>
                <button
                    @click="refreshAllData"
                    :disabled="loading || chartLoading"
                    title="Refresh Data"
                    class="p-2 rounded-full text-gray-400 hover:bg-gray-700 hover:text-white disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                >
                    <ArrowPathIcon class="h-5 w-5" :class="{'animate-spin': loading || chartLoading}" />
                </button>
            </div>
        </div>

        <div v-if="statsLoading && !initialDataLoaded" class="text-center py-10">
            <AppSpinner />
        </div>
        <div v-if="statsError && !statsLoading" class="mb-6 rounded-md bg-red-900/40 border border-red-700/50 p-4 text-red-300">
            {{ statsError }}
        </div>

        <div v-if="initialDataLoaded" class="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
            <DashboardStatCard
                title="Active Sensors"
                :icon="BeakerIcon"
                icon-color="text-green-400"
                icon-bg-color="bg-green-900/30"
                :border-color="sensorStats.error > 0 ? 'border-yellow-500/60' : 'border-gray-700 hover:border-green-500/50'"
                :value="`${sensorStats.active} / ${sensorStats.total}`"
            >
                <template #footer-extra v-if="sensorStats.error > 0 || sensorStats.inactive > 0">
                    <div class="text-xs mt-1 text-center sm:text-left">
                        <span v-if="sensorStats.error > 0" class="text-yellow-400 mr-2">{{ sensorStats.error }} errors</span>
                        <span v-if="sensorStats.inactive > 0" class="text-gray-500">{{ sensorStats.inactive }} inactive</span>
                    </div>
                </template>
            </DashboardStatCard>

            <DashboardStatCard
                title="Pending Alerts"
                :value="alertStats.pending"
                :icon="BellAlertIcon"
                icon-color="text-red-400"
                icon-bg-color="bg-red-900/30"
                :border-color="alertStats.pending > 0 ? 'border-red-500 ring-1 ring-red-500/30' : 'border-gray-700 hover:border-orange-500/50'"
                link="/alerts?status=PENDING"
                link-text="View Alerts"
                :value-class="alertStats.pending > 0 ? 'text-red-400' : 'text-white'"
            />

            <DashboardStatCard
                title="Total Cameras"
                :value="cameraStats.total"
                :icon="VideoCameraIcon"
                icon-color="text-blue-400"
                icon-bg-color="bg-blue-900/30"
                link="/cameras"
                link-text="Manage Cameras"
            />

            <DashboardStatCard
                title="Avg Temp (24h)"
                :value="avgTemp !== null ? avgTemp.toFixed(1) + '°C' : 'N/A'"
                :icon="ChartBarIcon"
                icon-color="text-teal-400"
                icon-bg-color="bg-teal-900/30"
            />
        </div>

        <div v-if="initialDataLoaded" class="mt-8 grid grid-cols-1 gap-8 lg:grid-cols-1 xl:grid-cols-3">
            <div class="bg-gray-850 p-4 rounded-lg shadow border border-gray-700 min-h-[350px] xl:col-span-2">
                <div class="flex justify-between items-center mb-4">
                    <h3 class="text-lg font-medium text-white">
                        Chart {{ selectedSensorName || 'Temperature & Humidity' }}
                    </h3>
                </div>
                <ChartsLineChart :chart-data="chartData" :loading="chartLoading" height="300px" />
            </div>

            <div class="bg-gray-850 p-4 rounded-lg shadow border border-gray-700 min-h-[350px]">
                <div class="flex justify-between items-center mb-4">
                    <h3 class="text-lg font-medium text-white">Recent Alerts</h3>
                    <NuxtLink to="/alerts" class="text-sm text-orange-400 hover:underline">View All</NuxtLink>
                </div>
                <AlertsRecentAlertsList :alerts="recentAlerts" :loading="recentAlertsLoading" />
            </div>
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useApi } from '~/composables/useApi'
import { useAsyncData } from '#app'
import DashboardStatCard from '~/components/dashboard/StatCard.vue'
import ChartsLineChart from '~/components/charts/LineChart.vue'
import AlertsRecentAlertsList from '~/components/alerts/RecentAlertsList.vue'
import AppSpinner from '~/components/ui/AppSpinner.vue'
import { BeakerIcon, BellAlertIcon, VideoCameraIcon, ArrowPathIcon, ChartBarIcon } from '@heroicons/vue/24/outline'
import { SensorStatus, type AlertWithRelations, type Sensor } from '~/types/api'
import type { ChartData } from 'chart.js'

definePageMeta({ layout: 'default',middleware: 'auth'})

const api = useApi()

const {
    data: dashboardData,
    pending: statsLoading,
    error: statsError,
    refresh: refreshStatsAndSensors,
} = useAsyncData(
    'dashboard-main-data',
    async () => {
        const [
            sensorsStatRes,
            alertsStatRes,
            camerasStatRes,
            avgTempRes,
            recentAlertsRes,
            availableSensorsRes,
        ] = await Promise.allSettled([
            api.sensors.getStats(),
            api.alerts.getStats(),
            api.cameras.getStats(),
            api.logs.getStats(),
            api.alerts.getRecentPending(5),
            api.sensors.getAll({ limit: 1000, fields: 'id,name,status' }),
        ])
        return {
            sensorStats: sensorsStatRes.status === 'fulfilled' ? sensorsStatRes.value : { total: 0, active: 0, inactive: 0, error: 0 },
            alertStats: alertsStatRes.status === 'fulfilled' ? alertsStatRes.value : { pending: 0 },
            cameraStats: camerasStatRes.status === 'fulfilled' ? camerasStatRes.value : { total: 0 },
            avgTemp: avgTempRes.status === 'fulfilled' ? avgTempRes.value.averageTemperature : null,
            recentAlerts: recentAlertsRes.status === 'fulfilled' ? recentAlertsRes.value.data : [],
            availableSensors: availableSensorsRes.status === 'fulfilled' ? availableSensorsRes.value : [],
        }
    },
    {
        lazy: true,
        server: false,
    }
)

const sensorStats = computed(() => dashboardData.value?.sensorStats ?? { total: 0, active: 0, inactive: 0, error: 0 })
const alertStats = computed(() => dashboardData.value?.alertStats ?? { pending: 0 })
const cameraStats = computed(() => dashboardData.value?.cameraStats ?? { total: 0 })
const avgTemp = computed(() => dashboardData.value?.avgTemp ?? null)
const recentAlerts = computed(() => dashboardData.value?.recentAlerts ?? [])
const availableSensors = computed(() => dashboardData.value?.availableSensors ?? [])
const initialDataLoaded = computed(() => !statsLoading.value && dashboardData.value !== null)
const recentAlertsLoading = statsLoading
const loading = computed(() => statsLoading.value || chartLoading.value)

const selectedSensorId = ref<string>('')
const selectedSensorName = computed(() => availableSensors.value.find(s => s.id === selectedSensorId.value)?.name || '')

const {
    data: chartData,
    pending: chartLoading,
    execute: fetchChartData,
} = useAsyncData(
    'dashboard-chart-data',
    () => {
        if (!selectedSensorId.value) return Promise.resolve(null)
        return api.logs.getChartData(selectedSensorId.value)
    },
    {
        immediate: false,
        watch: [selectedSensorId],
        transform: (response): ChartData<'line'> => {
            if (!response || !selectedSensorId.value) return { labels: [], datasets: [] }
            const sensorData = response[selectedSensorId.value]
            if (!sensorData || sensorData.length === 0) return { labels: [], datasets: [] }
            const tempData = sensorData
                .filter(log => log.temperature !== null)
                .map(log => ({ x: new Date(log.timestamp).valueOf(), y: log.temperature as number }))
            const humidityData = sensorData
                .filter(log => log.humidity !== null)
                .map(log => ({ x: new Date(log.timestamp).valueOf(), y: log.humidity as number }))
            return {
                datasets: [
                    ...(tempData.length > 0
                        ? [
                                {
                                    label: 'Temperature (°C)',
                                    data: tempData,
                                    borderColor: '#f87171',
                                    backgroundColor: 'rgba(248, 113, 113, 0.1)',
                                    tension: 0.1,
                                    yAxisID: 'y',
                                    pointRadius: 1.5,
                                    pointHoverRadius: 4,
                                },
                            ]
                        : []),
                    ...(humidityData.length > 0
                        ? [
                                {
                                    label: 'Humidity (%)',
                                    data: humidityData,
                                    borderColor: '#60a5fa',
                                    backgroundColor: 'rgba(96, 165, 250, 0.1)',
                                    tension: 0.1,
                                    yAxisID: 'y1',
                                    pointRadius: 1.5,
                                    pointHoverRadius: 4,
                                    hidden: false,
                                },
                            ]
                        : []),
                ],
            }
        },
    }
)

watch(
    availableSensors,
    newSensors => {
        if (newSensors && newSensors.length > 0 && !selectedSensorId.value) {
            const firstActiveSensor = newSensors.find(s => s.status === SensorStatus.ACTIVE)
            selectedSensorId.value = firstActiveSensor ? firstActiveSensor.id : newSensors[0].id
        }
    },
    { immediate: true }
)

const refreshAllData = async () => {
    await Promise.all([refreshStatsAndSensors(), fetchChartData()])
}
</script>

<style scoped>
</style>
