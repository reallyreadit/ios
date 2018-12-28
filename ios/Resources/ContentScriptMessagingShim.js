const messagingContext = new WebViewMessagingContext();
window.chrome = {
    runtime: {
        onMessage: {
            addListener: function (listener) {
                messagingContext.addListener(listener);
            }
        },
        sendMessage: function (message, responseCallback) {
            messagingContext.sendMessage(message, responseCallback);
        }
    }
};
