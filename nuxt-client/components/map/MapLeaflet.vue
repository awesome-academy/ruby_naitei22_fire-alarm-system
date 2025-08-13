<template>
    <div ref="mapContainer" class="w-full h-full z-0"></div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch, defineProps, defineEmits, nextTick, defineExpose } from 'vue';
import type { Map, Marker, LayerGroup, CircleMarker, DivIcon, LatLngExpression } from 'leaflet';
import { type Sensor, type Camera, type Alert, SensorStatus } from '~/types/api';

const props = defineProps({
    sensors: {
        type: Array as () => Sensor[],
        default: () => []
    },
    cameras: {
        type: Array as () => Camera[],
        default: () => []
    },
    activeAlerts: {
        type: Array as () => Alert[],
        default: () => []
    },
    initialCenter: {
        type: Array as unknown as () => [number, number],
        default: () => [10.7769, 106.7009]
    },
    initialZoom: {
        type: Number,
        default: 15
    },
    selectedItemId: {
        type: String as () => string | null,
        default: null
    }
});

const emit = defineEmits(['item-select']);

const mapContainer = ref<HTMLElement | null>(null);
let mapInstance: Map | null = null;
let sensorMarkersLayer: LayerGroup | null = null;
let cameraMarkersLayer: LayerGroup | null = null;
let alertPulseLayer: LayerGroup | null = null;
let L: any = null;

const initializeMap = () => {
    if (!L || !mapContainer.value || mapInstance) return;

    try {
        mapInstance = L.map(mapContainer.value, { zoomControl: false }).setView(props.initialCenter, props.initialZoom);

        L.control.zoom({ position: 'topright' }).addTo(mapInstance);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
            maxZoom: 19
        }).addTo(mapInstance);

        sensorMarkersLayer = L.layerGroup().addTo(mapInstance);
        cameraMarkersLayer = L.layerGroup().addTo(mapInstance);
        alertPulseLayer = L.layerGroup().addTo(mapInstance);

        updateMarkers();
        exposedMapInstance.value = mapInstance;
    } catch (error) {
        console.error('Error initializing Leaflet map:', error);
    }
};

onMounted(async () => {
    if (process.client) {
        try {
            const leaflet = await import('leaflet');
            L = leaflet.default;
            await import('leaflet/dist/leaflet.css');
            await nextTick();
            initializeMap();
        } catch (error) {
            console.error('Failed to load Leaflet dynamically:', error);
        }
    }
});

onUnmounted(() => {
    if (mapInstance) {
        mapInstance.remove();
        mapInstance = null;
        exposedMapInstance.value = null;
    }
});

watch(() => [props.sensors, props.cameras, props.activeAlerts], () => {
    if (mapInstance && L) {
        updateMarkers();
    }
}, { deep: true });

watch(() => props.selectedItemId, (newId, oldId) => {
    if (mapInstance && L) {
        console.log(`Selected item changed to: ${newId}`);
    }
});

const updateMarkers = () => {
    if (!mapInstance || !sensorMarkersLayer || !cameraMarkersLayer || !alertPulseLayer) return;

    sensorMarkersLayer.clearLayers();
    cameraMarkersLayer.clearLayers();
    alertPulseLayer.clearLayers();

    const alertedSensorIds = new Set(props.activeAlerts.map(a => a.sensorId));

    props.sensors.forEach(sensor => {
        if (sensor.latitude != null && sensor.longitude != null) {
            const isAlerting = alertedSensorIds.has(sensor.id);
            const marker = L.circleMarker([sensor.latitude, sensor.longitude], {
                radius: isAlerting ? 7 : 6,
                fillColor: getSensorColor(sensor.status, isAlerting),
                color: isAlerting ? '#FFFFFF' : '#2d3748',
                weight: isAlerting ? 2 : 1,
                opacity: 1,
                fillOpacity: isAlerting ? 0.9 : 0.75,
                itemId: sensor.id,
            })
                .bindPopup(generateSensorPopupContent(sensor, isAlerting))
                .on('click', () => {
                    emit('item-select', { id: sensor.id, type: 'Sensor', name: sensor.name });
                });
            sensorMarkersLayer?.addLayer(marker);

            if (isAlerting) {
                const pulseMarker = L.circleMarker([sensor.latitude, sensor.longitude], {
                    radius: 8,
                    fill: false,
                    color: '#EF4444',
                    weight: 3,
                    opacity: 0.6,
                    className: 'leaflet-pulsing-icon'
                });
                alertPulseLayer?.addLayer(pulseMarker);
            }
        }
    });

    props.cameras.forEach(camera => {
        if (camera.latitude != null && camera.longitude != null) {
            const cameraIcon = L.divIcon({
                html: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-6 h-6 text-cyan-400 drop-shadow-md"><path d="M1 8a2 2 0 0 1 2-2h2l1.172-1.172a2 2 0 0 1 2.828 0L10.828 6H13a2 2 0 0 1 2 2v6a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8Zm3 6a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z" /><path d="M15.5 8.5a1.5 1.5 0 1 1-3 0 1.5 1.5 0 0 1 3 0Z" /></svg>`,
                className: 'bg-transparent border-none',
                iconSize: [24, 24],
                iconAnchor: [12, 12]
            });

            const marker = L.marker([camera.latitude, camera.longitude], {
                icon: cameraIcon,
                title: camera.name,
                itemId: camera.id,
            })
                .bindPopup(generateCameraPopupContent(camera))
                .on('click', () => {
                    emit('item-select', { id: camera.id, type: 'Camera', name: camera.name });
                });
            cameraMarkersLayer?.addLayer(marker);
        }
    });
};

