import type { Api } from '~/plugins/api';

export const useApi = (): Api => {
    const { $api } = useNuxtApp();
    return $api;
};
