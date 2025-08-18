import Swal from 'sweetalert2';
import 'sweetalert2/dist/sweetalert2.min.css';
import type { Subscription, Cable } from 'actioncable';

let cableConsumer: Cable | null = null;
let subscription: Subscription | null = null;

export const useActionCable = () => {
    const router = useRouter();
    const { isAuthenticated } = useAuth();

    const connect = async () => {
        if (!process.client || !isAuthenticated.value || cableConsumer) return;

        try {
            const ActionCable = await import('actioncable');
            const cableUrl = 'ws://localhost:3000/cable';
            cableConsumer = ActionCable.createConsumer(cableUrl);

            subscription = cableConsumer.subscriptions.create('AlertsChannel', {
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
        } catch (error) {
            console.error('Failed to create Action Cable consumer:', error);
        }
    };

    const disconnect = () => {
        if (cableConsumer) {
            cableConsumer.disconnect();
            cableConsumer = null;
            subscription = null;
        }
    };

    if (process.client) {
        watch(isAuthenticated, (isAuth) => {
            if (isAuth && !cableConsumer) {
                connect();
            } else if (!isAuth) {
                disconnect();
            }
        }, { immediate: true });
    }
};
