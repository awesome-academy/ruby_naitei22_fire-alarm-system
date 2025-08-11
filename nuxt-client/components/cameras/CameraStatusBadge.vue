<template>
    <span :class="badgeClass" class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border">
      <span class="h-2 w-2 rounded-full mr-1.5" :class="dotClass"></span>
      {{ formattedStatus }}
    </span>
  </template>
  
  <script setup lang="ts">
  import { computed, defineProps, type PropType } from 'vue';
  import { CameraStatus } from '~/types/api'; // Import enum
  
  const props = defineProps({
    status: {
      type: String as PropType<CameraStatus>,
      required: true,
    },
  });
  
  const badgeClass = computed(() => {
    switch (props.status) {
      case CameraStatus.ONLINE: return 'bg-green-100/10 text-green-400 border-green-500/30';
      case CameraStatus.RECORDING: return 'bg-blue-100/10 text-blue-400 border-blue-500/30';
      case CameraStatus.OFFLINE: return 'bg-gray-100/10 text-gray-400 border-gray-500/30';
      case CameraStatus.ERROR: return 'bg-red-100/10 text-red-400 border-red-500/30';
      default: return 'bg-gray-100/10 text-gray-500 border-gray-600';
    }
  });
  
   const dotClass = computed(() => {
    switch (props.status) {
      case CameraStatus.ONLINE: return 'bg-green-400';
      case CameraStatus.RECORDING: return 'bg-blue-400 animate-pulse'; // Thêm pulse cho recording
      case CameraStatus.OFFLINE: return 'bg-gray-400';
      case CameraStatus.ERROR: return 'bg-red-400';
      default: return 'bg-gray-500';
    }
  });
  
  const formattedStatus = computed(() => {
     switch (props.status) {
      case CameraStatus.ONLINE: return 'Online';
      case CameraStatus.OFFLINE: return 'Offline';
      case CameraStatus.RECORDING: return 'Recording';
      case CameraStatus.ERROR: return 'Error';
      default: return props.status;
    }
  });
  </script>