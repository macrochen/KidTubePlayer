// background.js

// Listener for the extension icon click
chrome.action.onClicked.addListener((tab) => {
  if (tab.url.includes("youtube.com") || tab.url.includes("bilibili.com")) {
    console.log("Background: Action clicked. Toggling selection mode.");
    chrome.tabs.sendMessage(tab.id, { action: "toggleSelectionMode" });
  }
});

const responseCallbackMap = new Map();

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  console.log("Background: Received message:", request.action, "from sender:", sender);

  // 字幕抓取功能已禁用。
  // 如果需要重新启用，请取消注释以下代码块，并修改 content.js 中的相关逻辑。
  // if (request.action === "fetchTranscript") {
  //   console.log(`Background: Handling fetchTranscript request for videoId: ${request.videoId}`);
  //   handleFetchTranscriptRequest(request.videoId, sendResponse);
  //   return true; // Keep message channel open for async response
  // }

  if (request.action === "transcriptResult") {
    console.log("Background: Received transcriptResult from temp-tab-content-script.", request);
    const tabId = sender.tab?.id;
    if (tabId && responseCallbackMap.has(tabId)) {
      const originalSendResponse = responseCallbackMap.get(tabId);
      originalSendResponse(request); // Forward the result to the original caller (content.js)
      responseCallbackMap.delete(tabId);
      console.log(`Background: Closing tab ${tabId} after receiving transcriptResult.`);
      chrome.tabs.remove(tabId); // Close the temporary tab
    } else {
        console.error("Background: Received a transcriptResult from an unknown tab or no callback found.", sender);
        if (tabId) {
            console.log(`Background: Attempting to close unknown tab ${tabId}.`);
            chrome.tabs.remove(tabId);
        }
    }
  }
});

function handleFetchTranscriptRequest(videoId, sendResponse) {
  const url = `https://www.youtube.com/watch?v=${videoId}`;
  console.log(`Background: Creating temporary tab for video: ${url}`);

  chrome.tabs.create({ url: url, active: false }, (tab) => {
    console.log(`Background: Temporary tab created with ID: ${tab.id}`);
    responseCallbackMap.set(tab.id, sendResponse);

    const listener = async (tabId, changeInfo, updatedTab) => {
      // Inject main world script at document_start (loading phase)
      if (tabId === tab.id && changeInfo.status === 'loading') { 
        console.log(`Background: Tab ${tabId} is loading. Injecting youtube-main-world-script.js at document_start.`);
        try {
          await chrome.scripting.executeScript({
            target: { tabId: tab.id },
            files: ['youtube-main-world-script.js'],
            world: 'MAIN', // Inject into the main world
            injectImmediately: true, // Run at document_start
          });
          console.log(`Background: youtube-main-world-script.js injected into tab ${tabId} (MAIN world).`);

          // Add a small delay to allow the main world script to initialize and capture pot
          await new Promise(resolve => setTimeout(resolve, 500)); // 500ms delay

          // Now inject the temp-tab-content-script.js into the isolated world
          console.log(`Background: Tab ${tabId} is loading. Injecting temp-tab-content-script.js.`);
          await chrome.scripting.executeScript({
            target: { tabId: tab.id },
            files: ['temp-tab-content-script.js'],
            world: 'ISOLATED', // Default, but explicitly stated for clarity
          });
          console.log(`Background: temp-tab-content-script.js injected into tab ${tabId} (ISOLATED world).`);

        } catch (err) {
          console.error(`Background: Failed to inject scripts into tab ${tabId}`, err);
          const originalSendResponse = responseCallbackMap.get(tabId);
          if (originalSendResponse) {
            originalSendResponse({ success: false, error: err.message });
            responseCallbackMap.delete(tabId);
          }
          console.log(`Background: Closing tab ${tabId} due to injection failure.`);
          // chrome.tabs.remove(tabId); // Temporarily disabled for debugging
        }
        chrome.tabs.onUpdated.removeListener(listener); // Remove listener after injection attempt
      }
    };
    chrome.tabs.onUpdated.addListener(listener);
  });
}