import { ofetch, FetchError, type FetchOptions } from 'ofetch';

let isRefreshing = false;
let failedQueue: Array<{ resolve: (value?: any) => void; reject: (reason?: any) => void }> = [];

const processQueue = (error: Error | null) => {
    failedQueue.forEach(prom => {
        if (error) {
            prom.reject(error);
        } else {
            prom.resolve();
        }
    });
    failedQueue = [];
};

export const createApiClient = () => {
    const config = useRuntimeConfig();

    return ofetch.create({
        baseURL: config.public.apiBase,
        credentials: 'include',

        async onResponseError({ request, response, options }) {
            const originalRequestOptions = options as FetchOptions & { _retry?: boolean };
            const requestPath = new URL(request.toString(), 'http://localhost').pathname;

            if (requestPath.includes('/auth/refresh')) {
                return;
            }

            if (response.status === 401 && !originalRequestOptions._retry) {
                originalRequestOptions._retry = true;

                if (isRefreshing) {
                    return new Promise((resolve, reject) => {
                        failedQueue.push({ resolve, reject });
                    })
                        .then(() => ofetch(request, originalRequestOptions))
                        .catch(e => Promise.reject(e));
                }

                isRefreshing = true;

                try {
                    await ofetch('/auth/refresh', {
                        baseURL: config.public.apiBase,
                        method: 'POST',
                        credentials: 'include',
                    });

                    processQueue(null);
                    return ofetch(request, originalRequestOptions);
                } catch (refreshError: any) {
                    processQueue(refreshError);

                    const userState = useState('authStateUser');
                    userState.value = null;

                    if (process.client) {
                        await navigateTo('/login', { replace: true });
                    }

                    return Promise.reject(refreshError);
                } finally {
                    isRefreshing = false;
                }
            }

            const error = new FetchError(`[${response.status}] ${response.statusText}`, {
                cause: response.statusText,
            });
            // @ts-ignore
            error.data = response._data;
            throw error;
        },
    });
};