const generateSensorPopupContent = (sensor: Sensor, isAlerting: boolean): string => {
    let content = `<div class="text-xs space-y-0.5">`;
    content += `<strong class="text-sm block mb-1">${sensor.name}</strong>`;
    content += `<div><strong>Type:</strong> ${sensor.type}</div>`;
    content += `<div><strong>Status:</strong> <span style="color:${getSensorColor(sensor.status, false)}; font-weight:bold;">${formatStatus(sensor.status)}</span></div>`;
    if (sensor.latestLog) {
        if (sensor.latestLog.temperature != null) {
            content += `<div><strong>Temperature:</strong> ${sensor.latestLog.temperature.toFixed(1)}°C</div>`;
        }
        if (sensor.latestLog.humidity != null) {
            content += `<div><strong>Humidity:</strong> ${sensor.latestLog.humidity.toFixed(0)}%</div>`;
        }
        content += `<div class="text-gray-500 text-[10px] mt-1">Last Log: ${formatDateTime(sensor.latestLog.createdAt)}</div>`;
    }
    if (isAlerting) {
        content += `<div class="mt-1 p-1 bg-red-100 border border-red-300 rounded text-red-700 font-bold">ALERTING!</div>`;
    }
    content += `<div class="mt-1.5 pt-1 border-t border-gray-200 text-gray-600">${sensor.location}</div>`;
    content += `</div>`;
    return content;
};

const generateCameraPopupContent = (camera: Camera): string => {
    let content = `<div class="text-xs space-y-0.5">`;
    content += `<strong class="text-sm block mb-1">${camera.name}</strong>`;
    content += `<div><strong>Zone:</strong> ${camera.zone?.name || 'N/A'}</div>`;
    content += `</div>`;
    return content;
};

const getSensorColor = (status: SensorStatus, isAlerting: boolean): string => {
    if (isAlerting) return '#EF4444';
    switch (status) {
        case SensorStatus.ACTIVE: return '#22C55E';
        case SensorStatus.ERROR: return '#EAB308';
        case SensorStatus.INACTIVE: return '#6B7280';
        case SensorStatus.MAINTENANCE: return '#3B82F6';
        default: return '#4B5563';
    }
};

const formatStatus = (status: SensorStatus): string => {
    return status;
};

const formatDateTime = (dateTimeString: string | Date | undefined | null): string => {
    if (!dateTimeString) return 'N/A';
    try {
        const date = new Date(dateTimeString);
        if (isNaN(date.getTime())) return 'Invalid Date';
        return date.toLocaleString('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' });
    } catch (e) {
        return 'Err';
    }
};

const exposedMapInstance = ref<Map | null>(null);
defineExpose({
    mapInstance: exposedMapInstance
});
</script>

<style>
@keyframes leaflet-pulsing {
    0% { transform: scale(1); opacity: 0.6; }
    70% { transform: scale(3); opacity: 0; }
    100% { transform: scale(1); opacity: 0; }
}

.leaflet-pulsing-icon .leaflet-marker-icon,
.leaflet-pulsing-icon.leaflet-zoom-animated {
    animation: leaflet-pulsing 1.8s ease-out infinite;
    border-radius: 50%;
}

.h-full { height: 100%; }

.leaflet-popup-content-wrapper {
    background-color: #1f2937;
    color: #d1d5db;
    border-radius: 0.5rem;
    box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
}

.leaflet-popup-content {
    margin: 10px 12px;
    line-height: 1.4;
}

.leaflet-popup-close-button {
    color: #9ca3af;
    padding-top: 6px;
    padding-right: 6px;
}

.leaflet-popup-close-button:hover {
    color: #ffffff;
    background-color: transparent;
}
</style>
