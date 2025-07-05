// youtube-main-world-script.js

// 字幕抓取功能已禁用。
// 如果需要重新启用，请取消注释以下代码块，并修改 content.js 和 background.js 中的相关逻辑。

(function() {
  console.log("YouTube Main World Script: Injected.");

  // Variable to store the captured pot value
  let capturedPot = "";

  // console.log("YouTube Main World Script: Attempting to override XMLHttpRequest.prototype.open.");
  // const originalOpen = XMLHttpRequest.prototype.open;
  // XMLHttpRequest.prototype.open = function (
  //   method,
  //   url,
  //   async,
  //   username,
  //   password,
  // ) {
  //   console.log("YouTube Main World Script: XMLHttpRequest.open called with URL:", url);

  //   // Check if this is a timedtext API request
  //   if (
  //     typeof url === "string" &&
  //     url.includes("https://www.youtube.com/api/timedtext")
  //   ) {
  //     console.log("YouTube Main World Script: Detected timedtext API request.");
  //     try {
  //       const urlObj = new URL(url);
  //       const potParam = urlObj.searchParams.get("pot");
  //       if (potParam) {
  //         capturedPot = potParam;
  //         console.log("YouTube Main World Script: Captured pot parameter from URL:", potParam);
  //       } else {
  //         console.log("YouTube Main World Script: timedtext URL found, but 'pot' parameter is missing in URL.", url);
  //       }
  //     } catch (error) {
  //       console.error("YouTube Main World Script: Error parsing timedtext URL:", error);
  //     }
  //   } else {
  //     console.log("YouTube Main World Script: Not a timedtext API request.");
  //   }

  //   // Call the original open method
  //   return originalOpen.call(
  //     this,
  //     method,
  //     url,
  //     async ?? true,
  //     username,
  //     password,
  //   );
  // };
  // console.log("YouTube Main World Script: XMLHttpRequest.prototype.open override complete.");

  // console.log("YouTube Main World Script: Attempting to override XMLHttpRequest.prototype.send.");
  // const originalSend = XMLHttpRequest.prototype.send;
  // XMLHttpRequest.prototype.send = function(body) {
  //   console.log("YouTube Main World Script: XMLHttpRequest.send called.");
  //   // Check if body contains pot (e.g., if it's a JSON string)
  //   if (typeof body === 'string' && body.includes('pot')) {
  //     try {
  //       const parsedBody = JSON.parse(body);
  //       if (parsedBody && parsedBody.pot) {
  //         capturedPot = parsedBody.pot;
  //         console.log("YouTube Main World Script: Captured pot parameter from request body:", capturedPot);
  //       }
  //     } catch (e) {
  //       // Not a JSON body, or parsing failed
  //       console.log("YouTube Main World Script: Request body is not JSON or does not contain pot.");
  //     }
  //   }

  //   // Call the original send method
  //   return originalSend.apply(this, arguments);
  // };
  // console.log("YouTube Main World Script: XMLHttpRequest.prototype.send override complete.");

  // Listen for messages from the content script
  // window.addEventListener("message", async function(event) {
  //   // Only accept messages from our own content script
  //   if (event.source !== window || !event.data || event.data.source !== "youtube-importer-content-script") {
  //     return;
  //   }

  //   if (event.data.type === "GET_YT_INITIAL_PLAYER_RESPONSE") {
  //     console.log("YouTube Main World Script: Received request for ytInitialPlayerResponse.");
  //     var ytInitialPlayerResponse = window.ytInitialPlayerResponse || null;

  //     // Wait for pot to be captured, or timeout
  //     const MAX_POT_WAIT_RETRIES = 20; // Max 10 seconds wait for pot
  //     const POT_WAIT_INTERVAL = 500;
  //     let potWaitRetries = 0;

  //     while (!capturedPot && potWaitRetries < MAX_POT_WAIT_RETRIES) {
  //       console.log(`YouTube Main World Script: Waiting for pot... Attempt ${potWaitRetries + 1}/${MAX_POT_WAIT_RETRIES}`);
  //       await new Promise(resolve => setTimeout(resolve, POT_WAIT_INTERVAL));
  //       potWaitRetries++;
  //     }

  //     // Send the response back to the content script
  //     window.postMessage({
  //       source: "youtube-importer-main-world-script",
  //       type: "YT_INITIAL_PLAYER_RESPONSE",
  //       data: {
  //         ytInitialPlayerResponse: ytInitialPlayerResponse,
  //         pot: capturedPot // Include the captured pot value
  //       },
  //       requestId: event.data.requestId
  //     }, "*");
  //   }
  // });

  // Optional: Try to trigger captions if not already active (heuristic from cpdown)
  // This might help in cases where ytInitialPlayerResponse.captions is not fully populated yet
  // var subtitleButton = document.querySelector("button.ytp-subtitles-button");
  // if (subtitleButton) {
  //   console.log("YouTube Main World Script: Attempting to click subtitle button.");
  //   subtitleButton.click();
  //   setTimeout(function() {
  //     subtitleButton.click(); // Click again to toggle off if it was toggled on
  //   }, 200);
  // }

})();