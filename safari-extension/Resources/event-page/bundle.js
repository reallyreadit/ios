!function(e){var t={};function n(r){if(t[r])return t[r].exports;var o=t[r]={i:r,l:!1,exports:{}};return e[r].call(o.exports,o,o.exports,n),o.l=!0,o.exports}n.m=e,n.c=t,n.d=function(e,t,r){n.o(e,t)||Object.defineProperty(e,t,{enumerable:!0,get:r})},n.r=function(e){"undefined"!=typeof Symbol&&Symbol.toStringTag&&Object.defineProperty(e,Symbol.toStringTag,{value:"Module"}),Object.defineProperty(e,"__esModule",{value:!0})},n.t=function(e,t){if(1&t&&(e=n(e)),8&t)return e;if(4&t&&"object"==typeof e&&e&&e.__esModule)return e;var r=Object.create(null);if(n.r(r),Object.defineProperty(r,"default",{enumerable:!0,value:e}),2&t&&"string"!=typeof e)for(var o in e)n.d(r,o,function(t){return e[t]}.bind(null,o));return r},n.n=function(e){var t=e&&e.__esModule?function(){return e.default}:function(){return e};return n.d(t,"a",t),t},n.o=function(e,t){return Object.prototype.hasOwnProperty.call(e,t)},n.p="",n(n.s=5)}([function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0}),t.parseQueryString=function(e){return e?(e.startsWith("?")&&(e=e.substring(1)),e.split("&").reduce((function(e,t){var n=t.split("=");return e[decodeURIComponent(n[0])]=decodeURIComponent(n[1]),e}),{})):{}},t.createQueryString=function(e){if(e){var t=Object.keys(e).reduce((function(t,n){var r=encodeURIComponent(n),o=e[n];return null==o?t.push(r):"string"==typeof o||"number"==typeof o?t.push(r+"="+encodeURIComponent(o)):Array.isArray(o)&&o.forEach((function(e){t.push(r+"="+encodeURIComponent(e))})),t}),[]);if(t.length)return"?"+t.join("&")}return""},t.appReferralQueryStringKey="appReferral",t.authServiceTokenQueryStringKey="authServiceToken",t.clientTypeQueryStringKey="clientType",t.extensionAuthQueryStringKey="extensionAuth",t.extensionInstalledQueryStringKey="extensionInstalled",t.marketingVariantQueryStringKey="marketingVariant",t.messageQueryStringKey="message",t.marketingScreenVariantQueryStringKey="marketingScreenVariant",t.referrerUrlQueryStringKey="referrerUrl",t.unroutableQueryStringKeys=[t.appReferralQueryStringKey,t.authServiceTokenQueryStringKey,t.clientTypeQueryStringKey,t.extensionAuthQueryStringKey,t.extensionInstalledQueryStringKey,t.marketingVariantQueryStringKey,t.messageQueryStringKey,t.marketingScreenVariantQueryStringKey,t.referrerUrlQueryStringKey]},function(e,t,n){"use strict";var r,o=this&&this.__extends||(r=function(e,t){return(r=Object.setPrototypeOf||{__proto__:[]}instanceof Array&&function(e,t){e.__proto__=t}||function(e,t){for(var n in t)t.hasOwnProperty(n)&&(e[n]=t[n])})(e,t)},function(e,t){function n(){this.constructor=e}r(e,t),e.prototype=null===t?Object.create(t):(n.prototype=t.prototype,new n)});Object.defineProperty(t,"__esModule",{value:!0});var a=function(e){function t(t,n,r){void 0===r&&(r="localStorage");var o=e.call(this,t,[],r)||this;return o._getKey=n,o}return o(t,e),t.prototype._getItemByKey=function(e,t){var n=this;return t.filter((function(t){return n._getKey(t)===e}))[0]},t.prototype._removeItem=function(e,t){t.splice(t.indexOf(e),1)},t.prototype.get=function(e){return this._getItemByKey(e,this._read())},t.prototype.getAll=function(){return this._read()},t.prototype.set=function(e){var t=this._read(),n=this._getItemByKey(this._getKey(e),t);return n&&this._removeItem(n,t),t.push(e),this._write(t),e},t.prototype.remove=function(e){var t=this._read(),n=this._getItemByKey(e,t);return n&&(this._removeItem(n,t),this._write(t)),n},t}(n(2).default);t.default=a},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var r=function(){function e(e,t,n){var r=this;if(void 0===n&&(n="localStorage"),this._eventListeners=[],this._defaultValue=t,function(e){void 0===e&&(e="localStorage");try{var t=window[e],n="__storage_test__";return t.setItem(n,n),t.removeItem(n),!0}catch(e){return e instanceof DOMException&&(22===e.code||1014===e.code||"QuotaExceededError"===e.name||"NS_ERROR_DOM_QUOTA_REACHED"===e.name)&&0!==t.length}}(n)){var o;switch(n){case"localStorage":o=localStorage;break;case"sessionStorage":o=sessionStorage}this._storage={read:function(){return JSON.parse(o.getItem(e))},write:function(t){o.setItem(e,JSON.stringify(t))}},this._onStorage=function(t){t.key===e&&r._eventListeners.forEach((function(e){e(JSON.parse(t.oldValue),JSON.parse(t.newValue))}))};try{null==this._read()&&this.clear()}catch(e){this.clear()}}else{var a;this._storage={read:function(){return a},write:function(e){a=e}}}}return e.prototype._read=function(){return this._storage.read()},e.prototype._write=function(e){this._storage.write(e)},e.prototype.clear=function(){this._write(this._defaultValue)},e.prototype.addEventListener=function(e){0===this._eventListeners.length&&window.addEventListener("storage",this._onStorage),this._eventListeners.push(e)},e.prototype.removeEventListener=function(e){this._eventListeners.splice(this._eventListeners.findIndex((function(t){return t===e})),1),0===this._eventListeners.length&&window.removeEventListener("storage",this._onStorage)},e}();t.default=r},function(e,t,n){"use strict";var r,o=this&&this.__extends||(r=function(e,t){return(r=Object.setPrototypeOf||{__proto__:[]}instanceof Array&&function(e,t){e.__proto__=t}||function(e,t){for(var n in t)t.hasOwnProperty(n)&&(e[n]=t[n])})(e,t)},function(e,t){function n(){this.constructor=e}r(e,t),e.prototype=null===t?Object.create(t):(n.prototype=t.prototype,new n)});Object.defineProperty(t,"__esModule",{value:!0});var a=function(e){function t(t,n,r){return void 0===r&&(r="localStorage"),e.call(this,t,n,r)||this}return o(t,e),t.prototype.get=function(){return this._read()},t.prototype.set=function(e){this._write(e)},t}(n(2).default);t.default=a},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var r=n(0),o=[{protocol:"http",port:80},{protocol:"https",port:443}];function a(e){return e.startsWith("/")?e:"/"+e}t.createUrl=function(e,t,n){var i=e.protocol+"://"+e.host;if(null!=e.port){var s=o.filter((function(t){return t.protocol===e.protocol}))[0];s&&s.port===e.port||(i+=":"+e.port)}return e.path&&(i+=a(e.path)),t&&(i+=a(t)),n&&(i+=r.createQueryString(n)),i}},function(e,t,n){"use strict";var r=this&&this.__read||function(e,t){var n="function"==typeof Symbol&&e[Symbol.iterator];if(!n)return e;var r,o,a=n.call(e),i=[];try{for(;(void 0===t||t-- >0)&&!(r=a.next()).done;)i.push(r.value)}catch(e){o={error:e}}finally{try{r&&!r.done&&(n=a.return)&&n.call(a)}finally{if(o)throw o.error}}return i},o=this&&this.__spread||function(){for(var e=[],t=0;t<arguments.length;t++)e=e.concat(r(arguments[t]));return e};Object.defineProperty(t,"__esModule",{value:!0});var a=n(6),i=n(10),s=n(15),c=n(4),u=n(16),l=n(17),d=n(18),p=n(0);function f(e){var t="/icons/";t+="authenticated"===e?"icon-{SIZE}.png":"icon-{SIZE}-warning.png",chrome.browserAction.setIcon({path:[16,24,32,40,48].reduce((function(e,n){return e[n]=t.replace("{SIZE}",n.toString()),e}),{})})}var h=new i.default({onDisplayPreferenceChanged:function(e){m.displayPreferenceChanged(e),g.displayPreferenceChanged(e)},onUserSignedOut:function(){f("unauthenticated"),m.userSignedOut()},onUserUpdated:function(e){m.userUpdated(e),g.userUpdated(e)}}),m=new a.default({onGetDisplayPreference:function(){return h.getDisplayPreference()},onChangeDisplayPreference:function(e){return g.displayPreferenceChanged(e),h.changeDisplayPreference(e)},onRegisterPage:function(e,t){return h.registerPage(e,t).then((function(e){return g.articleUpdated({article:e.userArticle,isCompletionCommit:!1}),e}))},onCommitReadState:function(e,t,n){return console.log("contentScriptApi.onCommitReadState (tabId: "+e+")"),h.commitReadState(e,t).then((function(e){return g.articleUpdated({article:e,isCompletionCommit:n}),e}))},onLoadContentParser:function(e){try{if(new u.default(localStorage.getItem("contentParserVersion")).compareTo(new u.default("1.1.1"))>0)return console.log("contentScriptApi.onLoadContentParser (loading content parser from localStorage, tabId: "+e+")"),void chrome.tabs.executeScript(e,{code:localStorage.getItem("contentParserScript")})}catch(e){}console.log("contentScriptApi.onLoadContentParser (loading content parser from bundle, tabId: "+e+")"),chrome.tabs.executeScript(e,{file:"/content-scripts/reader/content-parser/bundle.js"})},onGetComments:function(e){return h.getComments(e)},onPostArticle:function(e){return h.postArticle(e).then((function(e){return g.articlePosted(e),g.articleUpdated({article:e.article,isCompletionCommit:!1}),e.comment&&g.commentPosted(l.createCommentThread(e)),e}))},onPostComment:function(e){return h.postComment(e).then((function(e){return g.articleUpdated({article:e.article,isCompletionCommit:!1}),g.commentPosted(e.comment),e}))},onPostCommentAddendum:function(e){return h.postCommentAddendum(e).then((function(e){return g.commentUpdated(e),e}))},onPostCommentRevision:function(e){return h.postCommentRevision(e).then((function(e){return g.commentUpdated(e),e}))},onRequestTwitterBrowserLinkRequestToken:function(){return h.requestTwitterBrowserLinkRequestToken()},onReportArticleIssue:function(e){return h.reportArticleIssue(e)},onSetStarred:function(e){return h.setStarred(e.articleId,e.isStarred).then((function(e){return g.articleUpdated({article:e,isCompletionCommit:!1}),e}))},onDeleteComment:function(e){return h.deleteComment(e).then((function(e){return g.commentUpdated(e),e}))}}),g=new s.default({onArticleUpdated:function(e){m.articleUpdated(e)},onAuthServiceLinkCompleted:function(e){m.authServiceLinkCompleted(e)},onDisplayPreferenceChanged:function(e){h.displayPreferenceChanged(e),m.displayPreferenceChanged(e)},onCommentPosted:function(e){m.commentPosted(e)},onCommentUpdated:function(e){m.commentUpdated(e)},onUserSignedIn:function(e){f("authenticated"),h.userSignedIn(e)},onUserSignedOut:function(){f("unauthenticated"),h.userSignedOut(),m.userSignedOut()},onUserUpdated:function(e){h.userUpdated(e),m.userUpdated(e)}});chrome.runtime.onInstalled.addListener((function(e){console.log("[EventPage] installed, reason: "+e.reason),["sessionKey",d.sessionIdCookieKey].forEach((function(e){chrome.cookies.get({url:c.createUrl(Object({protocol:"https",host:"readup.com"})),name:e},(function(e){var t;"unspecified"===(null===(t=e)||void 0===t?void 0:t.sameSite)&&chrome.cookies.set({url:c.createUrl(Object({protocol:"https",host:"readup.com"})),domain:e.domain,expirationDate:e.expirationDate,httpOnly:e.httpOnly,name:e.name,path:e.path,sameSite:"no_restriction",secure:e.secure,storeId:e.storeId,value:e.value})}))})),localStorage.removeItem("parseMode"),localStorage.removeItem("showOverlay"),localStorage.removeItem("newReplyNotification"),localStorage.removeItem("sourceRules"),localStorage.removeItem("articles"),localStorage.removeItem("tabs"),localStorage.setItem("debug",JSON.stringify(!1)),f(h.isAuthenticated()?"authenticated":"unauthenticated"),m.clearTabs(),g.clearTabs(),g.injectContentScripts(),("install"===e.reason||"update"===e.reason&&!localStorage.getItem("installationId"))&&chrome.runtime.getPlatformInfo((function(e){h.logExtensionInstallation(e).then((function(e){chrome.runtime.setUninstallURL(c.createUrl(Object({protocol:"https",host:"readup.com"}),"/extension/uninstall",{installationId:e.installationId})),localStorage.setItem("installationId",e.installationId)})).catch((function(e){console.log("[EventPage] error logging installation"),e&&console.log(e)}))})),chrome.alarms.create("updateContentParser",{when:Date.now(),periodInMinutes:120}),chrome.notifications&&chrome.alarms.create(i.default.alarms.checkNotifications,{when:Date.now(),periodInMinutes:2.5}),chrome.alarms.create(i.default.alarms.getBlacklist,{when:Date.now(),periodInMinutes:120}),chrome.alarms.clear("ServerApi.checkNewReplyNotification"),chrome.cookies.set({url:c.createUrl(Object({protocol:"https",host:"readup.com"})),domain:".readup.com",expirationDate:(Date.now()+31536e6)/1e3,name:d.extensionVersionCookieKey,secure:!0,value:"4.1.0",path:"/",sameSite:"no_restriction"},(function(){"install"===e.reason&&chrome.cookies.get({url:c.createUrl(Object({protocol:"https",host:"readup.com"})),name:d.extensionInstallationRedirectPathCookieKey},(function(e){var t,n;chrome.tabs.create({url:c.createUrl(Object({protocol:"https",host:"readup.com"}),null===(n=e)||void 0===n?void 0:n.value,(t={},t[p.extensionInstalledQueryStringKey]=null,t))})}))}))})),chrome.runtime.onStartup.addListener((function(){console.log("[EventPage] startup"),f(h.isAuthenticated()?"authenticated":"unauthenticated"),m.clearTabs(),g.clearTabs(),g.injectContentScripts()})),chrome.browserAction.onClicked.addListener((function(e){var t;h.isAuthenticated()?e.url&&(e.url.startsWith(c.createUrl(Object({protocol:"https",host:"readup.com"})))?chrome.tabs.executeScript(e.id,{code:"if (!window.reallyreadit?.alertContentScript) { window.reallyreadit = { ...window.reallyreadit, alertContentScript: { alertContent: 'Press the Readup button when you\\'re on an article web page.' } }; chrome.runtime.sendMessage({ from: 'contentScriptInitializer', to: 'eventPage', type: 'injectAlert' }); } else if (!window.reallyreadit.alertContentScript.isActive) { window.reallyreadit.alertContentScript.display(); }"}):h.getBlacklist().some((function(t){return t.test(e.url)}))?chrome.tabs.executeScript(e.id,{code:"if (!window.reallyreadit?.alertContentScript) { window.reallyreadit = { ...window.reallyreadit, alertContentScript: { alertContent: 'No article detected on this web page.' } }; chrome.runtime.sendMessage({ from: 'contentScriptInitializer', to: 'eventPage', type: 'injectAlert' }); } else if (!window.reallyreadit.alertContentScript.isActive) { window.reallyreadit.alertContentScript.display(); }"}):chrome.tabs.executeScript(e.id,{code:"if (!window.reallyreadit?.readerContentScript) { window.reallyreadit = { ...window.reallyreadit, readerContentScript: { } }; chrome.runtime.sendMessage({ from: 'contentScriptInitializer', to: 'eventPage', type: 'injectReader' }); }"})):chrome.tabs.create({url:c.createUrl(Object({protocol:"https",host:"readup.com"}),null,(t={},t[p.extensionAuthQueryStringKey]=null,t))})})),chrome.runtime.onMessage.addListener((function(e,t){if("contentScriptInitializer"===e.from&&"eventPage"===e.to)switch(e.type){case"injectAlert":return void chrome.tabs.executeScript(t.tab.id,{file:"/content-scripts/alert/bundle.js"});case"injectReader":return void chrome.tabs.executeScript(t.tab.id,{file:"/content-scripts/reader/bundle.js"})}})),chrome.alarms.onAlarm.addListener((function(e){if("updateContentParser"===e.name){var t=u.default.greatest.apply(u.default,o(["1.1.1",localStorage.getItem("contentParserVersion")].filter((function(e){return!!e})).map((function(e){return new u.default(e)}))));console.log("chrome.alarms.onAlarm (updateContentParser: checking for new version. current version: "+t.toString()+")"),fetch(c.createUrl(Object({protocol:"https",host:"static.readup.com"}),"/extension/content-parser.txt")).then((function(e){return e.text()})).then((function(e){var n=e.split("\n").filter((function(e){return!!e})).map((function(e){return{fileName:e,version:new u.default(e)}})).find((function(e){return t.canUpgradeTo(e.version)}));n?(console.log("chrome.alarms.onAlarm (updateContentParser: updating to version: "+n.version.toString()+")"),fetch(c.createUrl(Object({protocol:"https",host:"static.readup.com"}),"/extension/content-parser/"+n.fileName)).then((function(e){return e.text()})).then((function(e){localStorage.setItem("contentParserScript",e),localStorage.setItem("contentParserVersion",n.version.toString())})).catch((function(){console.log("chrome.alarms.onAlarm (updateContentParser: error updating to new version)")}))):console.log("chrome.alarms.onAlarm (updateContentParser: no new version)")})).catch((function(){console.log("chrome.alarms.onAlarm (updateContentParser: error checking for new version)")}))}}))},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var r=n(7),o=n(1),a=n(8),i=n(9),s=function(){function e(e){var t=this;this._badge=new a.default,this._tabs=new o.default("readerTabs",(function(e){return e.id}),"localStorage"),chrome.runtime.onMessage.addListener((function(n,o,a){var s;if("eventPage"===n.to&&"readerContentScript"===n.from)switch(console.log("[ReaderApi] received "+n.type+" message from tab # "+(null===(s=o.tab)||void 0===s?void 0:s.id)),n.type){case"getDisplayPreference":a({value:e.onGetDisplayPreference()});break;case"changeDisplayPreference":return t.sendMessageToOtherTabs(o.tab.id,{type:"displayPreferenceChanged",data:n.data}),r.createMessageResponseHandler(e.onChangeDisplayPreference(n.data),a),!0;case"registerPage":return t._tabs.set({articleId:null,id:o.tab.id}),t._badge.setLoading(o.tab.id),r.createMessageResponseHandler(e.onRegisterPage(o.tab.id,n.data).then((function(e){return t._tabs.set({articleId:e.userArticle.id,id:o.tab.id}),t._tabs.getAll().forEach((function(n){n.articleId===e.userArticle.id&&(t._badge.setReading(n.id,e.userArticle),chrome.browserAction.setTitle({tabId:n.id,title:i.calculateEstimatedReadTime(e.userArticle.wordCount)+" min. read"}))})),e})).catch((function(e){throw t._tabs.remove(o.tab.id),t._badge.setDefault(o.tab.id),e})),a),!0;case"commitReadState":return r.createMessageResponseHandler(e.onCommitReadState(o.tab.id,n.data.commitData,n.data.isCompletionCommit).then((function(e){return t._tabs.getAll().forEach((function(n){n.articleId===e.id&&t._badge.setReading(n.id,e)})),e})),a),!0;case"unregisterPage":t._tabs.remove(o.tab.id);break;case"loadContentParser":e.onLoadContentParser(o.tab.id);break;case"closeWindow":chrome.windows.remove(n.data,(function(){chrome.runtime.lastError&&console.log("[ReaderApi] error closing window, message: "+chrome.runtime.lastError.message)}));break;case"getComments":return r.createMessageResponseHandler(e.onGetComments(n.data),a),!0;case"hasWindowClosed":return r.createMessageResponseHandler(new Promise((function(e,t){chrome.windows.get(n.data,(function(t){chrome.runtime.lastError&&console.log("[ReaderApi] error getting window, message: "+chrome.runtime.lastError.message),e(!t)}))})),a),!0;case"openWindow":var c=n.data;return r.createMessageResponseHandler(new Promise((function(e,t){chrome.windows.create({type:"popup",url:c.url,width:c.width,height:c.height,focused:!0},(function(n){if(chrome.runtime.lastError)return console.log("[ReaderApi] error opening window, message: "+chrome.runtime.lastError.message),void t(chrome.runtime.lastError);e(n.id)}))})),a),!0;case"postArticle":return r.createMessageResponseHandler(e.onPostArticle(n.data),a),!0;case"postComment":return r.createMessageResponseHandler(e.onPostComment(n.data),a),!0;case"postCommentAddendum":return r.createMessageResponseHandler(e.onPostCommentAddendum(n.data),a),!0;case"postCommentRevision":return r.createMessageResponseHandler(e.onPostCommentRevision(n.data),a),!0;case"reportArticleIssue":return r.createMessageResponseHandler(e.onReportArticleIssue(n.data),a),!0;case"requestTwitterBrowserLinkRequestToken":return r.createMessageResponseHandler(e.onRequestTwitterBrowserLinkRequestToken(),a),!0;case"setStarred":return r.createMessageResponseHandler(e.onSetStarred(n.data),a),!0;case"deleteComment":return r.createMessageResponseHandler(e.onDeleteComment(n.data),a),!0}return!1}))}return e.prototype.broadcastMessage=function(e,t){var n=this;e.forEach((function(e){console.log("[ReaderApi] sending "+t.type+" message to tab # "+e.id),chrome.tabs.sendMessage(e.id,t,(function(){chrome.runtime.lastError&&(console.log("[ReaderApi] error sending message to tab # "+e.id+", message: "+chrome.runtime.lastError.message),n._tabs.remove(e.id))}))}))},e.prototype.sendMessageToAllTabs=function(e){this.broadcastMessage(this._tabs.getAll(),e)},e.prototype.sendMessageToOtherTabs=function(e,t){this.broadcastMessage(this._tabs.getAll().filter((function(t){return t.id!==e})),t)},e.prototype.sendMessageToArticleTabs=function(e,t){this.broadcastMessage(this._tabs.getAll().filter((function(t){return t.articleId===e})),t)},e.prototype.articleUpdated=function(e){this.sendMessageToArticleTabs(e.article.id,{type:"articleUpdated",data:e})},e.prototype.authServiceLinkCompleted=function(e){this.sendMessageToAllTabs({type:"authServiceLinkCompleted",data:e})},e.prototype.clearTabs=function(){this._tabs.clear()},e.prototype.commentPosted=function(e){this.sendMessageToArticleTabs(e.articleId,{type:"commentPosted",data:e})},e.prototype.commentUpdated=function(e){this.sendMessageToArticleTabs(e.articleId,{type:"commentUpdated",data:e})},e.prototype.displayPreferenceChanged=function(e){this.sendMessageToAllTabs({type:"displayPreferenceChanged",data:e})},e.prototype.userSignedOut=function(){var e=this;this.sendMessageToAllTabs({type:"userSignedOut"}),this._tabs.getAll().forEach((function(t){e._badge.setDefault(t.id)})),this._tabs.clear()},e.prototype.userUpdated=function(e){this.sendMessageToAllTabs({type:"userUpdated",data:e})},e}();t.default=s},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0}),t.isSuccessResponse=function(e){return"value"in e},t.createMessageResponseHandler=function(e,t){e.then((function(e){t({value:e})})).catch((function(e){var n;if(null!=e)if("string"==typeof e||"number"==typeof e)n=e.toString();else if("name"in e||"message"in e||"stack"in e)n=JSON.stringify({name:e.name,message:e.message,stack:e.stack});else try{n=JSON.stringify(e)}catch(e){n="Failed to stringify error."}else n="No error provided.";t({error:n})}))}},function(e,t,n){"use strict";var r;Object.defineProperty(t,"__esModule",{value:!0}),function(e){e.Default="#555555",e.Read="#32CD32",e.Unread="#A9A9A9"}(r||(r={}));var o=function(){function e(){this._animations=[]}return e.prototype.cancelAnimation=function(e){var t=this.getAnimation(e);t&&(console.log("[BrowserActionBadgeApi] cancelling loading animation for tab # "+e),clearInterval(t.interval),this._animations.splice(this._animations.indexOf(t),1))},e.prototype.getAnimation=function(e){return this._animations.find((function(t){return t.tabId===e}))},e.prototype.setDefault=function(e){this.cancelAnimation(e),chrome.browserAction.setBadgeBackgroundColor({color:r.Default,tabId:e}),chrome.browserAction.setBadgeText({tabId:e,text:""})},e.prototype.setLoading=function(e){this.getAnimation(e)||(console.log("[BrowserActionBadgeApi] creating loading animation for tab # "+e),this._animations.push(function(e){var t=0;return chrome.browserAction.setBadgeBackgroundColor({color:r.Default,tabId:e}),{interval:window.setInterval((function(){for(var n="",r=0;r<4;r++)n+=r===t?".":String.fromCharCode(8200);chrome.browserAction.setBadgeText({tabId:e,text:n}),t=++t%5}),150),tabId:e}}(e)))},e.prototype.setReading=function(e,t){console.log("[BrowserActionBadgeApi] setting progress at "+Math.floor(t.percentComplete)+"% for tab # "+e),this.cancelAnimation(e),chrome.browserAction.setBadgeBackgroundColor({color:t.isRead?r.Read:r.Unread,tabId:e}),chrome.browserAction.setBadgeText({tabId:e,text:Math.floor(t.percentComplete)+"%"})},e}();t.default=o},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0}),t.calculateEstimatedReadTime=function(e){return Math.max(1,Math.floor(e/184))}},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var r=n(1),o=n(3),a=n(11),i=n(4),s=n(0),c=n(12),u=n(14);function l(e,t){e.setRequestHeader("X-Readup-Client","web/extension@4.1.0"),t.context&&e.setRequestHeader("X-Readup-Context",t.context)}var d=function(){function e(t){var n=this;this._displayedNotifications=new r.default("displayedNotifications",(function(e){return e.id})),this._displayPreference=new o.default("displayPreference",null),this._blacklist=new o.default("blacklist",{value:[],timestamp:0,expirationTimespan:0}),this._user=new o.default("user",null),chrome.alarms.onAlarm.addListener((function(t){if(n.isAuthenticated())switch(t.name){case e.alarms.checkNotifications:n.checkNotifications();break;case e.alarms.getBlacklist:n.checkBlacklistCache()}})),chrome.notifications&&chrome.notifications.onClicked.addListener((function(e){chrome.tabs.create({url:i.createUrl(Object({protocol:"https",host:"api.readup.com"}),"/Extension/Notification/"+e)})})),this._onDisplayPreferenceChanged=t.onDisplayPreferenceChanged,this._onUserSignedOut=t.onUserSignedOut,this._onUserUpdated=t.onUserUpdated}return e.prototype.checkNotifications=function(){var e=this;chrome.notifications&&chrome.notifications.getAll((function(t){var n=Date.now()-12e4,r=e._displayedNotifications.getAll().reduce((function(e,t){return t.date>=n?e.current.push(t):e.expired.push(t),e}),{current:[],expired:[]}),o=r.current;r.expired.forEach((function(t){e._displayedNotifications.remove(t.id)})),e.fetchJson({method:"GET",path:"/Extension/Notifications",data:{ids:Object.keys(t).concat(o.filter((function(e){return!(e.id in t)})).map((function(e){return e.id})))}}).then((function(t){t.cleared.forEach((function(t){chrome.notifications.clear(t),e._displayedNotifications.remove(t)})),t.created.forEach((function(t){chrome.notifications.create(t.id,{type:"basic",iconUrl:"../icons/icon.svg",title:t.title,message:t.message,isClickable:!0}),e._displayedNotifications.set({id:t.id,date:Date.now()})}));var n=e._user.get();c.areEqual(n,t.user)||(e._user.set(t.user),n&&(console.log("[ServerApi] user updated (notification check)"),e._onUserUpdated(t.user)))})).catch((function(){}))}))},e.prototype.checkBlacklistCache=function(){var e=this;a.isExpired(this._blacklist.get())&&this.fetchJson({method:"GET",path:"/Extension/Blacklist"}).then((function(t){return e._blacklist.set(a.cache(t,719e3))})).catch((function(){}))},e.prototype.fetchJson=function(e){var t=this;return new Promise((function(n,r){var o=new XMLHttpRequest,a=i.createUrl(Object({protocol:"https",host:"api.readup.com"}),e.path);o.withCredentials=!0,o.addEventListener("load",(function(){if(200===this.status||400===this.status){var e=this.getResponseHeader("Content-Type"),o=void 0;e&&e.startsWith("application/json")&&(o=JSON.parse(this.responseText)),200===this.status?o?n(o):n():r(o||["ServerApi XMLHttpRequest load event. Status: "+this.status+" Status text: "+this.statusText+" Response text: "+this.responseText])}else 401===this.status&&(console.log("[ServerApi] user signed out (received 401 response from API server)"),t.userSignedOut(),t._onUserSignedOut()),r(["ServerApi XMLHttpRequest load event. Status: "+this.status+" Status text: "+this.statusText+" Response text: "+this.responseText])})),o.addEventListener("error",(function(){r(["ServerApi XMLHttpRequest error event"])})),"POST"===e.method?(o.open(e.method,a),l(o,e),o.setRequestHeader("Content-Type","application/json"),o.send(JSON.stringify(e.data))):(o.open(e.method,a+s.createQueryString(e.data)),l(o,e),o.send())}))},e.prototype.registerPage=function(e,t){return this.fetchJson({method:"POST",path:"/Extension/GetUserArticle",data:t,id:e})},e.prototype.getComments=function(e){return this.fetchJson({method:"GET",path:"/Articles/ListComments",data:{slug:e}})},e.prototype.postArticle=function(e){return this.fetchJson({method:"POST",path:"/Social/Post",data:e})},e.prototype.postComment=function(e){return this.fetchJson({method:"POST",path:"/Social/Comment",data:e})},e.prototype.postCommentAddendum=function(e){return this.fetchJson({method:"POST",path:"/Social/CommentAddendum",data:e})},e.prototype.postCommentRevision=function(e){return this.fetchJson({method:"POST",path:"/Social/CommentRevision",data:e})},e.prototype.deleteComment=function(e){return this.fetchJson({method:"POST",path:"/Social/CommentDeletion",data:e})},e.prototype.commitReadState=function(e,t){return this.fetchJson({method:"POST",path:"/Extension/CommitReadState",data:t})},e.prototype.isAuthenticated=function(){return null!=this._user.get()},e.prototype.getBlacklist=function(){return this._blacklist.get().value.map((function(e){return new RegExp(e)}))},e.prototype.rateArticle=function(e,t){return this.fetchJson({method:"POST",path:"/Articles/Rate",data:{articleId:e,score:t}})},e.prototype.reportArticleIssue=function(e){return this.fetchJson({method:"POST",path:"/Analytics/ArticleIssueReport",data:e})},e.prototype.requestTwitterBrowserLinkRequestToken=function(){return this.fetchJson({method:"POST",path:"/Auth/TwitterBrowserLinkRequest"})},e.prototype.setStarred=function(e,t){return this.fetchJson({method:"POST",path:"/Extension/SetStarred",data:{articleId:e,isStarred:t}})},e.prototype.logExtensionInstallation=function(e){return this.fetchJson({method:"POST",path:"/Extension/Install",data:e})},e.prototype.userSignedIn=function(e){this._user.set(e.userAccount),this._displayPreference.set(e.displayPreference),this.checkNotifications()},e.prototype.userSignedOut=function(){this._user.clear(),this._displayPreference.clear(),this._displayedNotifications.clear()},e.prototype.userUpdated=function(e){this._user.set(e||null)},e.prototype.getDisplayPreference=function(){var e=this,t=this._displayPreference.get();return this.fetchJson({method:"GET",path:"/UserAccounts/DisplayPreference"}).then((function(n){null!=t&&null!=n&&u.areEqual(t,n)||(n?e.displayPreferenceChanged(n):e.changeDisplayPreference(n=u.getClientDefaultDisplayPreference()),console.log("[ServerApi] display preference changed"),e._onDisplayPreferenceChanged(n))})).catch((function(){console.log("[ServerApi] error fetching display preference")})),t},e.prototype.displayPreferenceChanged=function(e){this._displayPreference.set(e)},e.prototype.changeDisplayPreference=function(e){return this.displayPreferenceChanged(e),this.fetchJson({method:"POST",path:"/UserAccounts/DisplayPreference",data:e})},e.alarms={checkNotifications:"ServerApi.checkNotifications",getBlacklist:"ServerApi.getBlacklist"},e}();t.default=d},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0}),t.cache=function(e,t){return{value:e,timestamp:Date.now(),expirationTimespan:t}},t.isExpired=function(e){return Date.now()-e.timestamp>e.expirationTimespan}},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var r=n(13);t.areEqual=function(e,t){return!(!e||!t)&&(e.id===t.id&&e.name===t.name&&e.email===t.email&&e.dateCreated===t.dateCreated&&e.role===t.role&&e.isEmailConfirmed===t.isEmailConfirmed&&e.timeZoneId===t.timeZoneId&&e.aotdAlert===t.aotdAlert&&e.replyAlertCount===t.replyAlertCount&&e.loopbackAlertCount===t.loopbackAlertCount&&e.postAlertCount===t.postAlertCount&&e.followerAlertCount===t.followerAlertCount&&e.isPasswordSet===t.isPasswordSet&&e.hasLinkedTwitterAccount===t.hasLinkedTwitterAccount)},t.hasAnyAlerts=function(e,t){return!!e&&(null!=t?!!(t&r.default.Aotd&&e.aotdAlert)||(!!(t&r.default.Reply&&e.replyAlertCount)||(!!(t&r.default.Loopback&&e.loopbackAlertCount)||(!!(t&r.default.Post&&e.postAlertCount)||!!(t&r.default.Follower&&e.followerAlertCount)))):!!(e.aotdAlert||e.replyAlertCount||e.loopbackAlertCount||e.postAlertCount||e.followerAlertCount))}},function(e,t,n){"use strict";var r;Object.defineProperty(t,"__esModule",{value:!0}),function(e){e[e.Aotd=1]="Aotd",e[e.Reply=2]="Reply",e[e.Loopback=4]="Loopback",e[e.Post=8]="Post",e[e.Follower=16]="Follower"}(r||(r={})),t.default=r},function(e,t,n){"use strict";var r;function o(){return window.matchMedia("(prefers-color-scheme: dark)").matches?r.Dark:r.Light}Object.defineProperty(t,"__esModule",{value:!0}),function(e){e[e.Light=1]="Light",e[e.Dark=2]="Dark"}(r=t.DisplayTheme||(t.DisplayTheme={})),t.areEqual=function(e,t){return e.hideLinks===t.hideLinks&&e.textSize===t.textSize&&e.theme===t.theme},t.getClientPreferredColorScheme=o,t.getClientDefaultDisplayPreference=function(){return{hideLinks:!0,textSize:1,theme:o()}},t.getDisplayPreferenceChangeMessage=function(e,t){var n;return t.hideLinks!==e.hideLinks?n="Links "+(t.hideLinks?"Disabled":"Enabled"):t.textSize!==e.textSize?n="Text Size "+(t.textSize>e.textSize?"Increased":"Decreased"):t.theme!==e.theme&&(n=(t.theme===r.Dark?"Dark":"Light")+" Theme Enabled"),n}},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var r=n(3),o=function(){function e(e){var t=this;this._tabs=new r.default("webAppTabs",[],"localStorage"),chrome.runtime.onMessage.addListener((function(n,r){var o;if("eventPage"===n.to&&"webAppContentScript"===n.from)switch(console.log("[WebAppApi] received "+n.type+" message from tab # "+(null===(o=r.tab)||void 0===o?void 0:o.id)),n.type){case"articleUpdated":e.onArticleUpdated(n.data);break;case"authServiceLinkCompleted":e.onAuthServiceLinkCompleted(n.data);break;case"commentPosted":e.onCommentPosted(n.data);break;case"commentUpdated":e.onCommentUpdated(n.data);break;case"displayPreferenceChanged":e.onDisplayPreferenceChanged(n.data);break;case"registerPage":t.addTab(r.tab.id);break;case"unregisterPage":t.removeTab(r.tab.id);break;case"userSignedIn":e.onUserSignedIn(n.data);break;case"userSignedOut":e.onUserSignedOut();break;case"userUpdated":e.onUserUpdated(n.data)}return!1}))}return e.prototype.addTab=function(e){var t=this._tabs.get();t.includes(e)||(t.push(e),this._tabs.set(t))},e.prototype.broadcastMessage=function(e){var t=this;this._tabs.get().forEach((function(n){console.log("[WebAppApi] sending "+e.type+" message to tab # "+n),chrome.tabs.sendMessage(n,e,(function(){chrome.runtime.lastError&&(console.log("[WebAppApi] error sending message to tab # "+n+", message: "+chrome.runtime.lastError.message),t.removeTab(n))}))}))},e.prototype.removeTab=function(e){var t=this._tabs.get();t.includes(e)&&(t.splice(t.indexOf(e),1),this._tabs.set(t))},e.prototype.articlePosted=function(e){this.broadcastMessage({type:"articlePosted",data:e})},e.prototype.articleUpdated=function(e){this.broadcastMessage({type:"articleUpdated",data:e})},e.prototype.clearTabs=function(){this._tabs.clear()},e.prototype.commentPosted=function(e){this.broadcastMessage({type:"commentPosted",data:e})},e.prototype.commentUpdated=function(e){this.broadcastMessage({type:"commentUpdated",data:e})},e.prototype.displayPreferenceChanged=function(e){this.broadcastMessage({type:"displayPreferenceChanged",data:e})},e.prototype.injectContentScripts=function(){chrome.tabs.query({url:"https://readup.com/*",status:"complete"},(function(e){chrome.runtime.lastError?console.log("[WebAppApi] error querying tabs"):e.forEach((function(e){var t;(null===(t=e.url)||void 0===t?void 0:t.startsWith("https://readup.com/"))&&(console.log("[WebAppApi] injecting content script into tab # "+e.id),chrome.tabs.executeScript(e.id,{file:"/content-scripts/web-app/bundle.js"}))}))}))},e.prototype.userUpdated=function(e){this.broadcastMessage({type:"userUpdated",data:e})},e}();t.default=o},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var r=function(){function e(e){var t=e.match(/(\d+)\.(\d+)\.(\d+)/);if(!t)throw new Error("Invalid version format");this._major=parseInt(t[1]),this._minor=parseInt(t[2]),this._patch=parseInt(t[3])}return e.greatest=function(){for(var e=[],t=0;t<arguments.length;t++)e[t]=arguments[t];return e.sort((function(e,t){return t.compareTo(e)}))[0]},e.prototype.canUpgradeTo=function(e){return e.major===this._major&&(e.minor>this._minor||e.minor===this._minor&&e.patch>this._patch)},e.prototype.compareTo=function(e){return this._major!==e._major?this._major-e._major:this._minor!==e._minor?this._minor-e._minor:this._patch!==e._patch?this._patch-e._patch:0},e.prototype.toString=function(){return this._major+"."+this._minor+"."+this._patch},Object.defineProperty(e.prototype,"major",{get:function(){return this._major},enumerable:!0,configurable:!0}),Object.defineProperty(e.prototype,"minor",{get:function(){return this._minor},enumerable:!0,configurable:!0}),Object.defineProperty(e.prototype,"patch",{get:function(){return this._patch},enumerable:!0,configurable:!0}),e}();t.default=r},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0}),t.createCommentThread=function(e){return{id:e.comment&&e.comment.id||"",dateCreated:e.date,text:e.comment&&e.comment.text||"",addenda:e.comment&&e.comment.addenda||[],articleId:e.article.id,articleTitle:e.article.title,articleSlug:e.article.slug,userAccount:e.userName,badge:e.badge,parentCommentId:null,dateDeleted:e.dateDeleted,children:[]}}},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0}),t.extensionInstallationRedirectPathCookieKey="extensionInstallationRedirectPath",t.extensionVersionCookieKey="extensionVersion",t.sessionIdCookieKey="sessionId"}]);