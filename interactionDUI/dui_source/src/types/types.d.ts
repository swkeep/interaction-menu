export type FocusTrackerT = 'indicator' | 'menu';
export interface FocusTracker {
    indicator: boolean;
    menu: boolean;
}

export interface Indicator {
    glow?: boolean;
    underline?: boolean;
    prompt?: string;
    hold?: number;
}

export interface OptionsStyle {
    color: {
        background: string;
        label: string;
        labelSelected: string;
        backgroundSelected: string;
    };
    text: {
        labelFontSize: string;
    };
}

interface VideoData {
    url: string;
    currentTime?: number;
    autoplay?: boolean;
    loop?: boolean;
    progress?: boolean;
    percent?: boolean;
    timecycle?: boolean;
    volume?: number;
    opacity?: number;
}

export interface AudioData {
    url: string;
    currentTime?: number;
    autoplay?: boolean;
    loop?: boolean;
    volume?: number;
    progress?: boolean;
    percent?: boolean;
    timecycle?: boolean;
}

type BorderType = 'dash' | 'solid' | 'double' | 'none' | null | undefined;

declare enum TransitionType {
    LEFT = 'slide-left',
    UP = 'slide-up',
    RIGHT = 'slide-right',
    DOWN = 'slide-down',
}

export interface Filters {
    brightness?: number; // percentage 0-100
    contrast?: number; // percentage 0-100
    saturation?: number; // percentage 0-100
    hue?: number; // degrees
    blur?: number; // pixels
    grayscale?: number; // percentage 0-100
    sepia?: number; // percentage 0-100
    invert?: number; // percentage 0-100
}

interface Picture {
    url: string;
    interval?: number;
    filters?: Filters;
    transition?: TransitionType;
    opacity?: number;
    width?: number;
    height?: number;
    border?: BorderType;
}

interface Progress {
    type: string;
    value?: number;
    percent?: boolean;
}

interface OptionFlags {
    action?: boolean;
    event?: boolean;
    update?: boolean;
    disable: boolean;
    dynamic?: boolean;
    hide: boolean;
    deleted?: boolean;
    canInteract: boolean;
    subMenu: boolean;
}

interface OptionBadge {
    type?: string;
    label: string;
}

export interface Option {
    badge: OptionBadge;
    id: string | number;
    vid: string | number;
    label: string;
    description: string;
    icon: string;
    video?: VideoData;
    audio?: AudioData;
    picture?: Picture;
    style?: OptionsStyle;
    progress?: Progress;
    flags: OptionFlags;
    checked?: boolean;
}

export interface Menu {
    id: string | number;
    metadata: { [key: string]: string };
    options: { [key: string]: Option };
    selected: Array<boolean>;
    flags: OptionFlags;
}

export interface InteractionMenu {
    id: string | number;
    indicator?: Indicator;
    loading?: boolean;
    menus: Menu[];
    selected: Array<boolean>;
    theme: string;
    glow: boolean;
    width: number | string;
}

export interface MenuOption {
    id: number;
    content: string;
}
