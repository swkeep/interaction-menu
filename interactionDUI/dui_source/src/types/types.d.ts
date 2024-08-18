export interface FocusTracker {
    indicator: boolean;
    menu: boolean;
}

export interface Indicator {
    glow?: boolean;
    underline?: boolean;
    active?: boolean;
    prompt?: string;
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

interface Video {
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

type BorderType = 'dash' | 'solid' | 'double' | 'none' | null | undefined;

interface Picture {
    url: string;
    interval?: number;
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
}

export interface Option {
    id: string | number;
    vid: string | number;
    label: string;
    description: string;
    icon: string;
    video?: Video;
    picture?: Picture;
    style?: OptionsStyle;
    progress?: Progress;
    flags: OptionFlags;
}

export interface Menu {
    id: string | number;
    options: Option[];
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
}

export interface MenuOption {
    id: number;
    content: string;
}
