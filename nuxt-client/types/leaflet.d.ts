import 'leaflet';

declare module 'leaflet' {
    interface LayerOptions {
        itemId?: string;
    }
}
