import Swal from 'sweetalert2';
import 'sweetalert2/dist/sweetalert2.min.css';
import type { Subscription, Cable } from 'actioncable';
import { useLatestSensorLog } from '~/composables/useRealtimeState';
import { useAuth } from '~/composables/useAuth';

export default defineNuxtPlugin((nuxtApp) => {
    let cableConsumer: Cable | null = null;
    const subscriptions: { [key: string]: Subscription } = {};

    const latestSensorLog = useLatestSensorLog();
    const { isAuthenticated } = useAuth();
    const router = useRouter();

    const subscribeToAlerts = () => {
        if (!cableConsumer || subscriptions.alerts) return;
        subscriptions.alerts = cableConsumer.subscriptions.create('AlertsChannel', {
            connected() {
                console.log('Subscribed to AlertsChannel.');
            },
            disconnected() {
                console.warn('Disconnected from AlertsChannel.');
            },
            received(alertData: any) {
                try {
                    const audio = new Audio('/sounds/alert.mp3');
                    audio.play().catch(e => console.warn('Audio play failed.', e));
                } catch (e) {
                    console.error('Error creating alert audio:', e);
                }
                Swal.fire({
                    title: '<span class="text-red-400">🔥 FIRE ALERT! 🔥</span>',
                    html: `
                        <div class="text-left text-sm space-y-2 swal-content-container">
                            <p class="text-base text-gray-300">${alertData.message || 'An unknown alert has occurred.'}</p>
                            <div class="pt-2 mt-2 border-t border-gray-600">
                                <p><strong class="w-20 inline-block text-gray-400">Zone:</strong> ${alertData.zone_name || 'N/A'}</p>
                                <p><strong class="w-20 inline-block text-gray-400">Time:</strong> ${alertData.created_at ? new Date(alertData.created_at).toLocaleString() : 'N/A'}</p>
                            </div>
                        </div>
                    `,
                    icon: 'warning',
                    iconColor: '#f87171',
                    confirmButtonText: 'View Alerts',
                    background: '#1f2937',
                    color: '#d1d5db',
                    confirmButtonColor: '#f97316',
                    width: '450px',
                    customClass: { popup: 'swal2-dark' },
                }).then((result) => {
                    if (result.isConfirmed) {
                        router.push('/alerts');
                    }
                });
            }
        });
    };

    const subscribeToSensorLogs = () => {
        if (!cableConsumer || subscriptions.sensorLogs) return;
        subscriptions.sensorLogs = cableConsumer.subscriptions.create('SensorLogsChannel', {
            connected() {
                console.log('Subscribed to SensorLogsChannel.');
            },
            disconnected() {
                console.warn('Disconnected from SensorLogsChannel.');
            },
            received(logData: any) {
                console.log('Received new sensor log via ActionCable:', logData);
                latestSensorLog.value = logData;
            }
        });
    };

    const connect = async () => {
        if (cableConsumer) return;
        try {
            console.log('Attempting to connect to Action Cable...');
            const ActionCable = await import('actioncable');
            const cableUrl = `ws://${window.location.hostname}:3000/cable`;
            cableConsumer = ActionCable.createConsumer(cableUrl);
            subscribeToAlerts();
            subscribeToSensorLogs();
        } catch (error) {
            console.error('Failed to create Action Cable consumer:', error);
        }
    };

    const disconnect = () => {
        if (cableConsumer) {
            console.log('Disconnecting from Action Cable...');
            cableConsumer.disconnect();
            cableConsumer = null;
            Object.keys(subscriptions).forEach(key => delete subscriptions[key]);
        }
    };

    watch(isAuthenticated, (isAuth) => {
        if (isAuth) {
            connect();
        } else {
            disconnect();
        }
    }, { immediate: true });
});
