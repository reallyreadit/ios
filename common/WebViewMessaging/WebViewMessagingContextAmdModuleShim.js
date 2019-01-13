function define(args, factory) {
    const exports = {};
    factory(null, exports);
    window.WebViewMessagingContext = exports.default;
}
define.amd = true;
