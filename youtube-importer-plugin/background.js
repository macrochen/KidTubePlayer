// 当用户点击浏览器右上角的插件图标时
chrome.action.onClicked.addListener((tab) => {
  // 关键修复：检查 URL 是否包含 "youtube.com" 或 "bilibili.com"
  // 这样无论在哪一个网站，点击图标都能激活插件
  if (tab.url.includes("youtube.com") || tab.url.includes("bilibili.com")) {
    // 向当前页面的 content script 发送一个消息，告诉它切换“选择模式”
    chrome.scripting.executeScript({
      target: { tabId: tab.id },
      function: toggleSelectionMode,
    });
  }
});

// 这个函数将被注入到页面中执行
function toggleSelectionMode() {
  // window.toggleApp 是我们将在 content.js 中定义的一个全局函数
  if (window.toggleApp) {
    window.toggleApp();
  }
}
