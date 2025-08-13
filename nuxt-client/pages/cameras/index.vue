<template>
    <div class="p-4 sm:p-6 lg:p-8">
        <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-6 pb-3 border-b border-gray-700 gap-4">
            <h1 class="text-2xl font-semibold text-white">Camera Management</h1>
            <NuxtLink
                to="/cameras/config"
                class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-orange-600 hover:bg-orange-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-800 focus:ring-orange-500"
            >
                <PlusIcon class="h-5 w-5 mr-2" />
                Add New Camera
            </NuxtLink>
        </div>

        <div v-if="pending && !cameras" class="text-center py-20">
            <AppSpinner class="w-10 h-10 inline-block" />
            <p class="text-gray-400 mt-3">Loading camera list...</p>
        </div>
        <div v-else-if="error" class="error-alert mb-6 flex justify-between items-center">
            <div class="flex items-center">
                <XCircleIcon class="h-5 w-5 mr-2 flex-shrink-0" />
                <span>{{ 'Unable to load camera list.' }}</span>
            </div>
            <button @click="refresh()" class="text-sm font-medium text-orange-400 hover:underline">Retry</button>
        </div>
        <div v-else>
            <CamerasCameraTable
                :cameras="cameras ?? []"
                :loading="pending"
                @delete="confirmDeleteCamera"
                @edit="editCamera"
                @view="viewCameraStream"
            />
        </div>

        <AppModal :is-open="showDeleteConfirm" @close="cancelDelete">
            <template #title>Confirm Camera Deletion</template>
            <template #content>
                <p class="text-sm text-gray-400">
                    Are you sure you want to delete the camera <strong class="text-white">{{ cameraToDelete?.name }}</strong>? This action cannot be undone.
                </p>
            </template>
            <template #footer>
                <button @click="executeDelete" :disabled="deleting" class="btn-danger inline-flex items-center">
                    <AppSpinner v-if="deleting" class="w-4 h-4 mr-2" />
                    {{ deleting ? 'Deleting...' : 'Delete' }}
                </button>
                <button @click="cancelDelete" class="ml-3 btn-secondary">Cancel</button>
            </template>
        </AppModal>
    </div>
</template>

<script setup lang="ts">
import { ref, nextTick } from 'vue';
import { navigateTo, useAsyncData } from '#app';
import { useApi } from '~/composables/useApi';
import Swal from 'sweetalert2';
import 'sweetalert2/dist/sweetalert2.min.css';
import CamerasCameraTable from '~/components/cameras/CameraTable.vue';
import AppModal from '~/components/ui/AppModal.vue';
import AppSpinner from '~/components/ui/AppSpinner.vue';
import { PlusIcon, XCircleIcon } from '@heroicons/vue/20/solid';
import type { Camera } from '~/types/api';

definePageMeta({
    layout: 'default',
    middleware: ['auth'],
});

const api = useApi();
const showDeleteConfirm = ref(false);
const cameraToDelete = ref<Camera | null>(null);
const deleting = ref(false);

const { data: cameras, pending, error, refresh } = useAsyncData(
    'cameras-list',
    () => api.cameras.getAll(),
    { server: false, lazy: true }
);

const editCamera = (camera: Camera) => {
    navigateTo(`/cameras/config?edit=${camera.id}`);
};

const confirmDeleteCamera = (camera: Camera) => {
    cameraToDelete.value = camera;
    showDeleteConfirm.value = true;
};

const cancelDelete = () => {
    showDeleteConfirm.value = false;
    nextTick(() => {
        cameraToDelete.value = null;
    });
};

const executeDelete = async () => {
    if (!cameraToDelete.value) return;
    deleting.value = true;
    try {
        await api.cameras.delete(cameraToDelete.value.id);
        await refresh();
        cancelDelete();
        Swal.fire({
            icon: 'success',
            title: 'Deleted!',
            text: `Camera "${cameraToDelete.value.name}" has been deleted.`,
            timer: 2000,
            timerProgressBar: true,
            showConfirmButton: false,
            background: '#1f2937',
            color: '#d1d5db',
            customClass: { popup: 'swal2-dark' },
            toast: true,
            position: 'top-end',
        });
    } catch (err: any) {
        Swal.fire({
            icon: 'error',
            title: 'Error!',
            text: err.data?.message || `Unable to delete camera.`,
            background: '#1f2937',
            color: '#d1d5db',
            confirmButtonColor: '#f97316',
            customClass: { popup: 'swal2-dark' },
        });
    } finally {
        deleting.value = false;
    }
};

const viewCameraStream = (camera: Camera) => {
    Swal.fire({
        title: `View Camera: ${camera.name}`,
        text: 'Live view/snapshot functionality is not implemented in this interface.',
        icon: 'info',
        background: '#1f2937',
        color: '#d1d5db',
        confirmButtonColor: '#f97316',
        customClass: { popup: 'swal2-dark' },
    });
};
</script>

<style scoped>
.error-alert {
    display: flex;
    align-items: center;
    padding: 0.75rem;
    border-radius: 0.375rem;
    border-width: 1px;
    font-size: 0.875rem;
    line-height: 1.25rem;
    background-color: rgba(191, 27, 27, 0.1);
    border-color: rgba(220, 38, 38, 0.3);
    color: #fca5a5;
}
.btn-secondary {
    display: inline-flex;
    justify-content: center;
    border-radius: 0.375rem;
    border-width: 1px;
    border-color: #4b5563;
    background-color: #374151;
    padding-left: 1rem;
    padding-right: 1rem;
    padding-top: 0.5rem;
    padding-bottom: 0.5rem;
    font-size: 0.875rem;
    font-weight: 500;
    color: #d1d5db;
}
.btn-secondary:hover {
    background-color: #4b5563;
}
.btn-danger {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding-left: 1rem;
    padding-right: 1rem;
    padding-top: 0.5rem;
    padding-bottom: 0.5rem;
    background-color: #dc2626;
    border-width: 1px;
    border-color: transparent;
    border-radius: 0.375rem;
    font-size: 0.875rem;
    font-weight: 500;
    color: #ffffff;
    box-shadow: 0 1px 2px 0 rgb(0 0 0 / 0.05);
}
.btn-danger:hover {
    background-color: #b91c1c;
}
.btn-danger:disabled {
    opacity: 0.5;
    cursor: not-allowed;
}
:global(.swal2-dark) {
    background-color: #1f2937 !important;
    color: #d1d5db !important;
}
:global(.swal2-dark .swal2-title) {
    color: #ffffff !important;
}
:global(.swal2-dark .swal2-html-container) {
    color: #d1d5db !important;
}
:global(.swal2-dark .swal2-timer-progress-bar) {
    background: #f97316 !important;
}
</style>
