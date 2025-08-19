<template>
    <div class="flex h-screen bg-gray-800 text-gray-100">
        <LayoutTheSidebar />
        <div class="flex-1 flex flex-col overflow-hidden ml-64">
            <LayoutTheHeader />
            <main class="flex-1 overflow-x-hidden overflow-y-auto bg-gray-800 p-4 sm:p-6 lg:p-8 custom-scrollbar">
                <slot />
            </main>
        </div>
        <ClientOnly>
            <div
                v-if="!audioUnlocked"
                class="fixed bottom-4 right-4 bg-gray-700 text-white p-3 rounded-lg shadow-lg text-sm z-50 flex items-center space-x-3 border border-gray-600"
            >
                <SpeakerWaveIcon class="h-5 w-5 text-orange-400" />
                <span>Enable audio notifications for alerts?</span>
                <button
                    @click="unlockAudio"
                    class="px-3 py-1 bg-orange-600 hover:bg-orange-700 rounded text-xs font-semibold focus:outline-none focus:ring-2 focus:ring-orange-500 focus:ring-offset-2 focus:ring-offset-gray-700"
                >
                    Enable
                </button>
                <button
                    @click="audioUnlocked = true"
                    title="Close"
                    class="p-1 text-gray-400 hover:text-white"
                >
                    <XMarkIcon class="h-4 w-4" />
                </button>
            </div>
        </ClientOnly>
    </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import LayoutTheSidebar from '~/components/layout/TheSidebar.vue';
import LayoutTheHeader from '~/components/layout/TheHeader.vue';
import { SpeakerWaveIcon, XMarkIcon } from '@heroicons/vue/20/solid';

const audioUnlocked = ref(false);

const unlockAudio = () => {
    if (process.client && !audioUnlocked.value) {
        try {
            const silentAudioPlayer = new Audio('/sounds/alert.mp3');
            silentAudioPlayer.volume = 0;
            silentAudioPlayer
                .play()
                .then(() => {
                    audioUnlocked.value = true;
                    console.log('Audio context has been unlocked by user interaction.');
                })
                .catch((error) => {
                    console.warn('Could not unlock audio context, alerts may be silent.', error);
                    audioUnlocked.value = true;
                });
        } catch (error) {
            console.error('Error while trying to create silent audio player:', error);
            audioUnlocked.value = true;
        }
    }
};
</script>

<style>
::-webkit-scrollbar {
    width: 8px;
    height: 8px;
}
::-webkit-scrollbar-track {
    background: #1f2937;
}
::-webkit-scrollbar-thumb {
    background: #4b5563;
    border-radius: 4px;
}
::-webkit-scrollbar-thumb:hover {
    background: #6b7280;
}
.custom-scrollbar::-webkit-scrollbar-track {
    background: #374151;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
    background: #6b7280;
}
.custom-scrollbar::-webkit-scrollbar-thumb:hover {
    background: #9ca3af;
}
</style>
