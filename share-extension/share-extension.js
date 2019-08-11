/******/ (function(modules) { // webpackBootstrap
/******/ 	// The module cache
/******/ 	var installedModules = {};
/******/
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/
/******/ 		// Check if module is in cache
/******/ 		if(installedModules[moduleId]) {
/******/ 			return installedModules[moduleId].exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = installedModules[moduleId] = {
/******/ 			i: moduleId,
/******/ 			l: false,
/******/ 			exports: {}
/******/ 		};
/******/
/******/ 		// Execute the module function
/******/ 		modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/
/******/ 		// Flag the module as loaded
/******/ 		module.l = true;
/******/
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/
/******/
/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__webpack_require__.m = modules;
/******/
/******/ 	// expose the module cache
/******/ 	__webpack_require__.c = installedModules;
/******/
/******/ 	// define getter function for harmony exports
/******/ 	__webpack_require__.d = function(exports, name, getter) {
/******/ 		if(!__webpack_require__.o(exports, name)) {
/******/ 			Object.defineProperty(exports, name, { enumerable: true, get: getter });
/******/ 		}
/******/ 	};
/******/
/******/ 	// define __esModule on exports
/******/ 	__webpack_require__.r = function(exports) {
/******/ 		if(typeof Symbol !== 'undefined' && Symbol.toStringTag) {
/******/ 			Object.defineProperty(exports, Symbol.toStringTag, { value: 'Module' });
/******/ 		}
/******/ 		Object.defineProperty(exports, '__esModule', { value: true });
/******/ 	};
/******/
/******/ 	// create a fake namespace object
/******/ 	// mode & 1: value is a module id, require it
/******/ 	// mode & 2: merge all properties of value into the ns
/******/ 	// mode & 4: return value when already ns object
/******/ 	// mode & 8|1: behave like require
/******/ 	__webpack_require__.t = function(value, mode) {
/******/ 		if(mode & 1) value = __webpack_require__(value);
/******/ 		if(mode & 8) return value;
/******/ 		if((mode & 4) && typeof value === 'object' && value && value.__esModule) return value;
/******/ 		var ns = Object.create(null);
/******/ 		__webpack_require__.r(ns);
/******/ 		Object.defineProperty(ns, 'default', { enumerable: true, value: value });
/******/ 		if(mode & 2 && typeof value != 'string') for(var key in value) __webpack_require__.d(ns, key, function(key) { return value[key]; }.bind(null, key));
/******/ 		return ns;
/******/ 	};
/******/
/******/ 	// getDefaultExport function for compatibility with non-harmony modules
/******/ 	__webpack_require__.n = function(module) {
/******/ 		var getter = module && module.__esModule ?
/******/ 			function getDefault() { return module['default']; } :
/******/ 			function getModuleExports() { return module; };
/******/ 		__webpack_require__.d(getter, 'a', getter);
/******/ 		return getter;
/******/ 	};
/******/
/******/ 	// Object.prototype.hasOwnProperty.call
/******/ 	__webpack_require__.o = function(object, property) { return Object.prototype.hasOwnProperty.call(object, property); };
/******/
/******/ 	// __webpack_public_path__
/******/ 	__webpack_require__.p = "";
/******/
/******/
/******/ 	// Load entry module and return exports
/******/ 	return __webpack_require__(__webpack_require__.s = "./src/native-client/share-extension/main.ts");
/******/ })
/************************************************************************/
/******/ ({

/***/ "./src/common/MessagingContext.ts":
/*!****************************************!*\
  !*** ./src/common/MessagingContext.ts ***!
  \****************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

var __read = (this && this.__read) || function (o, n) {
    var m = typeof Symbol === "function" && o[Symbol.iterator];
    if (!m) return o;
    var i = m.call(o), r, ar = [], e;
    try {
        while ((n === void 0 || n-- > 0) && !(r = i.next()).done) ar.push(r.value);
    }
    catch (error) { e = { error: error }; }
    finally {
        try {
            if (r && !r.done && (m = i["return"])) m.call(i);
        }
        finally { if (e) throw e.error; }
    }
    return ar;
};
var __spread = (this && this.__spread) || function () {
    for (var ar = [], i = 0; i < arguments.length; i++) ar = ar.concat(__read(arguments[i]));
    return ar;
};
Object.defineProperty(exports, "__esModule", { value: true });
var MessagingContext = /** @class */ (function () {
    function MessagingContext() {
        this._onMessageListeners = [];
        this._responseCallbacks = [];
    }
    MessagingContext.prototype.isResponseEnvelope = function (envelope) {
        return envelope.id != null;
    };
    MessagingContext.prototype.processMessage = function (envelope) {
        var _this = this;
        if (this.isResponseEnvelope(envelope)) {
            this._responseCallbacks
                .splice(this._responseCallbacks.findIndex(function (callback) { return callback.id === envelope.id; }), 1)[0]
                .function(envelope.data);
        }
        else {
            var sendResponse_1;
            if (envelope.callbackId != null) {
                sendResponse_1 = function (response) {
                    _this.postMessage({
                        id: envelope.callbackId,
                        data: response
                    });
                };
            }
            else {
                sendResponse_1 = function () { };
            }
            this._onMessageListeners.forEach(function (listener) {
                listener(envelope.data, sendResponse_1);
            });
        }
    };
    MessagingContext.prototype.addListener = function (listener) {
        this._onMessageListeners.push(listener);
    };
    MessagingContext.prototype.sendMessage = function (message, responseCallback) {
        var callbackId = null;
        if (responseCallback) {
            this._responseCallbacks.push({
                id: callbackId = this._responseCallbacks.length ?
                    Math.max.apply(Math, __spread(this._responseCallbacks.map(function (callback) { return callback.id; }))) + 1 :
                    0,
                function: responseCallback
            });
        }
        this.postMessage({ data: message, callbackId: callbackId });
    };
    return MessagingContext;
}());
exports.default = MessagingContext;


/***/ }),

/***/ "./src/common/WebViewMessagingContext.ts":
/*!***********************************************!*\
  !*** ./src/common/WebViewMessagingContext.ts ***!
  \***********************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p]; };
        return extendStatics(d, b);
    }
    return function (d, b) {
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
var MessagingContext_1 = __webpack_require__(/*! ./MessagingContext */ "./src/common/MessagingContext.ts");
var WebViewMessagingContext = /** @class */ (function (_super) {
    __extends(WebViewMessagingContext, _super);
    function WebViewMessagingContext() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    WebViewMessagingContext.prototype.postMessage = function (envelope) {
        if (window.webkit) {
            window.webkit.messageHandlers.reallyreadit.postMessage(envelope);
        }
    };
    WebViewMessagingContext.prototype.createIncomingMessageHandlers = function () {
        var _this = this;
        var processMessage = function (jsonMessage) {
            _this.processMessage(JSON.parse(jsonMessage));
        };
        return {
            postMessage: function (jsonMessage) {
                processMessage(jsonMessage);
            },
            sendResponse: function (jsonCallbackResponse) {
                processMessage(jsonCallbackResponse);
            }
        };
    };
    return WebViewMessagingContext;
}(MessagingContext_1.default));
exports.default = WebViewMessagingContext;


/***/ }),

