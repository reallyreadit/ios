!function(e){var t={};function n(a){if(t[a])return t[a].exports;var o=t[a]={i:a,l:!1,exports:{}};return e[a].call(o.exports,o,o.exports,n),o.l=!0,o.exports}n.m=e,n.c=t,n.d=function(e,t,a){n.o(e,t)||Object.defineProperty(e,t,{enumerable:!0,get:a})},n.r=function(e){"undefined"!=typeof Symbol&&Symbol.toStringTag&&Object.defineProperty(e,Symbol.toStringTag,{value:"Module"}),Object.defineProperty(e,"__esModule",{value:!0})},n.t=function(e,t){if(1&t&&(e=n(e)),8&t)return e;if(4&t&&"object"==typeof e&&e&&e.__esModule)return e;var a=Object.create(null);if(n.r(a),Object.defineProperty(a,"default",{enumerable:!0,value:e}),2&t&&"string"!=typeof e)for(var o in e)n.d(a,o,function(t){return e[t]}.bind(null,o));return a},n.n=function(e){var t=e&&e.__esModule?function(){return e.default}:function(){return e};return n.d(t,"a",t),t},n.o=function(e,t){return Object.prototype.hasOwnProperty.call(e,t)},n.p="",n(n.s=0)}([function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var a=n(1),o=window.reallyreadit.alertContentScript;a.default();var r=document.createElement("link");r.rel="stylesheet",r.href=chrome.runtime.getURL("/content-scripts/alert/bundle.css");var i=document.createElement("div");function s(){i.dataset.com_readup_theme=document.documentElement.dataset.com_readup_theme}i.style.position="fixed",i.style.top="0",i.style.right="0",i.style.width="0",i.style.height="0",i.style.margin="0",i.style.padding="0",i.style.transform="none",i.style.zIndex="2147483647",s(),window.addEventListener("com.readup.themechange",(function(){s()}));var l=document.body.appendChild(i).attachShadow({mode:"open"});l.append(r),o.display=function(){o.isActive||(l.append(function(){var e=document.createElement("img");e.alt="Readup Logo",e.className="logo-light",e.src=chrome.runtime.getURL("/content-scripts/ui/images/logo.svg");var t=document.createElement("img");t.alt="Readup Logo",t.className="logo-dark",t.src=chrome.runtime.getURL("/content-scripts/ui/images/logo-white.svg");var n=document.createElement("div");n.classList.add("prompt-text"),n.innerHTML=o.alertContent;var a=document.createElement("button");a.textContent="Dismiss",a.addEventListener("click",(function(){i.classList.add("popping-out")}));var r=document.createElement("div");r.classList.add("button-container"),r.append(a);var i=document.createElement("div");return i.classList.add("alert"),i.addEventListener("animationend",(function(e){"alert-pop-out"===e.animationName&&(o.isActive=!1,i.remove())})),i.append(e,t,n,r),i}()),o.isActive=!0)},o.display()},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var a=[{family:"Cambria (bold)",fileName:"cambria-bold.ttf"},{family:"Cambria (regular)",fileName:"cambria-regular.ttf"},{family:"Museo Sans (100)",fileName:"museo-sans-100.ttf"},{family:"Museo Sans (300)",fileName:"museo-sans-300.ttf"},{family:"Museo Sans (500)",fileName:"museo-sans-500.ttf"},{family:"Museo Sans (700)",fileName:"museo-sans-700.ttf"},{family:"Museo Sans (900)",fileName:"museo-sans-900.ttf"}];t.default=function(){var e=document.createElement("style");e.type="text/css",e.textContent=a.map((function(e){return"@font-face { font-family: '"+e.family+"'; src: url('"+chrome.runtime.getURL("/content-scripts/ui/fonts/"+e.fileName)+"'); }"})).join("\n"),document.body.append(e)}}]);