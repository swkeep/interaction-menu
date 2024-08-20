// shims-vue.d.ts
declare module '*.vue' {
    import { DefineComponent } from 'vue';

    const component: DefineComponent<object, object, unknown>;
    export default component;
}
