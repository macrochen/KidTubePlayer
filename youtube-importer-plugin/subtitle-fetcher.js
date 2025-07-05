// subtitle-fetcher.js

(async () => {
  console.log("Subtitle Fetcher: Script injected and starting execution.");
  console.log("Subtitle Fetcher: Initial window.ytInitialPlayerResponse state:", !!window.ytInitialPlayerResponse);

  const MAX_RETRIES = 60; // 增加最大重试次数到 60 (30秒)
  const RETRY_INTERVAL = 500; // 每次重试间隔（毫秒）
  let retries = 0;

  // 辅助函数：将 SRT 格式解析为纯文本
  function parseSrtToPlainText(srtContent) {
    // 简单的解析：移除时间戳和序列号，并移除 HTML 标签
    return srtContent
      .split(/\d+\n\d{2}:\d{2}:\d{2},\d{3} --> \d{2}:\d{2}:\d{2},\d{3}\n/)
      .map(block => block.replace(/<[^>]*>/g, '').trim()) // 移除 HTML 标签
      .filter(block => block.length > 0)
      .join(' ');
  }

  const findAndExtractCaptions = async () => {
    try {
      console.log(`Subtitle Fetcher: Attempt ${retries + 1}/${MAX_RETRIES}`);
      const videoId = new URL(window.location.href).searchParams.get('v');
      if (!videoId) {
        console.error("Subtitle Fetcher: 无法从 URL 中提取视频 ID。立即失败。");
        chrome.runtime.sendMessage({ action: "transcriptResult", success: false, error: "无法从 URL 中提取视频 ID。" });
        return true; // 停止重试
      }

      let englishCaptionTrack = null;
      let subtitleUrl = null;

      // --- 尝试 1：从 window.ytInitialPlayerResponse 获取字幕信息 ---
      console.log("Subtitle Fetcher: 尝试从 ytInitialPlayerResponse 获取字幕信息。");
      console.log("Subtitle Fetcher: Current window.ytInitialPlayerResponse state:", !!window.ytInitialPlayerResponse);
      if (window.ytInitialPlayerResponse) {
        console.log("Subtitle Fetcher: ytInitialPlayerResponse 对象存在。继续检查 captions 属性。");
        console.log("Subtitle Fetcher: Current ytInitialPlayerResponse.captions state:", !!window.ytInitialPlayerResponse.captions);
        if (window.ytInitialPlayerResponse.captions) {
          console.log("Subtitle Fetcher: ytInitialPlayerResponse.captions 存在。开始处理字幕轨道。");
          const captionsData = window.ytInitialPlayerResponse.captions;
          const captionTracks = captionsData.playerCaptionsTracklistRenderer.captionTracks;

          if (captionTracks && captionTracks.length > 0) {
            console.log(`Subtitle Fetcher: 找到 ${captionTracks.length} 个字幕轨道。`);
            englishCaptionTrack = captionTracks.find(track => track.languageCode === 'en' || track.languageCode.startsWith('en-'));
            if (!englishCaptionTrack) {
              englishCaptionTrack = captionTracks.find(track => track.vssId && track.vssId.startsWith('.en'));
            }

            if (englishCaptionTrack) {
              subtitleUrl = englishCaptionTrack.baseUrl;
              console.log("Subtitle Fetcher: 从 ytInitialPlayerResponse 找到英文字幕轨道。baseUrl: ", subtitleUrl);

              // 严格检查 'pot' 参数
              console.log("Subtitle Fetcher: Checking for 'pot=' in subtitleUrl:", subtitleUrl.includes("pot="));
              if (!subtitleUrl.includes("pot=")) {
                console.error("Subtitle Fetcher: 找到的字幕 URL 中缺少 'pot' 参数。无法下载。立即失败。");
                chrome.runtime.sendMessage({ action: "transcriptResult", success: false, error: "字幕 URL 中缺少 'pot' 参数，无法下载。" });
                return true; // 停止重试，严格失败
              }

              // 尝试模拟点击字幕按钮以确保 'pot' 参数加载（启发式方法）
              const subtitleButton = document.querySelector("button.ytp-subtitles-button");
              if (subtitleButton) {
                console.log("Subtitle Fetcher: 尝试点击字幕按钮以确保 'pot' 参数加载。");
                subtitleButton.click();
                await new Promise(r => setTimeout(r, 200)); // 给予页面一些时间
                subtitleButton.click(); // 再次点击以关闭（如果打开了）
              }

            } else {
              // ytInitialPlayerResponse 中未找到英文字幕轨道
              console.error("Subtitle Fetcher: ytInitialPlayerResponse 中未找到英文字幕轨道。立即失败。");
              chrome.runtime.sendMessage({ action: "transcriptResult", success: false, error: "ytInitialPlayerResponse 中未找到英文字幕轨道。" });
              return true; // 停止重试，严格失败
            }
          } else {
            // ytInitialPlayerResponse 中没有字幕轨道
            console.error("Subtitle Fetcher: ytInitialPlayerResponse 中没有字幕轨道。立即失败。");
            chrome.runtime.sendMessage({ action: "transcriptResult", success: false, error: "ytInitialPlayerResponse 中没有字幕轨道。" });
            return true; // 停止重试，严格失败
          }
        } else {
          console.log("Subtitle Fetcher: ytInitialPlayerResponse.captions 不存在。继续重试，等待 captions 属性加载。");
          return false; // 继续重试，等待 captions 属性加载
        }
      } else {
        console.log("Subtitle Fetcher: window.ytInitialPlayerResponse 不存在。继续重试，等待 ytInitialPlayerResponse 对象加载。");
        return false; // 继续重试，等待 ytInitialPlayerResponse 对象加载
      }

      // --- 如果 subtitleUrl 可用，则继续获取和处理字幕 ---
      if (subtitleUrl) {
        let transcriptSrt = "";
        const urlObj = new URL(subtitleUrl);
        urlObj.searchParams.set("fmt", "srt"); // 确保请求 SRT 格式

        console.log(`Subtitle Fetcher: 尝试从 URL 获取 SRT: ${urlObj.toString()}`);
        try {
          const response = await fetch(urlObj.toString());
          if (!response.ok) {
            const errorBody = await response.text();
            throw new Error(`HTTP error! status: ${response.status}, body: ${errorBody.substring(0, 200)}`);
          }
          transcriptSrt = await response.text();
        } catch (e) {
          console.error("Subtitle Fetcher: 从 URL 获取 SRT 失败:", e);
          chrome.runtime.sendMessage({ action: "transcriptResult", success: false, error: `下载字幕失败: ${e.message}` });
          return true; // 停止重试，下载错误
        }

        if (transcriptSrt.trim() === "") {
          console.error("Subtitle Fetcher: 获取到的字幕内容为空。立即失败。");
          chrome.runtime.sendMessage({ action: "transcriptResult", success: false, error: "获取到的字幕内容为空。" });
          return true; // 停止重试，内容为空
        }

        const fullText = parseSrtToPlainText(transcriptSrt);

        console.log("Subtitle Fetcher: 成功获取并解析字幕。发送结果。");
        chrome.runtime.sendMessage({ action: "transcriptResult", success: true, data: fullText });
        return true;
      }

    } catch (error) {
      console.error("Subtitle Fetcher 提取过程中发生未捕获的错误:", error.message);
      chrome.runtime.sendMessage({ action: "transcriptResult", success: false, error: `未捕获的错误: ${error.message}` });
      return true; // 停止重试，未捕获错误
    }
  };

  // 设置定时器，定期尝试查找和提取字幕
  const intervalId = setInterval(async () => {
    if (await findAndExtractCaptions()) {
      clearInterval(intervalId); // 成功或严格失败后清除定时器
    } else if (retries >= MAX_RETRIES) {
      console.error("Subtitle Fetcher: 达到最大重试次数。字幕数据未找到或无法处理。立即失败。");
      clearInterval(intervalId); // 达到最大重试次数后清除定时器
      chrome.runtime.sendMessage({ action: "transcriptResult", success: false, error: "达到最大重试次数，字幕数据未找到或无法处理。" });
    }
    retries++;
  }, RETRY_INTERVAL);
})();