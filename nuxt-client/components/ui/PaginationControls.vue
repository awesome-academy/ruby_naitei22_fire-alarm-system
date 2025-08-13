<template>
    <nav v-if="totalPages > 1" class="flex items-center justify-between border-t border-gray-700 bg-gray-900 px-4 py-3 sm:px-6" aria-label="Pagination">
        <div class="hidden sm:block">
            <p class="text-sm text-gray-400">
                Showing
                <span class="font-medium text-white">{{ Math.min((currentPage - 1) * itemsPerPage + 1, totalItems) }}</span>
                to
                <span class="font-medium text-white">{{ Math.min(currentPage * itemsPerPage, totalItems) }}</span>
                of
                <span class="font-medium text-white">{{ totalItems }}</span>
                results
            </p>
        </div>
        <div class="flex flex-1 justify-between sm:justify-end">
            <button
                @click="changePage(currentPage - 1)"
                :disabled="currentPage === 1"
                class="relative inline-flex items-center rounded-md bg-gray-800 px-3 py-2 text-sm font-semibold text-gray-300 ring-1 ring-inset ring-gray-700 hover:bg-gray-700 focus-visible:outline-offset-0 disabled:opacity-50 disabled:cursor-not-allowed"
            >
                Previous
            </button>
            <button
                @click="changePage(currentPage + 1)"
                :disabled="currentPage === totalPages"
                class="relative ml-3 inline-flex items-center rounded-md bg-gray-800 px-3 py-2 text-sm font-semibold text-gray-300 ring-1 ring-inset ring-gray-700 hover:bg-gray-700 focus-visible:outline-offset-0 disabled:opacity-50 disabled:cursor-not-allowed"
            >
                Next
            </button>
        </div>
    </nav>
</template>

<script setup lang="ts">
import { computed, defineProps, defineEmits } from 'vue';

const props = defineProps({
    currentPage: {
        type: Number,
        required: true,
    },
    itemsPerPage: {
        type: Number,
        required: true,
    },
    totalItems: {
        type: Number,
        required: true,
    },
});

const emit = defineEmits(['page-change']);

const totalPages = computed(() => {
    if (props.itemsPerPage <= 0) return 1;
    return Math.ceil(props.totalItems / props.itemsPerPage);
});

const changePage = (newPage: number) => {
    if (newPage >= 1 && newPage <= totalPages.value) {
        emit('page-change', newPage);
    }
};
</script>