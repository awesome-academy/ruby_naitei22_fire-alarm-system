import type { $Fetch } from 'ofetch';

export default ($fetch: $Fetch) => ({
    getStats() {
        return $fetch<{ averageTemperature: number | null }>('/logs/stats');
    },
    getChartData(sensorIds: string) {
        return $fetch<
            Record<
                string,
                { timestamp: string | Date; temperature: number | null; humidity: number | null }[]
            >
        >('/logs/chart', {
            params: { sensorIds },
        });
    },
});
