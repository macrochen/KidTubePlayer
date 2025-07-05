// content.js

// --- Global State Management ---
let selectionModeActive = false;
let selectedVideos = [];
let currentPlatform = '';

// --- Initialization ---
// Determine the current platform (YouTube or Bilibili)
if (window.location.hostname.includes('youtube.com')) {
    currentPlatform = 'youtube';
} else if (window.location.hostname.includes('bilibili.com')) {
    currentPlatform = 'bilibili';
}

/**
 * Main toggle function to activate or deactivate selection mode.
 */
function toggleApp() {
  selectionModeActive = !selectionModeActive;
  if (selectionModeActive) {
    console.log(`Importer: Activating selection mode on ${currentPlatform}`);
    createAppUI();
    scanForVideos();
    observeDOMChanges();
  } else {
    console.log("Importer: Deactivating selection mode");
    destroyAppUI();
    if (observer) observer.disconnect();
  }
}

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  console.log("Content: Received message:", request.action, "from sender:", sender);
  if (request.action === "toggleSelectionMode") {
    toggleApp();
  }
});

/**
 * Creates the plugin's user interface.
 */
function createAppUI() {
  if (document.getElementById('importer-panel')) return;
  const appContainer = document.createElement('div');
  appContainer.id = 'importer-panel';
  appContainer.innerHTML = `
    <div class="panel-header">
      <h3>已选视频列表 (<span id="video-count">0</span>)</h3>
      <button id="close-panel-btn">×</button>
    </div>
    <div id="selected-list" class="panel-body">
      <p class="empty-state">尚未选择任何视频</p>
    </div>
    <div class="panel-footer">
      <button id="export-json-btn" class="disabled">导出 JSON</button>
    </div>
  `;
  document.body.appendChild(appContainer);

  document.getElementById('export-json-btn').addEventListener('click', exportJSON);
  document.getElementById('close-panel-btn').addEventListener('click', toggleApp);
}

/**
 * Destroys the plugin's UI.
 */
function destroyAppUI() {
  document.getElementById('importer-panel')?.remove();
  document.querySelectorAll('.importer-add-btn').forEach(btn => btn.remove());
}

/**
 * Scans for videos on the page.
 */
function scanForVideos() {
    const selector = currentPlatform === 'youtube'
        ? 'ytd-rich-item-renderer, ytd-video-renderer, ytd-grid-video-renderer'
        : '.bili-video-card'; // Bilibili video card selector
    document.querySelectorAll(selector).forEach(videoEl => addPlusButton(videoEl));
}

  /**
 * Adds a "+ Add" button to a single video element.
 */
function addPlusButton(videoEl) {
  if (videoEl.querySelector('.importer-add-btn')) return;
  const btn = document.createElement('button');
  btn.className = 'importer-add-btn';
  btn.textContent = '+ 添加';
  
  const thumbnailContainer = currentPlatform === 'youtube'
      ? videoEl.querySelector('#thumbnail')
      : videoEl.querySelector('.bili-video-card__image');
      
  if (thumbnailContainer) {
    thumbnailContainer.style.position = 'relative';
    thumbnailContainer.appendChild(btn);
    btn.addEventListener('click', async (e) => {
      e.preventDefault();
      e.stopPropagation();
      const videoData = extractVideoData(videoEl);

      if (!videoData) {
        btn.textContent = '信息不全';
        btn.classList.add('error');
        console.error("Content: Video data extraction failed.");
        return;
      }

      btn.textContent = '下载字幕...';
      btn.disabled = true;
      btn.classList.add('loading');

      try {
        if (videoData.platform === 'youtube') {
          // 字幕抓取功能已禁用。
          // 如果需要重新启用，请取消注释以下代码块，并修改 background.js 中的相关逻辑。
          // console.log(`Content: Sending message to background to fetch transcript for ${videoData.id}`);
          // const response = await chrome.runtime.sendMessage({ action: "fetchTranscript", videoId: videoData.id });
          // if (response.success) {
          //   videoData.fullSubtitleText = response.data;
          //   console.log(`Content: Subtitle fetched successfully for ${videoData.id}`);
          // } else {
          //   console.error("Content: Received error from background:", response.error);
          //   throw new Error(response.error || "Unknown error fetching transcript from background");
          // }
          videoData.fullSubtitleText = ""; // 禁用字幕抓取，直接设置为空
          console.log(`Content: Subtitle fetching is disabled. fullSubtitleText set to empty for ${videoData.id}.`);
        } else {
          // For Bilibili or other platforms, we assume no subtitles for now.
          videoData.fullSubtitleText = "";
        }
        
        addVideoToList(videoData);
        btn.textContent = '✓ 已添加';
        btn.classList.remove('loading');
        btn.classList.add('added');
        // The button remains disabled after successfully adding.

      } catch (error) {
        console.error(`Content: Final error for ${videoData.id}:`, error);
        btn.textContent = '获取失败'; // Update UI to show failure
        btn.classList.remove('loading');
        btn.classList.add('error');
        btn.disabled = false; // Re-enable the button to allow retrying
      }
    });
  }
}
        

/**
 * Data extraction "manager" function.
 */
function extractVideoData(videoEl) {
    if (currentPlatform === 'youtube') {
        return extractYouTubeVideoData(videoEl);
    } else if (currentPlatform === 'bilibili') {
        return extractBilibiliVideoData(videoEl);
    }
    return null;
}

/**
 * Extracts YouTube video data.
 */
