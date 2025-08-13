import { defineNuxtPlugin, useRuntimeConfig } from '#app';
import { io, type Socket } from 'socket.io-client';
import Swal from 'sweetalert2';
import 'sweetalert2/dist/sweetalert2.min.css';

export default defineNuxtPlugin((nuxtApp) => {
    const config = useRuntimeConfig();
    const backendUrl = config.public.apiBase || 'http://localhost:8000';
    const router = useRouter();
    let socketInstance: Socket | null = null;

    try {
        socketInstance = io(backendUrl, {
            withCredentials: true,
            transports: ['websocket', 'polling'],
            autoConnect: false,
        });

        socketInstance.on('connect', () => {
            console.log('Connected to server:', socketInstance?.id);
        });

        socketInstance.on('disconnect', (reason) => {
            console.warn('Disconnected:', reason);
        });

        socketInstance.on('connect_error', (error) => {
            console.error('Connection Error:', error.message);
        });

        socketInstance.on('new_alert', (alertData) => {
            console.log('Received new_alert event:', alertData);

            try {
                const audio = new Audio('/sounds/alert.mp3');
                audio.play().catch((playError) => {
                    console.warn('Audio playback failed:', playError);
                });
            } catch (audioError) {
                console.error('Error playing alert sound:', audioError);
            }

            Swal.fire({
                title: '<span class="text-red-400">🔥 FIRE ALERT! 🔥</span>',
                html: `
                    <div class="text-left space-y-2">
                        <p class="text-base text-gray-300">${alertData.message || 'Unknown alert message.'}</p>
                        <p class="text-sm text-gray-400">
                            <strong class="font-medium">Sensor:</strong> ${alertData.sensorName || 'N/A'}
                        </p>
                        <p class="text-xs text-gray-500 pt-2 border-t border-gray-700/50">
                            Time: ${alertData.createdAt ? new Date(alertData.createdAt).toLocaleString('en-US') : 'N/A'}
                        </p>
                    </div>
                `,
                icon: 'warning',
                iconColor: '#f87171',
                confirmButtonText: 'View Details',
                focusConfirm: false,
                background: '#1f2937',
                color: '#d1d5db',
                confirmButtonColor: '#f97316',
                width: '450px',
                customClass: {
                    popup: 'fire-alert-popup',
                },
                allowOutsideClick: false,
                allowEscapeKey: false,
            }).then((result) => {
                if (result.isConfirmed && alertData.id) {
                    router.push(`/alerts`);
                }
            });
        });

        nuxtApp.hook('app:mounted', () => {
            if (socketInstance && !socketInstance.connected) {
                socketInstance.connect();
            }
        });

    } catch (error) {
        console.error('Failed to initialize socket.io-client:', error);
        socketInstance = null;
    }

    return {
        provide: {
            socket: socketInstance,
        },
    };
});
