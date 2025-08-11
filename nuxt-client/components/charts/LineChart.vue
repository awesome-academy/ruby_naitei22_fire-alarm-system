<template>
    <div :style="{ height: height, position: 'relative' }">
        <Line v-if="chartData && !loading" :data="chartData" :options="chartOptions" />
        <div v-if="loading" class="absolute inset-0 flex items-center justify-center bg-gray-850 bg-opacity-50">
            <AppSpinner />
        </div>
        <div v-if="!loading && (!chartData || chartData.datasets.length === 0 || chartData.datasets.every(ds => ds.data.length === 0))"
                 class="absolute inset-0 flex items-center justify-center text-gray-500 text-sm italic">
            No data available to display the chart.
        </div>
    </div>
</template>

<script setup lang="ts">
import { defineProps, computed } from 'vue';
import { Line } from 'vue-chartjs';
import {
    Chart as ChartJS,
    LinearScale,
    PointElement,
    LineElement,
    Title,
    Tooltip,
    Legend,
    TimeScale,
    Colors,
    type ChartData,
    type ChartOptions
} from 'chart.js';
import 'chartjs-adapter-date-fns';

ChartJS.register(
    TimeScale,
    LinearScale,
    PointElement,
    LineElement,
    Title,
    Tooltip,
    Legend,
    Colors
);

const props = defineProps({
    chartData: {
        type: Object as () => ChartData<'line'> | null,
        default: null,
    },
    loading: {
        type: Boolean,
        default: false,
    },
    height: {
        type: String,
        default: '300px'
    }
});

const chartOptions = computed<ChartOptions<'line'>>(() => ({
    responsive: true,
    maintainAspectRatio: false,
    interaction: {
        mode: 'index',
        intersect: false,
    },
    scales: {
        x: {
            type: 'time',
            time: {
                unit: 'hour',
                tooltipFormat: 'dd/MM/yyyy HH:mm:ss',
                displayFormats: {
                    hour: 'HH:mm',
                    day: 'dd/MM',
                    month: 'MM/yyyy'
                }
            },
            title: { display: true, text: 'Time', color: '#9ca3af' },
            ticks: { color: '#9ca3af' },
            grid: { color: 'rgba(107, 114, 128, 0.2)' }
        },
        y: {
            type: 'linear',
            display: true,
            position: 'left',
            title: { display: true, text: 'Temperature (°C)', color: '#f87171' },
            ticks: { color: '#f87171' },
            grid: { color: 'rgba(107, 114, 128, 0.1)' }
        },
        y1: {
            type: 'linear',
            display: true,
            position: 'right',
            title: { display: true, text: 'Humidity (%)', color: '#60a5fa' },
            ticks: { color: '#60a5fa' },
            grid: { drawOnChartArea: false },
            min: 0,
            max: 100
        }
    },
    plugins: {
        legend: {
            position: 'top',
            labels: { color: '#d1d5db' }
        },
        tooltip: {
            backgroundColor: 'rgba(31, 41, 55, 0.9)',
            titleColor: '#ffffff',
            bodyColor: '#d1d5db',
            boxPadding: 4,
            padding: 8,
            borderColor: 'rgba(107, 114, 128, 0.5)',
            borderWidth: 1
        },
        colors: {
            enabled: true,
        }
    }
}));
</script>
