<template>
    <TransitionRoot appear :show="isOpen" as="template">
        <Dialog as="div" @close="closeModal" class="relative z-50">
            <TransitionChild
                as="template"
                enter="duration-300 ease-out"
                enter-from="opacity-0"
                enter-to="opacity-100"
                leave="duration-200 ease-in"
                leave-from="opacity-100"
                leave-to="opacity-0"
            >
                <div class="fixed inset-0 bg-black bg-opacity-60 backdrop-blur-sm" />
            </TransitionChild>

            <div class="fixed inset-0 overflow-y-auto">
                <div class="flex min-h-full items-center justify-center p-4 text-center">
                    <TransitionChild
                        as="template"
                        enter="duration-300 ease-out"
                        enter-from="opacity-0 scale-95"
                        enter-to="opacity-100 scale-100"
                        leave="duration-200 ease-in"
                        leave-from="opacity-100 scale-100"
                        leave-to="opacity-0 scale-95"
                    >
                        <DialogPanel class="w-full max-w-md transform overflow-hidden rounded-lg bg-gray-800 border border-gray-700 p-6 text-left align-middle shadow-xl transition-all">
                            <DialogTitle
                                as="h3"
                                class="text-lg font-medium leading-6 text-white mb-4"
                            >
                                <slot name="title">Default Title</slot>
                            </DialogTitle>

                            <div class="mt-2">
                                <div class="text-sm text-gray-300">
                                    <slot name="content">Default modal content goes here.</slot>
                                </div>
                            </div>

                            <div class="mt-6 flex justify-end space-x-3">
                                <slot name="footer">
                                    <button
                                        type="button"
                                        class="inline-flex justify-center rounded-md border border-gray-600 bg-gray-700 px-4 py-2 text-sm font-medium text-gray-300 hover:bg-gray-600 focus:outline-none focus-visible:ring-2 focus-visible:ring-gray-500 focus-visible:ring-offset-2 focus-visible:ring-offset-gray-800"
                                        @click="closeModal"
                                    >
                                        Close
                                    </button>
                                </slot>
                            </div>
                        </DialogPanel>
                    </TransitionChild>
                </div>
            </div>
        </Dialog>
    </TransitionRoot>
</template>

<script setup lang="ts">
import {
    TransitionRoot,
    TransitionChild,
    Dialog,
    DialogPanel,
    DialogTitle,
} from '@headlessui/vue';
import { defineProps, defineEmits } from 'vue';

const props = defineProps({
    isOpen: {
        type: Boolean,
        required: true,
    },
});

const emit = defineEmits(['close']);

function closeModal() {
    emit('close');
}
</script>

<style scoped>
</style>
