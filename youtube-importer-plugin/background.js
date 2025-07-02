// 当用户点击浏览器右上角的插件图标时
chrome.action.onClicked.addListener((tab) => {
  // 确保我们在一个 YouTube 页面上
  if (tab.url.includes("youtube.com")) {
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
