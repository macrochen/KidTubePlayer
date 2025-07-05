// temp-tab-content-script.js

// Helper function to get ytInitialPlayerResponse from main world
function getYtInitialPlayerResponseFromMainWorld(videoId) {
  return new Promise((resolve, reject) => {
    const requestId = Math.random().toString(36).substring(7);

    const handleMessage = (event) => {
      if (event.source !== window || !event.data || event.data.source !== "youtube-importer-main-world-script") {
        return;
      }
      if (event.data.type === "YT_INITIAL_PLAYER_RESPONSE" && event.data.requestId === requestId) {
        window.removeEventListener("message", handleMessage);
        resolve(event.data.data); // Now event.data.data contains { ytInitialPlayerResponse, pot }
      }
    };

    window.addEventListener("message", handleMessage);

    // Send message to main world script
    window.postMessage({
      source: "youtube-importer-content-script",
      type: "GET_YT_INITIAL_PLAYER_RESPONSE",
      requestId: requestId,
      videoId: videoId // Pass videoId for potential future use in main world script
    }, "*");

    // Timeout if no response
    setTimeout(() => {
      window.removeEventListener("message", handleMessage);
      reject(new Error("Timeout waiting for ytInitialPlayerResponse from main world."));
    }, 5000); // 5 seconds timeout
  });
}

// Helper function to parse SRT to plain text
function parseSrtToPlainText(srtContent) {
  return srtContent
    .split(/\d+\n\d{2}:\d{2}:\d{2},\d{3} --> \d{2}:\d{2}:\d{2},\d{3}\n/)
    .map(block => block.replace(/<[^>]*>/g, '').trim())
    .filter(block => block.length > 0)
    .join(' ');
}

(async () => {
  console.log("Temp Tab Content: Script started.");
  const videoId = new URL(window.location.href).searchParams.get('v');

  if (!videoId) {
    console.error("Temp Tab Content: No video ID found in URL.");
    chrome.runtime.sendMessage({ action: "transcriptResult", success: false, error: "No video ID found in URL." });
    return;
  }

  try {
    let ytResponseData = null; // This will now contain { ytInitialPlayerResponse, pot }

    // Retry mechanism for getting ytInitialPlayerResponse from main world
    const MAX_YT_RETRIES = 10; // Max retries for ytInitialPlayerResponse
    const YT_RETRY_INTERVAL = 500; // Interval for retries
    for (let i = 0; i < MAX_YT_RETRIES; i++) {
      try {
        ytResponseData = await getYtInitialPlayerResponseFromMainWorld(videoId);
        if (ytResponseData && ytResponseData.ytInitialPlayerResponse) {
          console.log(`Temp Tab Content: Successfully got ytInitialPlayerResponse on attempt ${i + 1}.`);
          break;
        }
      } catch (e) {
        console.warn(`Temp Tab Content: Attempt ${i + 1} to get ytInitialPlayerResponse failed: ${e.message}. Retrying...`);
      }
      await new Promise(r => setTimeout(r, YT_RETRY_INTERVAL));
    }

    if (!ytResponseData || !ytResponseData.ytInitialPlayerResponse) {
      throw new Error("Failed to get ytInitialPlayerResponse after multiple attempts.");
    }

    console.log("Temp Tab Content: Got ytResponseData:", ytResponseData);
    const ytInitialPlayerResponse = ytResponseData.ytInitialPlayerResponse;
    const capturedPot = ytResponseData.pot; // Get the captured pot

    // Strict check: if pot is empty, throw error and stop
    if (!capturedPot) {
      console.error("Temp Tab Content: Captured pot is empty. Cannot proceed with download.");
      chrome.runtime.sendMessage({ action: "transcriptResult", success: false, error: "无法获取到字幕下载所需的 'pot' 参数。" });
      return;
    }

    const captionsData = ytInitialPlayerResponse.captions;
    if (!captionsData || !captionsData.playerCaptionsTracklistRenderer || !captionsData.playerCaptionsTracklistRenderer.captionTracks) {
      console.log("Temp Tab Content: No captions data found in ytInitialPlayerResponse.");
      chrome.runtime.sendMessage({ action: "transcriptResult", success: true, data: "", message: "No captions data found in ytInitialPlayerResponse." });
      return;
    }

    const captionTracks = captionsData.playerCaptionsTracklistRenderer.captionTracks;
    let englishCaptionTrack = captionTracks.find(track => track.languageCode === 'en' || track.languageCode.startsWith('en-'));
    if (!englishCaptionTrack) {
      englishCaptionTrack = captionTracks.find(track => track.vssId && track.vssId.startsWith('.en'));
    }

    if (!englishCaptionTrack) {
      console.log("Temp Tab Content: No English captions found for this video.");
      chrome.runtime.sendMessage({ action: "transcriptResult", success: true, data: "", message: "No English captions found for this video." });
      return;
    }

    let subtitleUrl = englishCaptionTrack.baseUrl;
    console.log("Temp Tab Content: Found English caption track baseUrl:", subtitleUrl);

    // Append captured pot to the subtitle URL if available and not already present
    if (capturedPot && !subtitleUrl.includes("pot=")) {
      const urlObj = new URL(subtitleUrl);
      urlObj.searchParams.set("pot", capturedPot);
      urlObj.searchParams.set("c", "WEB");
      urlObj.searchParams.set("fmt", "srt"); 
      subtitleUrl = urlObj.toString();
      console.log("Temp Tab Content: Appended captured pot to subtitleUrl:", subtitleUrl);
    }

    let srtContent = "";
    let downloadSuccess = false;

    // Try downloading from the baseUrl first
    try {
      const urlToFetch = new URL(subtitleUrl);// Ensure fmt=srt is set
      const finalDownloadUrl = urlToFetch.toString();
      console.log("Temp Tab Content: Attempting to download SRT from:", finalDownloadUrl);
      const response = await fetch(finalDownloadUrl);
      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`HTTP error! status: ${response.status}, body: ${errorText.substring(0, 200)}`);
      }
      srtContent = await response.text();
      if (srtContent.trim() !== "") {
        downloadSuccess = true;
        console.log("Temp Tab Content: Successfully downloaded SRT.");
      } else {
        console.warn("Temp Tab Content: Downloaded SRT is empty from URL:", finalDownloadUrl);
      }
    } catch (e) {
      console.error("Temp Tab Content: Failed to download SRT from URL:", subtitleUrl, "Error:", e);
    }

    if (!downloadSuccess || srtContent.trim() === "") {
      console.error("Temp Tab Content: Failed to download any SRT content or content is empty after all attempts. Final URL attempted:", subtitleUrl);
      chrome.runtime.sendMessage({ action: "transcriptResult", success: false, error: "无法下载字幕内容或内容为空。" });
      return;
    }

    const fullSubtitleText = parseSrtToPlainText(srtContent);
    console.log("Temp Tab Content: Successfully fetched and parsed subtitle. Sending result to background.");
    chrome.runtime.sendMessage({ action: "transcriptResult", success: true, data: fullSubtitleText, message: "Subtitle fetched successfully." });

  } catch (error) {
    console.error("Temp Tab Content: Error in main logic:", error);
    chrome.runtime.sendMessage({ action: "transcriptResult", success: false, error: error.message });
  }
})();