function extractYouTubeVideoData(videoEl) {
    try {
        const titleLink = videoEl.querySelector('#video-title-link') || videoEl.querySelector('#video-title');
        const videoId = new URL(titleLink.href).searchParams.get('v');
        const title = titleLink.getAttribute('title');
        const author = videoEl.querySelector('ytd-channel-name #text')?.textContent.trim();
        const authorAvatarURL = videoEl.querySelector('#avatar img')?.src || null;
        const thumbnailURL = videoEl.querySelector('#thumbnail img')?.src || null;
        const metadataSpans = videoEl.querySelectorAll('#metadata-line span');
        const viewCount = parseViews(metadataSpans[0]?.textContent || '0');
        const uploadDate = parseDate(metadataSpans[1]?.textContent || '现在');

        return { platform: 'youtube', id: videoId, title, author, viewCount, uploadDate, authorAvatarURL, thumbnailURL };
    } catch (e) { console.error("YouTube data extraction failed", e, videoEl); return null; }
}

/**
 * Extracts Bilibili video data.
 */
function extractBilibiliVideoData(videoEl) {
    try {
        const link = videoEl.querySelector('.bili-video-card__info--right > a');
        const bvid = new URL(link.href).pathname.split('/')[2];
        const title = videoEl.querySelector('.bili-video-card__info--tit')?.textContent.trim(); //link.getAttribute('title');
        const author = videoEl.querySelector('.bili-video-card__info--author')?.textContent.trim();
        const authorAvatarURL = cleanURL(videoEl.querySelector('.bili-video-card__up > .bili-avatar img')?.src);
        const thumbnailURL = cleanURL(videoEl.querySelector('.bili-video-card__image img')?.src);
        const viewCount = parseViews(videoEl.querySelector('.bili-video-card__stats--item')?.textContent || '0');
        const uploadDate = parseDate(videoEl.querySelector('.bili-video-card__info--date')?.textContent || '现在');

        return { platform: 'bilibili', id: bvid, title, author, viewCount, uploadDate, authorAvatarURL, thumbnailURL };
    } catch (e) { console.error("Bilibili data extraction failed", e, videoEl); return null; }
}

function addVideoToList(videoData) {
  if (selectedVideos.some(v => v.id === videoData.id && v.platform === videoData.platform)) return;
  selectedVideos.push(videoData);
  updateListView();
}

function removeVideoFromList(videoId, platform) {
    selectedVideos = selectedVideos.filter(v => !(v.id === videoId && v.platform === platform));
    updateListView();
    // ... (logic to re-enable the add button for this video if needed)
}

function updateListView() {
  const listEl = document.getElementById('selected-list');
  const countEl = document.getElementById('video-count');
  const exportBtn = document.getElementById('export-json-btn');

  countEl.textContent = selectedVideos.length;

  if (selectedVideos.length === 0) {
    listEl.innerHTML = '<p class="empty-state">尚未选择任何视频</p>';
    exportBtn.classList.add('disabled');
  }
  else {
    listEl.innerHTML = selectedVideos.map(v => `
      <div class="list-item" data-id="${v.id}" data-platform="${v.platform}">
        <span class="platform-icon ${v.platform}">${v.platform.charAt(0).toUpperCase()}</span>
        <span>${v.title}</span>
        <button class="remove-btn">×</button>
      </div>
    `).join('');
    exportBtn.classList.remove('disabled');

    listEl.querySelectorAll('.remove-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        const item = btn.parentElement;
        removeVideoFromList(item.dataset.id, item.dataset.platform);
      });
    });
  }
}

function exportJSON() {
  if (selectedVideos.length === 0) return;
  const jsonString = JSON.stringify(selectedVideos, null, 2);
  const blob = new Blob([jsonString], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = 'videos.json';
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}


// --- Helper Functions ---
function cleanURL(url) {
    if (!url) return null;
    return url.startsWith('//') ? 'https:' + url : url;
}

function parseViews(text) {
    text = text.toLowerCase().replace(/,/g, '').replace('次观看', '').replace(' views', '').trim();
    let number = parseFloat(text);
    if (text.includes('万')) number *= 10000;
    if (text.includes('亿')) number *= 100000000;
    return Math.round(number);
}

function parseDate(text) {
    const now = new Date();
    
    // 检查是否是相对时间 (e.g., "X天前")
    if (text.includes('前') || text.includes('ago')) {
        text = text.replace('前', '').replace(' ago', '').trim();
        const value = parseInt(text) || 0;
        if (text.includes('分钟') || text.includes('minute')) {
            now.setMinutes(now.getMinutes() - value);
        } else if (text.includes('小时') || text.includes('hour')) {
            now.setHours(now.getHours() - value);
        } else if (text.includes('天') || text.includes('day')) {
            now.setDate(now.getDate() - value);
        } else if (text.includes('周') || text.includes('week')) {
            now.setDate(now.getDate() - value * 7);
        } else if (text.includes('月') || text.includes('month')) {
            now.setMonth(now.getMonth() - value);
        } else if (text.includes('年') || text.includes('year')) {
            now.setFullYear(now.getFullYear() - value);
        }
        return now.toISOString();
    }
    
    // 检查是否是绝对日期 (e.g., "2023年10月25日")
    const match = text.match(/(\d{4})年(\d{1,2})月(\d{1,2})日/);
    if (match) {
        const year = parseInt(match[1], 10);
        const month = parseInt(match[2], 10) - 1; // 月份是从0开始的
        const day = parseInt(match[3], 10);
        return new Date(year, month, day).toISOString();
    }

    // 如果两种格式都匹配失败，返回当前时间
    return now.toISOString();
}

// --- DOM Mutation Observer ---
let observer;
function observeDOMChanges() {
  observer = new MutationObserver(mutations => {
    mutations.forEach(mutation => {
      if (mutation.addedNodes.length) {
        scanForVideos();
      }
    });
  });

  observer.observe(document.body, { 
    childList: true,
    subtree: true,
  });
}