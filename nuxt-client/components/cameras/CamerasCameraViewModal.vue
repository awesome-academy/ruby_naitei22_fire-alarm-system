<template>
    <AppModal :is-open="isOpen" @close="$emit('close')">
        <template #title>
            View Camera: {{ camera?.name }}
        </template>

        <template #content>
            <div v-if="!camera" class="text-center text-gray-500">No camera information available.</div>
            <div v-else>
                <dl class="text-sm space-y-1 mb-4">
                    <div class="flex">
                        <dt class="text-gray-400 w-20">Zone:</dt>
                        <dd class="text-gray-200">{{ camera.zone?.name || 'N/A' }}</dd>
                    </div>
                    <div class="flex">
                        <dt class="text-gray-400 w-20">URL:</dt>
                        <dd class="text-gray-200 text-xs font-mono break-all">{{ camera.url }}</dd>
                    </div>
                    <div class="flex items-center">
                        <dt class="text-gray-400 w-20">Status:</dt>
                        <dd><CamerasCameraStatusBadge :status="camera.status" /></dd>
                    </div>
                </dl>

                <div class="aspect-video bg-black rounded border border-gray-700 relative overflow-hidden">
                    <div v-if="pending" class="absolute inset-0 flex flex-col items-center justify-center text-gray-400 z-10">
                        <AppSpinner class="w-8 h-8" />
                        <span class="mt-2 text-xs">Loading snapshot...</span>
                    </div>
                    <div v-else-if="error" class="absolute inset-0 flex flex-col items-center justify-center text-red-400 z-10 p-4 text-center">
                        <ExclamationTriangleIcon class="w-8 h-8 mb-2" />
                        <p class="text-xs font-medium">Snapshot loading error:</p>
                        <p class="text-xs mt-1">{{ error.data?.message || error.message }}</p>
                        <button @click="fetchSnapshot" class="mt-3 text-xs text-orange-300 hover:underline">Retry</button>
                    </div>
                    <img v-else-if="snapshotUrl" :src="snapshotUrl" alt="Camera Snapshot" class="absolute inset-0 w-full h-full object-contain" />
                    <div v-else class="absolute inset-0 flex items-center justify-center text-gray-600 italic text-sm">
                        No snapshot available
                    </div>
                </div>
                <p class="text-xs text-gray-500 mt-2 text-center">Snapshot is refreshed when this window is opened or by using the refresh button.</p>
            </div>
        </template>

        <template #footer>
            <div class="flex justify-between w-full items-center">
                <button @click="fetchSnapshot" :disabled="pending" title="Refresh Snapshot" class="p-2 rounded-full text-gray-400 hover:bg-gray-700 hover:text-white disabled:opacity-50 disabled:cursor-not-allowed transition-colors">
                    <ArrowPathIcon class="h-4 w-4" :class="{ 'animate-spin': pending }" />
                </button>
                <button type="button" class="btn-secondary" @click="$emit('close')">
                    Close
                </button>
            </div>
        </template>
    </AppModal>
</template>

<script setup lang="ts">
import { ref, watch, onUnmounted } from 'vue';
import { useApi } from '~/composables/useApi';
import AppModal from '~/components/ui/AppModal.vue';
import AppSpinner from '~/components/ui/AppSpinner.vue';
import CamerasCameraStatusBadge from '~/components/cameras/CameraStatusBadge.vue';
import { ArrowPathIcon, ExclamationTriangleIcon } from '@heroicons/vue/24/outline';
import type { CameraWithDetails } from '~/types/api';

const props = defineProps({
    isOpen: { type: Boolean, required: true },
    camera: { type: Object as () => CameraWithDetails | null, default: null },
});
defineEmits(['close']);

const api = useApi();

const snapshotUrl = ref<string | null>(null);
const pending = ref(false);
const error = ref<any | null>(null);

const revokeSnapshotUrl = () => {
    if (snapshotUrl.value) {
        URL.revokeObjectURL(snapshotUrl.value);
        snapshotUrl.value = null;
    }
};

const fetchSnapshot = async () => {
    if (!props.camera?.id || pending.value) return;

    pending.value = true;
    error.value = null;
    revokeSnapshotUrl();

    try {
        const blob = await api.cameras.getSnapshot(props.camera.id);
        if (blob.type.startsWith('image/')) {
            snapshotUrl.value = URL.createObjectURL(blob);
        } else {
            const errorText = await blob.text();
            const errorJson = JSON.parse(errorText);
            throw new Error(errorJson.message || 'Invalid response type. Expected an image.');
        }
    } catch (err: any) {
        error.value = err;
        snapshotUrl.value = null;
    } finally {
        pending.value = false;
    }
};

watch(() => props.isOpen, (newIsOpen) => {
    if (newIsOpen && props.camera?.id) {
        fetchSnapshot();
    } else {
        revokeSnapshotUrl();
        error.value = null;
        pending.value = false;
    }
});

onUnmounted(() => {
    revokeSnapshotUrl();
});
</script>

<style scoped>
.btn-secondary {
    /* Add your styles here */
}
dl dt {
    flex-shrink: 0;
}
dl dd {
    word-break: break-word;
}
</style>