/***/ "./src/common/contentParsing/ContentContainer.ts":
/*!*******************************************************!*\
  !*** ./src/common/contentParsing/ContentContainer.ts ***!
  \*******************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

Object.defineProperty(exports, "__esModule", { value: true });
var ContentContainer = /** @class */ (function () {
    function ContentContainer(containerLineage, contentLineages) {
        this._containerLineage = [];
        this._contentLineages = [];
        this._containerLineage = containerLineage;
        this._contentLineages = contentLineages;
    }
    Object.defineProperty(ContentContainer.prototype, "containerElement", {
        get: function () {
            return (this._containerLineage.length ?
                this._containerLineage[this._containerLineage.length - 1] :
                null);
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(ContentContainer.prototype, "containerLineage", {
        get: function () {
            return this._containerLineage;
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(ContentContainer.prototype, "contentLineages", {
        get: function () {
            return this._contentLineages;
        },
        enumerable: true,
        configurable: true
    });
    return ContentContainer;
}());
exports.default = ContentContainer;


/***/ }),

/***/ "./src/common/contentParsing/GraphEdge.ts":
/*!************************************************!*\
  !*** ./src/common/contentParsing/GraphEdge.ts ***!
  \************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

Object.defineProperty(exports, "__esModule", { value: true });
var GraphEdge;
(function (GraphEdge) {
    GraphEdge[GraphEdge["None"] = 0] = "None";
    GraphEdge[GraphEdge["Left"] = 1] = "Left";
    GraphEdge[GraphEdge["Right"] = 2] = "Right";
})(GraphEdge || (GraphEdge = {}));
exports.default = GraphEdge;


/***/ }),

/***/ "./src/common/contentParsing/ImageContainer.ts":
/*!*****************************************************!*\
  !*** ./src/common/contentParsing/ImageContainer.ts ***!
  \*****************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p]; };
        return extendStatics(d, b);
    }
    return function (d, b) {
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
var ContentContainer_1 = __webpack_require__(/*! ./ContentContainer */ "./src/common/contentParsing/ContentContainer.ts");
var ImageContainer = /** @class */ (function (_super) {
    __extends(ImageContainer, _super);
    function ImageContainer(containerLineage, contentLineages, caption, credit) {
        var _this = _super.call(this, containerLineage, contentLineages) || this;
        _this._caption = caption;
        _this._credit = credit;
        return _this;
    }
    Object.defineProperty(ImageContainer.prototype, "caption", {
        get: function () {
            return this._caption;
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(ImageContainer.prototype, "credit", {
        get: function () {
            return this._credit;
        },
        enumerable: true,
        configurable: true
    });
    return ImageContainer;
}(ContentContainer_1.default));
exports.default = ImageContainer;


/***/ }),

/***/ "./src/common/contentParsing/TextContainer.ts":
/*!****************************************************!*\
  !*** ./src/common/contentParsing/TextContainer.ts ***!
  \****************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p]; };
        return extendStatics(d, b);
    }
    return function (d, b) {
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
var __read = (this && this.__read) || function (o, n) {
    var m = typeof Symbol === "function" && o[Symbol.iterator];
    if (!m) return o;
    var i = m.call(o), r, ar = [], e;
    try {
        while ((n === void 0 || n-- > 0) && !(r = i.next()).done) ar.push(r.value);
    }
    catch (error) { e = { error: error }; }
    finally {
        try {
            if (r && !r.done && (m = i["return"])) m.call(i);
        }
        finally { if (e) throw e.error; }
    }
    return ar;
};
var __spread = (this && this.__spread) || function () {
    for (var ar = [], i = 0; i < arguments.length; i++) ar = ar.concat(__read(arguments[i]));
    return ar;
};
Object.defineProperty(exports, "__esModule", { value: true });
var ContentContainer_1 = __webpack_require__(/*! ./ContentContainer */ "./src/common/contentParsing/ContentContainer.ts");
var TextContainer = /** @class */ (function (_super) {
    __extends(TextContainer, _super);
    function TextContainer(containerLineage, contentLineages, wordcount) {
        var _this = _super.call(this, containerLineage, contentLineages) || this;
        _this._wordCount = wordcount;
        return _this;
    }
    TextContainer.prototype.mergeContent = function (container) {
        var _a;
        (_a = this._contentLineages).push.apply(_a, __spread(container._contentLineages));
        this._wordCount += container.wordCount;
    };
    Object.defineProperty(TextContainer.prototype, "wordCount", {
        get: function () {
            return this._wordCount;
        },
        enumerable: true,
        configurable: true
    });
    return TextContainer;
}(ContentContainer_1.default));
exports.default = TextContainer;


/***/ }),

