export const menuMockData = [
    {
        selected: 1,
        theme: 'nopixel',
        indicator: {
            prompt: 'Enter',
            glow: true,
            active: true,
        },
        menus: [
            {
                id: 'test',
                flags: {
                    hide: false,
                },
                options: [
                    {
                        vid: 1,
                        label: 'Sand',
                        flags: {
                            action: true,
                            hide: false,
                        },
                    },
                    {
                        vid: 2,
                        label: 'State: Locked',
                        flags: {
                            update: true,
                            hide: false,
                        },
                    },
                ],
            },
        ],
    },
    {
        selected: 1,
        theme: 'default',
        menus: [
            {
                id: 'test',
                flags: {
                    hide: false,
                },
                options: [
                    {
                        vid: 1,
                        label: 'Center No Action',
                        flags: {
                            hide: false,
                        },
                    },
                    {
                        vid: 2,
                        label: 'Sand',
                        flags: {
                            action: true,
                            hide: false,
                        },
                    },
                    {
                        vid: 3,
                        label: 'State: Locked',
                        flags: {
                            update: true,
                            hide: false,
                        },
                    },
                    {
                        vid: 4,
                        audio: {
                            url: 'http://127.0.0.1:8080/Seven-Pounds-Energy-Complextro.mp3',
                            volume: 1.0,
                            progress: true,
                            // percent: true,
                            // loop: true,
                            timecycle: true,
                        },
                        flags: {
                            update: true,
                            hide: false,
                        },
                    },
                ],
            },
        ],
    },

    {
        selected: 1,
        theme: 'default',
        menus: [
            {
                id: 'test2',
                flags: {
                    hide: false,
                },
                options: [
                    {
                        vid: 1,
                        picture: {
                            // transition: 'slide-up',
                            height: '20em',
                            url: ['http://127.0.0.1:8080/warframe1.jpg', 'http://127.0.0.1:8080/warframe2.jpg'],
                        },
                        flags: {
                            hide: false,
                        },
                    },
                    {
                        vid: 2,
                        picture: {
                            filters: {
                                brightness: 100,
                            },
                            url: 'http://127.0.0.1:8080/00235-990749447.png',
                        },
                        flags: {
                            hide: false,
                        },
                    },
                    {
                        vid: 3,
                        label: 'Test Title',
                        description: 'Test Subtitle',
                        video: {
                            url: 'http://127.0.0.1:8080/Nevermore.mp4',
                            volume: 0.0,
                            progress: true,
                            // percent: true,
                            // loop: true,
                            timecycle: true,
                        },
                        flags: {
                            hide: false,
                        },
                    },
                    {
                        vid: 4,
                        label: 'Progress',
                        progress: {
                            type: 'info',
                            percent: true,
                            value: 69,
                        },
                        flags: {
                            hide: false,
                        },
                    },
                ],
            },
        ],
    },

    {
        selected: 1,
        theme: 'default',
        indicator: {
            prompt: 'Sound',
            glow: true,
            active: true,
        },
        menus: [
            {
                id: 'test',
                flags: {
                    hide: false,
                },
                options: [
                    {
                        vid: 1,
                        label: 'Center No Action',
                        flags: {
                            hide: false,
                        },
                        icon: 'fas fa-align-center',
                    },
                    {
                        vid: 2,
                        label: 'Sand',
                        flags: {
                            action: true,
                            hide: false,
                        },
                        icon: 'fas fa-umbrella-beach',
                    },
                    {
                        vid: 3,
                        label: 'State: Locked',
                        flags: {
                            update: true,
                            hide: false,
                        },
                        icon: 'fas fa-lock',
                    },
                ],
            },
        ],
    },
];
