(function (factory) {
    if (typeof module === "object" && typeof module.exports === "object") {
        var v = factory(require, exports);
        if (v !== undefined) module.exports = v;
    }
    else if (typeof define === "function" && define.amd) {
        define(["require", "exports"], factory);
    }
})(function (require, exports) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    var default_1 = /** @class */ (function () {
        function default_1() {
            var _this = this;
            this._onMessageListeners = [];
            this._responseCallbacks = [];
            window.reallyreadit = {
                sendResponse: function (jsonCallbackResponse) {
                    var callbackResponse = JSON.parse(jsonCallbackResponse);
                    _this._responseCallbacks
                        .splice(_this._responseCallbacks.findIndex(function (callback) { return callback.id === callbackResponse.id; }), 1)[0]
                        .function(callbackResponse.data);
                },
                postMessage: function (jsonMessage) {
                    var message = JSON.parse(jsonMessage);
                    var sendResponse;
                    if (message.callbackId != null) {
                        sendResponse = function (response) {
                            _this.postMessage({
                                id: message.callbackId,
                                data: response
                            });
                        };
                    }
                    else {
                        sendResponse = function () { };
                    }
                    _this._onMessageListeners.forEach(function (listener) {
                        listener(message.data, null, sendResponse);
                    });
                }
            };
        }
        default_1.prototype.postMessage = function (message) {
            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.reallyreadit) {
                window.webkit.messageHandlers.reallyreadit.postMessage(message);
            }
            else {
                window.postMessage('reallyreadit:' + JSON.stringify(message), '*');
            }
        };
        default_1.prototype.addListener = function (listener) {
            this._onMessageListeners.push(listener);
        };
        default_1.prototype.sendMessage = function (message, responseCallback) {
            var callbackId = null;
            if (responseCallback) {
                this._responseCallbacks.push({
                    id: callbackId = this._responseCallbacks.length ?
                        Math.max.apply(Math, this._responseCallbacks.map(function (callback) { return callback.id; })) + 1 :
                        0,
                    function: responseCallback
                });
            }
            this.postMessage({ data: message, callbackId: callbackId });
        };
        return default_1;
    }());
    exports.default = default_1;
});
