import { createApiClient } from '~/utils/apiClient';
import authRepository from '~/repositories/auth';
import alertsRepository from '~/repositories/alerts';
import camerasRepository from '~/repositories/cameras';
import logsRepository from '~/repositories/logs';
import sensorsRepository from '~/repositories/sensors';
import usersRepository from '~/repositories/users';
import zonesRepository from '~/repositories/zones';

export type Api = ReturnType<typeof createApi>;

function createApi() {
    const apiClient = createApiClient();
    return {
        auth: authRepository(apiClient),
        alerts: alertsRepository(apiClient),
        cameras: camerasRepository(apiClient),
        logs: logsRepository(apiClient),
        sensors: sensorsRepository(apiClient),
        users: usersRepository(apiClient),
        zones: zonesRepository(apiClient),
    };
}

export default defineNuxtPlugin(() => {
    const api = createApi();
    return {
        provide: {
            api,
        },
    };
});
