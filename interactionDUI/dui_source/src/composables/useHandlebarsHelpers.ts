import Handlebars from 'handlebars';

export function useHandlebarsHelpers() {
    Handlebars.registerHelper('switch', function (this: any, value: any, options: any) {
        this.switch_value = value;
        this.switch_break = false;
        return options.fn(this);
    });
    Handlebars.registerHelper('case', function (this: any, value: any, options: any) {
        if (value == this.switch_value) {
            this.switch_break = true;
            return options.fn(this);
        }
    });
    Handlebars.registerHelper('default', function (this: any, value: any, options: any) {
        if (this.switch_break === false) {
            return typeof options === 'object' ? options.fn(this) : value;
        }
    });
    Handlebars.registerHelper('times', function (n: number, options: any) {
        let out = '';
        for (let i = 0; i < n; i++) {
            out += options.fn({ i, index: i + 1, isEven: i % 2 === 0, isOdd: i % 2 === 1 });
        }
        return out;
    });

    Handlebars.registerHelper('ifEven', (n: number, options: any) =>
        n % 2 === 0 ? options.fn(this) : options.inverse(this)
    );
    Handlebars.registerHelper('ifOdd', (n: number, options: any) =>
        n % 2 === 1 ? options.fn(this) : options.inverse(this)
    );
    Handlebars.registerHelper('eq', (a, b) => a === b);
    Handlebars.registerHelper('neq', (a, b) => a !== b);
    Handlebars.registerHelper('gt', (a, b) => a > b);
    Handlebars.registerHelper('gte', (a, b) => a >= b);
    Handlebars.registerHelper('lt', (a, b) => a < b);
    Handlebars.registerHelper('lte', (a, b) => a <= b);
    Handlebars.registerHelper('and', (...args) => args.slice(0, -1).every(Boolean));
    Handlebars.registerHelper('or', (...args) => args.slice(0, -1).some(Boolean));
    Handlebars.registerHelper('not', (v) => !v);
    Handlebars.registerHelper('safeHTML', (str: string) => new Handlebars.SafeString(str ?? ''));
    Handlebars.registerHelper('add', (a: number, b: number) => a + b);
    Handlebars.registerHelper('subtract', (a: number, b: number) => a - b);
    Handlebars.registerHelper('multiply', (a: number, b: number) => a * b);
    Handlebars.registerHelper('divide', (a: number, b: number) => (b !== 0 ? a / b : null));
    Handlebars.registerHelper('mod', (a: number, b: number) => (b !== 0 ? a % b : null));
    Handlebars.registerHelper('toFixed', (n: number, digits: number) =>
        Number(n).toFixed(digits)
    );
    Handlebars.registerHelper('currency', (n: number, locale = 'en-US', currency = 'USD') =>
        new Intl.NumberFormat(locale, { style: 'currency', currency }).format(Number(n))
    );
    Handlebars.registerHelper('filesize', (bytes: number) => {
        if (bytes === 0) return '0 B';
        const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
        const i = Math.floor(Math.log(bytes) / Math.log(1024));
        return (bytes / Math.pow(1024, i)).toFixed(1) + ' ' + sizes[i];
    });
    Handlebars.registerHelper('length', (arr: any) =>
        arr && arr.length !== undefined ? arr.length : 0
    );
    Handlebars.registerHelper('now', () => new Date().toISOString());
    Handlebars.registerHelper('timestamp', () => Math.floor(Date.now() / 1000));
    Handlebars.registerHelper('timeago', (date: string | Date) => {
        const diff = Date.now() - new Date(date).getTime();
        const sec = Math.floor(diff / 1000);
        if (sec < 60) return `${sec}s ago`;
        const min = Math.floor(sec / 60);
        if (min < 60) return `${min}m ago`;
        const hr = Math.floor(min / 60);
        if (hr < 24) return `${hr}h ago`;
        const day = Math.floor(hr / 24);
        return `${day}d ago`;
    });

    return Handlebars;
}
