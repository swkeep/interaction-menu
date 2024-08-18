import { onMounted, onBeforeUnmount } from 'vue';
import { Option } from '../types/types';

interface EventData {
    action: string;
    data: any;
}

type EventHandler = (data: any) => void;

const subscribe = (action: string, handler: EventHandler): void => {
    const eventListener = (event: MessageEvent): void => {
        const { action: eventAction, data } = event.data as EventData;

        if (handler && eventAction === action) handler(data);
    };

    onMounted(() => window.addEventListener('message', eventListener));
    onBeforeUnmount(() => window.removeEventListener('message', eventListener));
};

interface DebugEvent {
    action: string;
    data: any;
}

const debug = (events: DebugEvent[], timer = 1000): void => {
    if (process.env.NODE_ENV !== 'development') return;

    events.forEach((event, index) => {
        setTimeout(
            () => {
                const eventData: EventData = {
                    action: event.action,
                    data: event.data,
                };

                const customEvent = new MessageEvent('message', {
                    data: eventData,
                });

                window.dispatchEvent(customEvent);
            },
            timer * (index + 1),
        );
    });
};

const dev_run = (handler: () => void): void => {
    if (process.env.NODE_ENV !== 'development') return;
    handler();
};

const itemStyle = (item: Option) => {
    const { checked, style } = item;
    const background = checked
        ? style?.color?.backgroundSelected || style?.color?.background
        : style?.color?.background;
    const labelColor = style?.color?.label;
    const labelFontSize = style?.text?.labelFontSize;

    return {
        backgroundColor: background,
        color: labelColor,
        fontSize: labelFontSize,
    };
};

const pad = (num: number) => String(Math.floor(num)).padStart(2, '0');
const formatTime = (seconds: number) => {
    return `${pad(seconds / 3600)}:${pad((seconds / 60) % 60)}:${pad(seconds % 60)}`;
};

export { itemStyle, subscribe, debug, dev_run, formatTime };
