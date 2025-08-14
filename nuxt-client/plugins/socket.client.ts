import { defineNuxtPlugin } from '#app';
import { createConsumer } from 'actioncable';
import Swal from 'sweetalert2';
import 'sweetalert2/dist/sweetalert2.min.css';

export default defineNuxtPlugin(() => {
    const cableUrl = 'ws://localhost:3000/cable';
    const router = useRouter();

    try {
        const cable = createConsumer(cableUrl);

        cable.subscriptions.create('AlertsChannel', {
            connected() {
                console.log('Connected to Action Cable: AlertsChannel');
            },
            disconnected() {
                console.warn('Disconnected from Action Cable: AlertsChannel');
            },
            received(alertData: any) {
                console.log('Received new alert via Action Cable:', alertData);
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
                                <strong class="font-medium">Zone:</strong> ${alertData.zone_name || 'N/A'}
                            </p>
                            <p class="text-xs text-gray-500 pt-2 border-t border-gray-700/50">
                                Time: ${alertData.created_at ? new Date(alertData.created_at).toLocaleString() : 'N/A'}
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
                }).then((result: any) => {
                    if (result.isConfirmed && alertData.id) {
                        router.push(`/alerts`);
                    }
                });
            }
        });
    } catch (error) {
        console.error('Failed to initialize Action Cable consumer:', error);
    }

    return {
        provide: {},
    };
});