/***/ "./src/common/contentParsing/TextContainerDepthGroup.ts":
/*!**************************************************************!*\
  !*** ./src/common/contentParsing/TextContainerDepthGroup.ts ***!
  \**************************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

Object.defineProperty(exports, "__esModule", { value: true });
var TextContainerDepthGroup = /** @class */ (function () {
    function TextContainerDepthGroup(depth) {
        var members = [];
        for (var _i = 1; _i < arguments.length; _i++) {
            members[_i - 1] = arguments[_i];
        }
        this._wordCount = 0;
        this._depth = depth;
        this._members = members;
        this._wordCount = members.reduce(function (sum, member) { return sum += member.wordCount; }, 0);
    }
    TextContainerDepthGroup.prototype.add = function (container) {
        // look for an existing member
        var member = this._members.find(function (member) { return member.containerElement === container.containerElement; });
        if (member) {
            // merge content
            member.mergeContent(container);
        }
        else {
            // add a new member
            this._members.push(container);
        }
        // incrememnt the group word count
        this._wordCount += container.wordCount;
    };
    Object.defineProperty(TextContainerDepthGroup.prototype, "depth", {
        get: function () {
            return this._depth;
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(TextContainerDepthGroup.prototype, "members", {
        get: function () {
            return this._members;
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(TextContainerDepthGroup.prototype, "wordCount", {
        get: function () {
            return this._wordCount;
        },
        enumerable: true,
        configurable: true
    });
    return TextContainerDepthGroup;
}());
exports.default = TextContainerDepthGroup;


/***/ }),

/***/ "./src/common/contentParsing/TraversalPath.ts":
/*!****************************************************!*\
  !*** ./src/common/contentParsing/TraversalPath.ts ***!
  \****************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

Object.defineProperty(exports, "__esModule", { value: true });
var TraversalPath = /** @class */ (function () {
    function TraversalPath(_a) {
        var hops = _a.hops, frequency = _a.frequency, wordCount = _a.wordCount;
        this._hops = hops;
        this._frequency = frequency;
        this._wordCount = wordCount;
    }
    TraversalPath.prototype.add = function (_a) {
        var frequency = _a.frequency, wordCount = _a.wordCount;
        return new TraversalPath({
            hops: this._hops,
            frequency: this._frequency + frequency,
            wordCount: this._wordCount + wordCount
        });
    };
    Object.defineProperty(TraversalPath.prototype, "frequency", {
        get: function () {
            return this._frequency;
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(TraversalPath.prototype, "hops", {
        get: function () {
            return this._hops;
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(TraversalPath.prototype, "wordCount", {
        get: function () {
            return this._wordCount;
        },
        enumerable: true,
        configurable: true
    });
    return TraversalPath;
}());
exports.default = TraversalPath;


/***/ }),

/***/ "./src/common/contentParsing/TraversalPathSearchResult.ts":
/*!****************************************************************!*\
  !*** ./src/common/contentParsing/TraversalPathSearchResult.ts ***!
  \****************************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

Object.defineProperty(exports, "__esModule", { value: true });
var TraversalPathSearchResult = /** @class */ (function () {
    function TraversalPathSearchResult(textContainer, paths) {
        this._textContainer = textContainer;
        this._paths = paths;
    }
    TraversalPathSearchResult.prototype.getPreferredPath = function () {
        if (!this._preferredPath) {
            this._preferredPath = this._paths.sort(function (a, b) { return (a.wordCount !== b.wordCount ?
                b.wordCount - a.wordCount :
                a.hops - b.hops); })[0];
        }
        return this._preferredPath;
    };
    Object.defineProperty(TraversalPathSearchResult.prototype, "textContainer", {
        get: function () {
            return this._textContainer;
        },
        enumerable: true,
        configurable: true
    });
    return TraversalPathSearchResult;
}());
exports.default = TraversalPathSearchResult;


/***/ }),

/***/ "./src/common/contentParsing/configuration/Config.ts":
/*!***********************************************************!*\
  !*** ./src/common/contentParsing/configuration/Config.ts ***!
  \***********************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

var __assign = (this && this.__assign) || function () {
    __assign = Object.assign || function(t) {
        for (var s, i = 1, n = arguments.length; i < n; i++) {
            s = arguments[i];
            for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p))
                t[p] = s[p];
        }
        return t;
    };
    return __assign.apply(this, arguments);
};
Object.defineProperty(exports, "__esModule", { value: true });
var utils_1 = __webpack_require__(/*! ../utils */ "./src/common/contentParsing/utils.ts");
var Config = /** @class */ (function () {
    function Config(universal, publisher, contentSearchRootElement) {
        this._textContainerContent = universal.textContainerContent;
        this._imageContainerMetadata = universal.imageContainerMetadata;
        this._imageContainerContent = universal.imageContainerContent;
        this._textContainerSelection = universal.textContainerSelection;
        this._wordCountTraversalPathSearchLimitMultiplier = universal.wordCountTraversalPathSearchLimitMultiplier;
        if (publisher) {
            if (publisher.textContainerSearch) {
                this._textContainerSearch = __assign({}, universal.textContainerSearch, { attributeFullWordBlacklist: universal.textContainerSearch.attributeFullWordBlacklist.concat(publisher.textContainerSearch.attributeBlacklist || []), attributeFullWordWhitelist: publisher.textContainerSearch.attributeWhitelist || [] });
            }
            else {
                this._textContainerSearch = __assign({}, universal.textContainerSearch, { attributeFullWordWhitelist: [] });
            }
            if (publisher.imageContainerSearch) {
                this._imageContainerSearch = __assign({}, universal.imageContainerSearch, { attributeFullWordBlacklist: universal.imageContainerSearch.attributeFullWordBlacklist.concat(publisher.imageContainerSearch.attributeBlacklist || []), attributeFullWordWhitelist: publisher.imageContainerSearch.attributeWhitelist || [] });
            }
            else {
                this._imageContainerSearch = __assign({}, universal.imageContainerSearch, { attributeFullWordWhitelist: [] });
            }
            this._contentSearchRootElementSelector = publisher.contentSearchRootElementSelector;
            if (publisher.transpositions) {
                this._transpositions = publisher.transpositions
                    .map(function (rule) {
                    var parentElement = document.querySelector(rule.parentElementSelector), elements = rule.elementSelectors.reduce(function (elements, selector) { return elements.concat(Array.from(document.querySelectorAll(selector))); }, []);
                    if (parentElement && elements.length) {
                        return {
                            elements: elements,
                            lineage: utils_1.buildLineage({
                                ancestor: contentSearchRootElement,
                                descendant: parentElement
                            })
                        };
                    }
                    else {
                        return null;
                    }
                })
                    .filter(function (rule) { return !!rule; });
            }
            else {
                this._transpositions = [];
            }
        }
        else {
            this._textContainerSearch = __assign({}, universal.textContainerSearch, { attributeFullWordWhitelist: [] });
            this._imageContainerSearch = __assign({}, universal.imageContainerSearch, { attributeFullWordWhitelist: [] });
            this._transpositions = [];
        }
    }
    Object.defineProperty(Config.prototype, "textContainerSearch", {
        get: function () {
            return this._textContainerSearch;
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(Config.prototype, "textContainerContent", {
        get: function () {
            return this._textContainerContent;
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(Config.prototype, "imageContainerSearch", {
        get: function () {
            return this._imageContainerSearch;
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(Config.prototype, "imageContainerMetadata", {
        get: function () {
            return this._imageContainerMetadata;
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(Config.prototype, "imageContainerContent", {
        get: function () {
            return this._imageContainerContent;
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(Config.prototype, "textContainerSelection", {
        get: function () {
            return this._textContainerSelection;
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(Config.prototype, "contentSearchRootElementSelector", {
        get: function () {
            return this._contentSearchRootElementSelector;
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(Config.prototype, "transpositions", {
        get: function () {
            return this._transpositions;
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(Config.prototype, "wordCountTraversalPathSearchLimitMultiplier", {
        get: function () {
            return this._wordCountTraversalPathSearchLimitMultiplier;
        },
        enumerable: true,
        configurable: true
    });
    return Config;
}());
exports.default = Config;


/***/ }),

/***/ "./src/common/contentParsing/configuration/configs.ts":
/*!************************************************************!*\
  !*** ./src/common/contentParsing/configuration/configs.ts ***!
  \************************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

Object.defineProperty(exports, "__esModule", { value: true });
exports.default = {
    universal: {
        textContainerSearch: {
            nodeNameBlacklist: ['BUTTON', 'FIGURE', 'FORM', 'HEAD', 'IFRAME', 'NAV', 'NOSCRIPT', 'PICTURE', 'SCRIPT', 'STYLE'],
            attributeFullWordBlacklist: ['ad', 'carousel', 'gallery', 'related', 'share', 'subscribe', 'subscription'],
            attributeWordPartBlacklist: ['byline', 'caption', 'comment', 'download', 'interlude', 'image', 'meta', 'newsletter', 'photo', 'promo', 'pullquote', 'recirc', 'video'],
            itempropValueBlacklist: ['author', 'datePublished'],
            descendantNodeNameBlacklist: ['FORM', 'IFRAME'],
            additionalContentNodeNameBlacklist: ['ASIDE', 'FOOTER', 'HEADER'],
            additionalContentMaxDepthDecrease: 1,
            additionalContentMaxDepthIncrease: 1
        },
        textContainerContent: {
            regexBlacklist: [/^\[[^\]]+\]$/],
            singleSentenceOpenerBlacklist: ['►', 'click here', 'don\'t miss', 'listen to this story', 'read more', 'related article:', 'sign up for', 'sponsored:', 'this article appears in', 'watch:']
        },
        imageContainerSearch: {
            nodeNameBlacklist: ['FORM', 'HEAD', 'IFRAME', 'NAV', 'NOSCRIPT', 'SCRIPT', 'STYLE'],
            attributeFullWordBlacklist: ['ad', 'related', 'share', 'subscribe', 'subscription'],
            attributeWordPartBlacklist: ['interlude', 'newsletter', 'promo', 'recirc', 'video'],
            itempropValueBlacklist: [],
            descendantNodeNameBlacklist: ['FORM', 'IFRAME']
        },
        imageContainerMetadata: {
            contentRegexBlacklist: [/audm/i],
            contentRegexWhitelist: [],
            captionSelectors: ['figcaption', '[class*="caption"i]'],
            creditSelectors: ['[class*="credit"i]', '[class*="source"i]'],
            imageWrapperAttributeWordParts: ['image', 'img']
        },
        imageContainerContent: {
            nodeNameBlacklist: ['BUTTON'],
            nodeNameWhitelist: ['IMG', 'META', 'PICTURE', 'SOURCE'],
            attributeBlacklist: ['expand', 'icon', 'share']
        },
        textContainerSelection: {
            nodeNameWhitelist: ['ASIDE', 'BLOCKQUOTE', 'DIV', 'H1', 'H2', 'H3', 'H4', 'H5', 'H6', 'OL', 'P', 'PRE', 'TABLE', 'UL'],
            ancestorNodeNameBlacklist: ['BLOCKQUOTE', 'LI', 'P']
        },
        wordCountTraversalPathSearchLimitMultiplier: 0.75
    },
    publishers: [
        {
            hostname: 'article-test.dev.readup.com',
            transpositions: [
                {
                    elementSelectors: [
                        '.lead'
                    ],
                    parentElementSelector: '.lead + div'
                }
            ]
        },
        {
            hostname: 'churchofjesuschrist.org',
            transpositions: [
                {
                    elementSelectors: [
                        '.body-block > p',
                        '.body-block > section:first-of-type > header > h2'
                    ],
                    parentElementSelector: '.body-block > section:first-of-type'
                }
            ]
        },
        {
            hostname: 'cnn.com',
            transpositions: [
                {
                    elementSelectors: [
                        '.el__leafmedia--sourced-paragraph > .zn-body__paragraph',
                        '.l-container > .zn-body__paragraph:not(.zn-body__footer)',
                        '.l-container > .zn-body__paragraph > h3'
                    ],
                    parentElementSelector: '.zn-body__read-all'
                }
            ]
        },
        {
            hostname: 'huffpost.com',
            transpositions: [
                {
                    elementSelectors: [
                        '#entry-text [data-rapid-subsec="paragraph"] > :not([data-rapid-subsec="paragraph"])'
                    ],
                    parentElementSelector: '#entry-text'
                }
            ]
        },
        {
            hostname: 'medium.com',
            textContainerSearch: {
                attributeWhitelist: ['ad']
            }
        },
        {
            hostname: 'nytimes.com',
            transpositions: [
                {
                    elementSelectors: [
                        '.story-body-1 > .story-body-text'
                    ],
                    parentElementSelector: '.story-body-2'
                }
            ]
        },
        {
            hostname: 'sciencedaily.com',
            transpositions: [
                {
                    elementSelectors: [
                        'p.lead'
                    ],
                    parentElementSelector: 'div#text'
                }
            ]
        },
        {
            hostname: 'stanfordmag.org',
            textContainerSearch: {
                attributeWhitelist: ['image']
            }
        },
        {
            hostname: 'telegraph.co.uk',
            transpositions: [
                {
                    elementSelectors: [
                        '#mainBodyArea > div[class$="Par"] > *'
                    ],
                    parentElementSelector: '#mainBodyArea > .body'
                }
            ]
        },
        {
            hostname: 'theatlantic.com',
            imageContainerSearch: {
                attributeBlacklist: ['callout']
            }
        },
        {
            hostname: 'topic.com',
            textContainerSearch: {
                attributeWhitelist: ['essay']
            }
        },
        {
            hostname: 'wired.com',
            textContainerSearch: {
                attributeBlacklist: ['inset']
            }
        }
    ]
};


/***/ }),

/***/ "./src/common/contentParsing/figureContent.ts":
/*!****************************************************!*\
  !*** ./src/common/contentParsing/figureContent.ts ***!
  \****************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

var __values = (this && this.__values) || function (o) {
    var m = typeof Symbol === "function" && o[Symbol.iterator], i = 0;
    if (m) return m.call(o);
    return {
        next: function () {
            if (o && i >= o.length) o = void 0;
            return { value: o && o[i++], done: !o };
        }
    };
};
Object.defineProperty(exports, "__esModule", { value: true });
var utils_1 = __webpack_require__(/*! ./utils */ "./src/common/contentParsing/utils.ts");
function getChildNodesTextContent(element) {
    var e_1, _a;
    var text = '';
    try {
        for (var _b = __values(element.childNodes), _c = _b.next(); !_c.done; _c = _b.next()) {
            var child = _c.value;
            if (child.nodeType === Node.TEXT_NODE) {
                text += child.textContent;
            }
        }
    }
    catch (e_1_1) { e_1 = { error: e_1_1 }; }
    finally {
        try {
            if (_c && !_c.done && (_a = _b.return)) _a.call(_b);
        }
        finally { if (e_1) throw e_1.error; }
    }
    return text;
}
function isValidContent(element, config) {
    return (!config.nodeNameBlacklist.some(function (nodeName) { return element.nodeName === nodeName; }) &&
        (config.nodeNameWhitelist.some(function (nodeName) { return element.nodeName === nodeName || !!element.getElementsByTagName(nodeName).length; }) ||
            !getChildNodesTextContent(element).trim()) &&
        !utils_1.findWordsInAttributes(element).some(function (word) { return config.attributeBlacklist.includes(word); }) &&
        (element.nodeName === 'IMG' ?
            utils_1.isValidImgElement(element) :
            true));
}
exports.isValidContent = isValidContent;


/***/ }),

/***/ "./src/common/contentParsing/parseDocumentContent.ts":
/*!***********************************************************!*\
  !*** ./src/common/contentParsing/parseDocumentContent.ts ***!
  \***********************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

var __values = (this && this.__values) || function (o) {
    var m = typeof Symbol === "function" && o[Symbol.iterator], i = 0;
    if (m) return m.call(o);
    return {
        next: function () {
            if (o && i >= o.length) o = void 0;
            return { value: o && o[i++], done: !o };
        }
    };
};
var __read = (this && this.__read) || function (o, n) {
    var m = typeof Symbol === "function" && o[Symbol.iterator];
    if (!m) return o;
    var i = m.call(o), r, ar = [], e;
    try {
        while ((n === void 0 || n-- > 0) && !(r = i.next()).done) ar.push(r.value);
    }
    catch (error) { e = { error: error }; }
    finally {
        try {
            if (r && !r.done && (m = i["return"])) m.call(i);
        }
        finally { if (e) throw e.error; }
    }
    return ar;
};
var __spread = (this && this.__spread) || function () {
    for (var ar = [], i = 0; i < arguments.length; i++) ar = ar.concat(__read(arguments[i]));
    return ar;
};
Object.defineProperty(exports, "__esModule", { value: true });
var TextContainerDepthGroup_1 = __webpack_require__(/*! ./TextContainerDepthGroup */ "./src/common/contentParsing/TextContainerDepthGroup.ts");
var TraversalPathSearchResult_1 = __webpack_require__(/*! ./TraversalPathSearchResult */ "./src/common/contentParsing/TraversalPathSearchResult.ts");
var TraversalPath_1 = __webpack_require__(/*! ./TraversalPath */ "./src/common/contentParsing/TraversalPath.ts");
var ImageContainer_1 = __webpack_require__(/*! ./ImageContainer */ "./src/common/contentParsing/ImageContainer.ts");
var GraphEdge_1 = __webpack_require__(/*! ./GraphEdge */ "./src/common/contentParsing/GraphEdge.ts");
var TextContainer_1 = __webpack_require__(/*! ./TextContainer */ "./src/common/contentParsing/TextContainer.ts");
var utils_1 = __webpack_require__(/*! ./utils */ "./src/common/contentParsing/utils.ts");
var figureContent_1 = __webpack_require__(/*! ./figureContent */ "./src/common/contentParsing/figureContent.ts");
var Config_1 = __webpack_require__(/*! ./configuration/Config */ "./src/common/contentParsing/configuration/Config.ts");
var configs_1 = __webpack_require__(/*! ./configuration/configs */ "./src/common/contentParsing/configuration/configs.ts");
// regular expressions
var wordRegex = /\S+/g;
var singleSentenceRegex = /^[^.!?]+[.!?'"]*$/;
// misc
function findDescendantsMatchingQuerySelectors(element, selectors) {
    return selectors
        .map(function (selector) { return element.querySelectorAll(selector); })
        .reduce(function (elements, element) { return elements.concat(Array.from(element)); }, []);
}
function getWordCount(node) {
    return (node.textContent.match(wordRegex) || []).length;
}
;
function searchUpLineage(lineage, test) {
    for (var i = lineage.length - 1; i >= 0; i--) {
        var ancestor = lineage[i];
        if (test(ancestor, i)) {
            return ancestor;
        }
    }
    return null;
}
// select article search element based on available metadata
function selectContentSearchRootElement(configuredSelector) {
    if (configuredSelector) {
        var configuredRoot = document.querySelector(configuredSelector);
        if (configuredRoot) {
            return configuredRoot;
        }
    }
    var queryRoot = document.body;
    var articleScopes = queryRoot.querySelectorAll('[itemtype="http://schema.org/Article"], [itemtype="http://schema.org/BlogPosting"]');
    if (articleScopes.length) {
        queryRoot = articleScopes[0];
    }
    var articleBodyNodes = queryRoot.querySelectorAll('[itemprop=articleBody]');
    if (articleBodyNodes.length === 1) {
        return articleBodyNodes[0];
    }
    var articleNodes = queryRoot.querySelectorAll('article');
    if (articleNodes.length === 1) {
        return articleNodes[0];
    }
    return queryRoot;
}
// filtering
function isImageContainerMetadataValid(image, config) {
    var meta = (image.caption || '') + ' ' + (image.credit || '');
    return !(config.contentRegexBlacklist.some(function (regex) { return regex.test(meta); }) &&
        !config.contentRegexWhitelist.some(function (regex) { return regex.test(meta); }));
}
function isTextContentValid(block, config) {
    var links = block.getElementsByTagName('a');
    if (!links.length) {
        return true;
    }
    if (links.length === 1 &&
        links[0].textContent === block.textContent &&
        block.textContent.toUpperCase() === block.textContent) {
        return false;
    }
    var trimmedContent = block.textContent.trim();
    if (config.regexBlacklist.some(function (regex) { return regex.test(trimmedContent); })) {
        return false;
    }
    var singleSentenceMatch = trimmedContent.match(singleSentenceRegex);
    if (singleSentenceMatch) {
        var lowercasedContent_1 = trimmedContent.toLowerCase();
        return !config.singleSentenceOpenerBlacklist.some(function (opener) { return lowercasedContent_1.startsWith(opener); });
    }
    return true;
}
function shouldSearchForContent(element, config) {
    if (config.nodeNameBlacklist.includes(element.nodeName)) {
        return false;
    }
    if (config.itempropValueBlacklist.includes(element.getAttribute('itemprop'))) {
        return false;
    }
    var words = utils_1.findWordsInAttributes(element);
    return !(words.some(function (word) { return (config.attributeFullWordBlacklist.includes(word) ||
        config.attributeWordPartBlacklist.some(function (wordPart) { return word.includes(wordPart); })) &&
        !words.some(function (word) { return config.attributeFullWordWhitelist.includes(word); }); }));
}
// find text containers by recursively walking the tree looking for text nodes
var findTextContainers = (function () {
    function findClosestTextContainerElement(lineage, config) {
        return searchUpLineage(lineage, function (ancestor, index) { return (utils_1.isElement(ancestor) &&
            config.nodeNameWhitelist.includes(ancestor.nodeName) &&
            !lineage
                .slice(0, index)
                .some(function (ancestor) { return config.ancestorNodeNameBlacklist.includes(ancestor.nodeName); })); });
    }
    function addTextNode(node, lineage, config, containers) {
        // add text nodes with no words to preserve whitespace in valid containers. filter containers after the
        // entire tree has been processed.
        // find the closest text container element
        var containerElement = findClosestTextContainerElement(lineage, config.textContainerSelection);
        // only process the text node if a text container was found
        if (containerElement &&
            !config.textContainerSearch.descendantNodeNameBlacklist.some(function (nodeName) { return !!containerElement.getElementsByTagName(nodeName).length; })) {
            // capture lineage
            var containerLineage = void 0;
            var transpositionRule = (config ?
                config.transpositions.find(function (rule) { return rule.elements.some(function (element) { return element === containerElement; }); }) :
                null);
            if (transpositionRule) {
                containerLineage = transpositionRule.lineage.concat(containerElement);
            }
            else {
                containerLineage = lineage.slice(0, lineage.indexOf(containerElement) + 1);
            }
            // create the text container and add to container array or merge with existing container
            var textContainer = new TextContainer_1.default(containerLineage, [lineage.concat(node)], getWordCount(node)), existingContainer = containers.find(function (container) { return container.containerElement === containerElement; });
            if (existingContainer) {
                existingContainer.mergeContent(textContainer);
            }
            else {
                containers.push(textContainer);
            }
        }
    }
    return function (node, lineage, config, containers) {
        if (containers === void 0) { containers = []; }
        var e_1, _a;
        // guard against processing undesirable nodes
        if (utils_1.isElement(node) &&
            (!lineage.length ||
                shouldSearchForContent(node, config.textContainerSearch))) {
            // process child text nodes or element nodes
            var childLineage = lineage.concat(node);
            try {
                for (var _b = __values(node.childNodes), _c = _b.next(); !_c.done; _c = _b.next()) {
                    var child = _c.value;
                    if (child.nodeType === Node.TEXT_NODE) {
                        addTextNode(child, childLineage, config, containers);
                    }
                    else {
                        findTextContainers(child, childLineage, config, containers);
                    }
                }
            }
            catch (e_1_1) { e_1 = { error: e_1_1 }; }
            finally {
                try {
                    if (_c && !_c.done && (_a = _b.return)) _a.call(_b);
                }
                finally { if (e_1) throw e_1.error; }
            }
        }
        return containers;
    };
}());
function groupTextContainersByDepth(containers) {
    return containers.reduce(function (depthGroups, container) {
        var containerDepth = container.containerLineage.length, existingGroup = depthGroups.find(function (group) { return group.depth === containerDepth; });
        if (existingGroup) {
            existingGroup.add(container);
        }
        else {
            depthGroups.push(new TextContainerDepthGroup_1.default(containerDepth, container));
        }
        return depthGroups;
    }, []);
}
// find traversal paths between depth group members
function findTraversalPaths(group) {
    return group.members.map(function (member, index, members) {
        var peers = members.filter(function (potentialPeer) { return potentialPeer !== member; }), paths = [
            new TraversalPath_1.default({
                hops: 0,
                frequency: 1,
                wordCount: member.wordCount
            })
        ];
        var _loop_1 = function (i) {
            var containerLineageIndex = group.depth - i, foundPeers = peers.filter(function (peer) { return peer.containerLineage[containerLineageIndex] === member.containerLineage[containerLineageIndex]; });
            if (foundPeers.length) {
                paths.push(new TraversalPath_1.default({
                    hops: i * 2,
                    frequency: foundPeers.length,
                    wordCount: foundPeers.reduce(function (sum, peer) { return sum += peer.wordCount; }, 0)
                }));
                foundPeers.forEach(function (peer) {
                    peers.splice(peers.indexOf(peer), 1);
                });
            }
        };
        for (var i = 1; i <= group.depth && peers.length; i++) {
            _loop_1(i);
        }
        return new TraversalPathSearchResult_1.default(member, paths);
    });
}
// image processing
var findImageContainers = (function () {
    function getTextContent(elements) {
        var e_2, _a;
        try {
            for (var elements_1 = __values(elements), elements_1_1 = elements_1.next(); !elements_1_1.done; elements_1_1 = elements_1.next()) {
                var element = elements_1_1.value;
                var text = element.textContent.trim();
                if (text) {
                    return text;
                }
            }
        }
        catch (e_2_1) { e_2 = { error: e_2_1 }; }
        finally {
            try {
                if (elements_1_1 && !elements_1_1.done && (_a = elements_1.return)) _a.call(elements_1);
            }
            finally { if (e_2) throw e_2.error; }
        }
        return null;
    }
    function addFigureContent(element, config, contentElements) {
        if (contentElements === void 0) { contentElements = []; }
        var e_3, _a;
        if (figureContent_1.isValidContent(element, config)) {
            contentElements.push(element);
            try {
                for (var _b = __values(element.children), _c = _b.next(); !_c.done; _c = _b.next()) {
                    var child = _c.value;
                    addFigureContent(child, config, contentElements);
                }
            }
            catch (e_3_1) { e_3 = { error: e_3_1 }; }
            finally {
                try {
                    if (_c && !_c.done && (_a = _b.return)) _a.call(_b);
                }
                finally { if (e_3) throw e_3.error; }
            }
        }
        return contentElements;
    }
    function addImage(element, lineage, config, images) {
        var e_4, _a;
        if (shouldSearchForContent(element, config.imageContainerSearch) &&
            !config.imageContainerSearch.descendantNodeNameBlacklist.some(function (nodeName) { return !!element.getElementsByTagName(nodeName).length; })) {
            var imgElements = Array.from(element.nodeName === 'IMG' ?
                [element] :
                element.getElementsByTagName('img')), validImgElements = imgElements.filter(function (element) { return utils_1.isValidImgElement(element); });
            if (!imgElements.length || validImgElements.length) {
                var containerElement = void 0;
                var contentElements = void 0;
                switch (element.nodeName) {
                    case 'PICTURE':
                        containerElement = element;
                        contentElements = Array
                            .from(element.children)
                            .filter(function (child) { return child.nodeName === 'SOURCE' || child.nodeName === 'META' || child.nodeName === 'IMG'; });
                        break;
                    case 'FIGURE':
                        containerElement = element;
                        contentElements = [];
                        try {
                            for (var _b = __values(element.children), _c = _b.next(); !_c.done; _c = _b.next()) {
                                var child = _c.value;
                                addFigureContent(child, config.imageContainerContent, contentElements);
                            }
                        }
                        catch (e_4_1) { e_4 = { error: e_4_1 }; }
                        finally {
                            try {
                                if (_c && !_c.done && (_a = _b.return)) _a.call(_b);
                            }
                            finally { if (e_4) throw e_4.error; }
                        }
                        break;
                    case 'IMG':
                        containerElement = element;
                        contentElements = [element];
                        break;
                }
                var metaSearchRoot = (searchUpLineage(lineage, function (ancestor, index) {
                    if (index === 0) {
                        return false;
                    }
                    var parent = lineage[index - 1];
                    return ((parent.previousElementSibling || parent.nextElementSibling) &&
                        !utils_1.findWordsInAttributes(parent).some(function (word) { return config.imageContainerMetadata.imageWrapperAttributeWordParts.some(function (part) { return word.includes(part); }); }));
                }) ||
                    element);
                images.push(new ImageContainer_1.default(containerElement ?
                    lineage.concat(containerElement) :
                    [], contentElements.map(function (child) { return lineage.concat(utils_1.buildLineage({ descendant: child, ancestor: element })); }), getTextContent(findDescendantsMatchingQuerySelectors(metaSearchRoot, config.imageContainerMetadata.captionSelectors)), getTextContent(findDescendantsMatchingQuerySelectors(metaSearchRoot, config.imageContainerMetadata.creditSelectors))));
            }
        }
    }
    return function (node, lineage, edge, searchArea, config, images) {
        if (images === void 0) { images = []; }
        if (utils_1.isElement(node) &&
            shouldSearchForContent(node, config.imageContainerSearch)) {
            var childLineage_1 = lineage.concat(node);
            findChildren(node, lineage.length, edge, searchArea).forEach(function (result) {
                if (utils_1.isImageContainerElement(result.node)) {
                    addImage(result.node, childLineage_1, config, images);
                }
                else {
                    findImageContainers(result.node, childLineage_1, result.edge, searchArea, config, images);
                }
            });
        }
        return images;
    };
}());
// missing text container processing
function findAdditionalPrimaryTextContainers(node, lineage, edge, searchArea, potentialContainers, blacklist, config, additionalContainers) {
    if (additionalContainers === void 0) { additionalContainers = []; }
    if (utils_1.isElement(node) &&
        !config.additionalContentNodeNameBlacklist.includes(node.nodeName) &&
        shouldSearchForContent(node, config) &&
        !blacklist.includes(node)) {
        findChildren(node, lineage.length, edge, searchArea).forEach(function (result) {
            var matchingContainer;
            if (utils_1.isElement(result.node) &&
                (matchingContainer = potentialContainers.find(function (container) { return container.containerElement === result.node; }))) {
                if (!blacklist.some(function (wrapper) { return wrapper === result.node || result.node.contains(wrapper); })) {
                    additionalContainers.push(matchingContainer);
                }
            }
            else {
                findAdditionalPrimaryTextContainers(result.node, __spread([node], lineage), result.edge, searchArea, potentialContainers, blacklist, config, additionalContainers);
            }
        });
    }
    return additionalContainers;
}
// safe area search
function findChildren(parent, depth, edge, searchArea) {
    var children = Array.from(parent.childNodes);
    if (edge !== GraphEdge_1.default.None &&
        depth < searchArea.length - 1) {
        var childrenLineageDepthGroup_1 = searchArea[depth + 1];
        var firstSearchableChildIndex_1, lastSearchableChildIndex_1;
        if (edge & GraphEdge_1.default.Left) {
            firstSearchableChildIndex_1 = children.findIndex(function (child) { return childrenLineageDepthGroup_1.includes(child); });
        }
        if (edge & GraphEdge_1.default.Right) {
            lastSearchableChildIndex_1 = (children.length -
                1 -
                children
                    .reverse()
                    .findIndex(function (child) { return childrenLineageDepthGroup_1.includes(child); }));
            children.reverse();
        }
        return children
            .filter(function (_, index) {
            return (firstSearchableChildIndex_1 != null ?
                index >= firstSearchableChildIndex_1 :
                true) &&
                (lastSearchableChildIndex_1 != null ?
                    index <= lastSearchableChildIndex_1 :
                    true);
        })
            .map(function (child, index, children) {
            var childEdge = GraphEdge_1.default.None;
            if (edge & GraphEdge_1.default.Left && index === 0) {
                childEdge |= GraphEdge_1.default.Left;
            }
            if (edge & GraphEdge_1.default.Right && index === children.length - 1) {
                childEdge |= GraphEdge_1.default.Right;
            }
            return {
                node: child,
                edge: childEdge
            };
        });
    }
    return children.map(function (child) { return ({
        node: child,
        edge: GraphEdge_1.default.None
    }); });
}
function parseDocumentContent() {
    var publisherConfig = configs_1.default.publishers.find(function (config) { return location.hostname.endsWith(config.hostname); });
    var contentSearchRootElement = selectContentSearchRootElement(publisherConfig ?
        publisherConfig.contentSearchRootElementSelector :
        null);
    var config = new Config_1.default(configs_1.default.universal, publisherConfig, contentSearchRootElement);
    var textContainers = findTextContainers(contentSearchRootElement, [], config)
        .filter(function (container) { return container.wordCount > 0 && isTextContentValid(container.containerElement, config.textContainerContent); });
    var textContainerDepthGroups = groupTextContainersByDepth(textContainers);
    var depthGroupWithMostWords = textContainerDepthGroups.sort(function (a, b) { return b.wordCount - a.wordCount; })[0];
    var traversalPathSearchResults = findTraversalPaths(depthGroupWithMostWords);
    var primaryTextContainerSearchResults = traversalPathSearchResults
        .reduce(function (groups, result) {
        var group = groups.find(function (group) { return group.preferredPathHopCount === result.getPreferredPath().hops; });
        if (group) {
            group.searchResults.push(result);
            group.wordCount += result.textContainer.wordCount;
        }
        else {
            groups.push({
                preferredPathHopCount: result.getPreferredPath().hops,
                searchResults: [result],
                wordCount: result.textContainer.wordCount
            });
        }
        return groups;
    }, [])
        .sort(function (a, b) { return b.wordCount - a.wordCount; })
        .reduce(function (selectedGroups, group) {
        if (selectedGroups.reduce(function (sum, group) { return sum + group.wordCount; }, 0) < depthGroupWithMostWords.wordCount * config.wordCountTraversalPathSearchLimitMultiplier) {
            selectedGroups.push(group);
        }
        return selectedGroups;
    }, [])
        .reduce(function (results, group) { return results.concat(group.searchResults); }, []);
    var primaryTextRootNode = primaryTextContainerSearchResults[0].textContainer.containerLineage[primaryTextContainerSearchResults[0].textContainer.containerLineage.length - Math.max((Math.max.apply(Math, __spread(primaryTextContainerSearchResults.map(function (result) { return result.getPreferredPath().hops; }))) / 2), 1)];
    var searchArea = utils_1.zipContentLineages(primaryTextContainerSearchResults.map(function (result) { return result.textContainer; }))
        .slice(utils_1.buildLineage({
        ancestor: contentSearchRootElement,
        descendant: primaryTextRootNode
    })
        .length - 1);
    var imageContainers = findImageContainers(primaryTextRootNode, [], GraphEdge_1.default.Left | GraphEdge_1.default.Right, searchArea, config)
        .filter(function (image) { return isImageContainerMetadataValid(image, config.imageContainerMetadata); });
    var additionalPrimaryTextContainers = findAdditionalPrimaryTextContainers(primaryTextRootNode, [], GraphEdge_1.default.Left | GraphEdge_1.default.Right, searchArea, textContainerDepthGroups
        .filter(function (group) { return (group.depth !== depthGroupWithMostWords.depth &&
        group.depth >= depthGroupWithMostWords.depth - config.textContainerSearch.additionalContentMaxDepthDecrease &&
        group.depth <= depthGroupWithMostWords.depth + config.textContainerSearch.additionalContentMaxDepthIncrease); })
        .reduce(function (containers, group) { return containers.concat(group.members); }, [])
        .concat(traversalPathSearchResults
        .filter(function (result) { return !primaryTextContainerSearchResults.includes(result); })
        .map(function (result) { return result.textContainer; })), imageContainers.map(function (container) { return container.containerElement; }), config.textContainerSearch)
        .filter(function (container) { return isTextContentValid(container.containerElement, config.textContainerContent); });
    return {
        contentSearchRootElement: contentSearchRootElement,
        depthGroupWithMostWords: depthGroupWithMostWords,
        primaryTextContainerSearchResults: primaryTextContainerSearchResults,
        additionalPrimaryTextContainers: additionalPrimaryTextContainers,
        primaryTextRootNode: primaryTextRootNode,
        primaryTextContainers: primaryTextContainerSearchResults
            .map(function (result) { return result.textContainer; })
            .concat(additionalPrimaryTextContainers),
        imageContainers: imageContainers
    };
}
exports.default = parseDocumentContent;


/***/ }),

/***/ "./src/common/contentParsing/utils.ts":
/*!********************************************!*\
  !*** ./src/common/contentParsing/utils.ts ***!
  \********************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

var __read = (this && this.__read) || function (o, n) {
    var m = typeof Symbol === "function" && o[Symbol.iterator];
    if (!m) return o;
    var i = m.call(o), r, ar = [], e;
    try {
        while ((n === void 0 || n-- > 0) && !(r = i.next()).done) ar.push(r.value);
    }
    catch (error) { e = { error: error }; }
    finally {
        try {
            if (r && !r.done && (m = i["return"])) m.call(i);
        }
        finally { if (e) throw e.error; }
    }
    return ar;
};
var __spread = (this && this.__spread) || function () {
    for (var ar = [], i = 0; i < arguments.length; i++) ar = ar.concat(__read(arguments[i]));
    return ar;
};
Object.defineProperty(exports, "__esModule", { value: true });
function buildLineage(_a) {
    var ancestor = _a.ancestor, descendant = _a.descendant;
    var lineage = [descendant];
    while (lineage[0] !== ancestor) {
        lineage.unshift(lineage[0].parentElement);
    }
    return lineage;
}
exports.buildLineage = buildLineage;
var attributeWordRegex = /[A-Z]?[a-z]+/g;
function findWordsInAttributes(element) {
    return (
    // searching other attributes such as data-* and src can lead to too many false positives of blacklisted words
    (element.id + ' ' + element.classList.value).match(attributeWordRegex) ||
        [])
        .map(function (word) { return word.toLowerCase(); });
}
exports.findWordsInAttributes = findWordsInAttributes;
;
function isElement(node) {
    return node.nodeType === Node.ELEMENT_NODE;
}
exports.isElement = isElement;
function isImageContainerElement(node) {
    return (node.nodeName === 'FIGURE' ||
        node.nodeName === 'IMG' ||
        node.nodeName === 'PICTURE');
}
exports.isImageContainerElement = isImageContainerElement;
function isValidImgElement(imgElement) {
    return ((imgElement.naturalWidth <= 1 && imgElement.naturalHeight <= 1) || ((imgElement.naturalWidth >= 200 && imgElement.naturalHeight >= 100) ||
        (imgElement.naturalWidth >= 100 && imgElement.naturalHeight >= 200)));
}
exports.isValidImgElement = isValidImgElement;
function zipContentLineages(containers) {
    return containers
        .reduce(function (depths, container) {
        container.contentLineages.forEach(function (lineage) {
            lineage.forEach(function (node, index) {
                if (!depths[index].includes(node)) {
                    depths[index].push(node);
                }
            });
        });
        return depths;
    }, Array
        .from(new Array(Math.max.apply(Math, __spread(containers.map(function (container) { return Math.max.apply(Math, __spread(container.contentLineages.map(function (lineage) { return lineage.length; }))); })))))
        .map(function () { return ([]); }));
}
exports.zipContentLineages = zipContentLineages;


/***/ }),

/***/ "./src/common/reading/createPageParseResult.ts":
/*!*****************************************************!*\
  !*** ./src/common/reading/createPageParseResult.ts ***!
  \*****************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

var __assign = (this && this.__assign) || function () {
    __assign = Object.assign || function(t) {
        for (var s, i = 1, n = arguments.length; i < n; i++) {
            s = arguments[i];
            for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p))
                t[p] = s[p];
        }
        return t;
    };
    return __assign.apply(this, arguments);
};
Object.defineProperty(exports, "__esModule", { value: true });
function createPageParseResult(metadata, content) {
    var wordCount = content.primaryTextContainers.reduce(function (sum, el) { return sum + el.wordCount; }, 0);
    return __assign({}, metadata.metadata, { wordCount: wordCount, readableWordCount: wordCount, article: __assign({}, metadata.metadata.article, { description: metadata.metadata.article.description }) });
}
exports.default = createPageParseResult;


/***/ }),

/***/ "./src/common/reading/parseDocumentMetadata.ts":
/*!*****************************************************!*\
  !*** ./src/common/reading/parseDocumentMetadata.ts ***!
  \*****************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

Object.defineProperty(exports, "__esModule", { value: true });
var parseElementMicrodata_1 = __webpack_require__(/*! ./parseElementMicrodata */ "./src/common/reading/parseElementMicrodata.ts");
var parseSchema_1 = __webpack_require__(/*! ./parseSchema */ "./src/common/reading/parseSchema.ts");
var parseMiscMetadata_1 = __webpack_require__(/*! ./parseMiscMetadata */ "./src/common/reading/parseMiscMetadata.ts");
var parseOpenGraph_1 = __webpack_require__(/*! ./parseOpenGraph */ "./src/common/reading/parseOpenGraph.ts");
var utils_1 = __webpack_require__(/*! ./utils */ "./src/common/reading/utils.ts");
var emptyResult = {
    url: null,
    article: {
        title: null,
        source: {},
        authors: [],
        tags: [],
        pageLinks: []
    }
};
function first(propSelector, filterOrResults, results) {
    var filter;
    if (filterOrResults instanceof Array) {
        filter = function (value) { return !!value; };
        results = filterOrResults;
    }
    else {
        filter = filterOrResults;
    }
    return results.map(propSelector).find(filter);
}
function most(propSelector, filterOrResults, results) {
    var filter;
    if (filterOrResults instanceof Array) {
        results = filterOrResults;
    }
    else {
        filter = filterOrResults;
    }
    var values = results.map(propSelector);
    if (filter) {
        values = values.filter(function (values) { return values.every(filter); });
    }
    return values.sort(function (a, b) { return b.length - a.length; })[0];
}
function merge(schema, misc, openGraph) {
    var orderedResults = [schema, openGraph, misc];
    return {
        url: first(function (x) { return utils_1.matchGetAbsoluteUrl(x.url); }, orderedResults),
        article: {
            title: first(function (x) { return x.article.title; }, orderedResults),
            source: first(function (x) { return x.article.source; }, function (x) { return !!x.name; }, orderedResults),
            datePublished: first(function (x) { return x.article.datePublished; }, orderedResults),
            dateModified: first(function (x) { return x.article.dateModified; }, orderedResults),
            authors: most(function (x) { return x.article.authors; }, function (x) { return !!x.name; }, orderedResults),
            section: first(function (x) { return x.article.section; }, orderedResults),
            description: first(function (x) { return x.article.description; }, orderedResults),
            tags: most(function (x) { return x.article.tags; }, orderedResults),
            pageLinks: most(function (x) { return x.article.pageLinks; }, orderedResults)
        }
    };
}
var articleElementAttributeBlacklistRegex = /((^|\W)comments?($|\W))/i;
function parseDocumentMetadata() {
    var isArticle = false;
    // misc
    var misc = parseMiscMetadata_1.default();
    if (Array
        .from(document.getElementsByTagName('article'))
        .filter(function (element) { return !(articleElementAttributeBlacklistRegex.test(element.id) ||
        articleElementAttributeBlacklistRegex.test(element.classList.value)); })
        .length === 1) {
        isArticle = true;
    }
    // OpenGraph
    var openGraph = parseOpenGraph_1.default();
    if (openGraph) {
        isArticle = true;
    }
    else {
        openGraph = emptyResult;
    }
    // schema.org
    var schema;
    // first check for an LD+JSON script
    var script = document.querySelector('script[type="application/ld+json"]');
    if (script && script.textContent) {
        var cdataMatch = script.textContent.match(/^\s*\/\/<!\[CDATA\[([\s\S]*)\/\/\]\]>\s*$/);
        try {
            if (cdataMatch) {
                schema = parseSchema_1.default([JSON.parse(cdataMatch[1])]);
            }
            else {
                schema = parseSchema_1.default([JSON.parse(script.textContent)]);
            }
        }
        catch (ex) {
            // LD+JSON parse error
        }
    }
    // log or parse document microdata
    if (schema) {
        isArticle = true;
    }
    else if (schema = parseSchema_1.default(parseElementMicrodata_1.default(document.documentElement))) {
        isArticle = true;
    }
    else {
        schema = emptyResult;
    }
    // merge metadata objects
    return { isArticle: isArticle, metadata: merge(schema, misc, openGraph) };
}
exports.default = parseDocumentMetadata;


/***/ }),

/***/ "./src/common/reading/parseElementMicrodata.ts":
/*!*****************************************************!*\
  !*** ./src/common/reading/parseElementMicrodata.ts ***!
  \*****************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

Object.defineProperty(exports, "__esModule", { value: true });
var utils_1 = __webpack_require__(/*! ./utils */ "./src/common/reading/utils.ts");
var valueMap = {
    'a': 'href',
    'img': 'src',
    'link': 'href',
    'meta': 'content',
    'object': 'data',
    'time': 'datetime'
};
var itemTypeRegExp = /schema\.org\/(.+)/;
function isScopeElement(element) {
    return element.hasAttribute('itemscope') || element.hasAttribute('itemtype');
}
function getElementValue(element) {
    // use getAttribute instead of property to avoid case-sensitivity issues
    var tagName = element.tagName.toLowerCase();
    return valueMap.hasOwnProperty(tagName) ? element.getAttribute(valueMap[tagName]) : element.textContent;
}
function getElementType(element, isTopLevel) {
    var type = {};
    if (element.hasAttribute('itemtype')) {
        if (isTopLevel) {
            type['@context'] = 'http://schema.org';
        }
        var itemType = element.getAttribute('itemtype'), match = itemType.match(itemTypeRegExp);
        if (match && match.length === 2) {
            type['@type'] = match[1];
        }
        else {
            type['@type'] = itemType;
        }
    }
    return type;
}
function mergeValue(properties, value, scope) {
    properties.forEach(function (property) {
        if (scope.hasOwnProperty(property)) {
            if (scope[property] instanceof Array) {
                scope[property].push(value);
            }
            else {
                scope[property] = [scope[property], value];
            }
        }
        else {
            scope[property] = value;
        }
    });
    return value;
}
function parseElementMicrodata(element, topLevelTypes, scope) {
    if (topLevelTypes === void 0) { topLevelTypes = []; }
    if (scope === void 0) { scope = null; }
    // check element for microdata attributes
    // check for scope to guard against invalid itemprops declared outside a scope
    if (scope && element.hasAttribute('itemprop')) {
        var properties = utils_1.getWords(element.getAttribute('itemprop'));
        if (isScopeElement(element)) {
            // value is a type
            scope = mergeValue(properties, getElementType(element), scope);
            // guard against non-scope elements with an itemid attribute
        }
        else if (!element.hasAttribute('itemid')) {
            // value is a primitive
            mergeValue(properties, getElementValue(element), scope);
        }
    }
    else if (isScopeElement(element)) {
        // new top level type
        topLevelTypes.push(scope = getElementType(element, true));
    }
    // process children
    for (var i = 0; i < element.children.length; i++) {
        parseElementMicrodata(element.children[i], topLevelTypes, scope);
    }
    // return top level types
    return topLevelTypes;
}
exports.default = parseElementMicrodata;


/***/ }),

/***/ "./src/common/reading/parseMiscMetadata.ts":
/*!*************************************************!*\
  !*** ./src/common/reading/parseMiscMetadata.ts ***!
  \*************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

Object.defineProperty(exports, "__esModule", { value: true });
var utils_1 = __webpack_require__(/*! ./utils */ "./src/common/reading/utils.ts");
function parseMiscMetadata() {
    var articleTitleElements = document.querySelectorAll('article h1');
    return {
        url: (utils_1.matchGetAbsoluteUrl(utils_1.getElementAttribute(document.querySelector('link[rel="canonical"]'), function (e) { return e.href; })) ||
            window.location.href.split(/\?|#/)[0]),
        article: {
            title: (articleTitleElements.length === 1 ?
                articleTitleElements[0].textContent.trim() :
                document.title),
            source: {
                url: (utils_1.matchGetAbsoluteUrl(utils_1.getElementAttribute(document.querySelector('link[rel="publisher"]'), function (e) { return e.href; })) ||
                    window.location.protocol + '//' + window.location.hostname)
            },
            description: utils_1.getElementAttribute(document.querySelector('meta[name="description"]'), function (e) { return e.content; }),
            authors: Array.from(document.querySelectorAll('meta[name="author"]')).map(function (e) { return ({ name: e.content }); }),
            tags: [],
            pageLinks: []
        }
    };
}
exports.default = parseMiscMetadata;


/***/ }),

/***/ "./src/common/reading/parseOpenGraph.ts":
/*!**********************************************!*\
  !*** ./src/common/reading/parseOpenGraph.ts ***!
  \**********************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

Object.defineProperty(exports, "__esModule", { value: true });
var utils_1 = __webpack_require__(/*! ./utils */ "./src/common/reading/utils.ts");
function findMetaElementContent(property, elements) {
    return utils_1.getElementAttribute(elements.find(function (e) { return e.getAttribute('property') === property; }), function (e) { return e.content; });
}
function parseOpenGraph() {
    var elements = Array.from(document.getElementsByTagName('meta'));
    if (/article/i.test(findMetaElementContent('og:type', elements))) {
        return {
            url: findMetaElementContent('og:url', elements),
            article: {
                title: findMetaElementContent('og:title', elements),
                source: {
                    name: findMetaElementContent('og:site_name', elements)
                },
                datePublished: findMetaElementContent('article:published_time', elements),
                dateModified: findMetaElementContent('article:modified_time', elements),
                authors: elements
                    .filter(function (e) { return e.getAttribute('property') === 'article:author'; })
                    .map(function (e) {
                    var url = utils_1.matchGetAbsoluteUrl(e.content);
                    return url ? { url: url } : { name: e.content };
                }),
                section: findMetaElementContent('article:section', elements),
                description: findMetaElementContent('og:description', elements),
                tags: elements
                    .filter(function (e) { return e.getAttribute('property') === 'article:tag'; })
                    .map(function (e) { return e.content; }),
                pageLinks: []
            }
        };
    }
    return null;
}
exports.default = parseOpenGraph;


/***/ }),

/***/ "./src/common/reading/parseSchema.ts":
/*!*******************************************!*\
  !*** ./src/common/reading/parseSchema.ts ***!
  \*******************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

Object.defineProperty(exports, "__esModule", { value: true });
function first(value, map) {
    var retValue = value instanceof Array ? value[0] : value;
    return map && retValue ? map(retValue) : retValue;
}
function many(value, map) {
    var retValue = value instanceof Array ? value : value ? [value] : [];
    return map ? retValue.map(map) : retValue;
}
function parseSchema(topLevelTypes) {
    var data = topLevelTypes.find(function (type) {
        return type.hasOwnProperty('@type') &&
            (type['@type'].endsWith('Article') || type['@type'] === 'BlogPosting');
    });
    if (data) {
        return {
            url: first(data.url),
            article: {
                title: first(data.headline) || first(data.name),
                source: first(data.publisher || data.sourceOrganization || data.provider, function (x) { return ({
                    name: first(x.name),
                    url: first(x.url)
                }); }) || {},
                datePublished: first(data.datePublished),
                dateModified: first(data.dateModified),
                authors: many(data.author || data.creator, function (x) { return ({
                    name: first(x.name),
                    url: first(x.url)
                }); }),
                section: first(data.articleSection) || first(data.printSection),
                description: first(data.description),
                tags: data.keywords ? data.keywords instanceof Array ? data.keywords : data.keywords.split(',') : [],
                pageLinks: []
            }
        };
    }
    return null;
}
exports.default = parseSchema;


/***/ }),

/***/ "./src/common/reading/utils.ts":
/*!*************************************!*\
  !*** ./src/common/reading/utils.ts ***!
  \*************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

Object.defineProperty(exports, "__esModule", { value: true });
exports.absoluteUrlRegex = /^(https?:)?\/{2}(?!\/)/;
function getElementAttribute(element, selector) {
    return element ? selector(element) : null;
}
exports.getElementAttribute = getElementAttribute;
function matchGetAbsoluteUrl(url) {
    if (url) {
        var match = url.match(exports.absoluteUrlRegex);
        if (match) {
            if (!match[1]) {
                return window.location.protocol + url;
            }
            else {
                return url;
            }
        }
    }
    return null;
}
exports.matchGetAbsoluteUrl = matchGetAbsoluteUrl;
function getWords(text) {
    // better to match words instead of splitting on
    // whitespace in order to avoid empty results
    return (text && text.match(/\S+/g)) || [];
}
exports.getWords = getWords;


/***/ }),

/***/ "./src/native-client/share-extension/main.ts":
/*!***************************************************!*\
  !*** ./src/native-client/share-extension/main.ts ***!
  \***************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

Object.defineProperty(exports, "__esModule", { value: true });
var WebViewMessagingContext_1 = __webpack_require__(/*! ../../common/WebViewMessagingContext */ "./src/common/WebViewMessagingContext.ts");
var parseDocumentMetadata_1 = __webpack_require__(/*! ../../common/reading/parseDocumentMetadata */ "./src/common/reading/parseDocumentMetadata.ts");
var createPageParseResult_1 = __webpack_require__(/*! ../../common/reading/createPageParseResult */ "./src/common/reading/createPageParseResult.ts");
var parseDocumentContent_1 = __webpack_require__(/*! ../../common/contentParsing/parseDocumentContent */ "./src/common/contentParsing/parseDocumentContent.ts");
new WebViewMessagingContext_1.default().sendMessage({
    type: 'parseResult',
    data: createPageParseResult_1.default(parseDocumentMetadata_1.default(), parseDocumentContent_1.default())
});


/***/ })

/******/ });