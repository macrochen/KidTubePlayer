// --- 全局状态管理 ---
let selectionModeActive = false;
let selectedVideos = [];
let currentPlatform = '';

// --- 初始化 ---
// 判断当前在哪个平台
if (window.location.hostname.includes('youtube.com')) {
    currentPlatform = 'youtube';
} else if (window.location.hostname.includes('bilibili.com')) {
    currentPlatform = 'bilibili';
}

/**
 * 主切换函数，用于开启或关闭选择模式
 */
function toggleApp() {
  selectionModeActive = !selectionModeActive;
  if (selectionModeActive) {
    console.log(`Importer: 激活选择模式 on ${currentPlatform}`);
    createAppUI();
    scanForVideos();
    observeDOMChanges();
  } else {
    console.log("Importer: 关闭选择模式");
    destroyAppUI();
    if (observer) observer.disconnect();
  }
}

window.toggleApp = toggleApp;

/**
 * 创建插件的用户界面
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
 * 销毁插件的UI
 */
function destroyAppUI() {
  document.getElementById('importer-panel')?.remove();
  document.querySelectorAll('.importer-add-btn').forEach(btn => btn.remove());
}

/**
 * 扫描页面上的视频
 */
function scanForVideos() {
    const selector = currentPlatform === 'youtube'
        ? 'ytd-rich-item-renderer, ytd-video-renderer, ytd-grid-video-renderer'
        : '.bili-video-card'; // Bilibili 的视频卡片选择器
    document.querySelectorAll(selector).forEach(videoEl => addPlusButton(videoEl));
}

/**
 * 为单个视频元素添加“+ 添加”按钮
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
    btn.addEventListener('click', (e) => {
      e.preventDefault();
      e.stopPropagation();
      const videoData = extractVideoData(videoEl);
      if (videoData) {
        addVideoToList(videoData);
        btn.textContent = '✓ 已添加';
        btn.classList.add('added');
        btn.disabled = true;
      } else {
        btn.textContent = '信息不全';
        btn.classList.add('error');
      }
    });
  }
}

/**
 * 数据提取的“总管”函数
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
 * 提取 YouTube 视频数据
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
 * 提取 Bilibili 视频数据
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
    // ... (恢复按钮的逻辑也需要更新以考虑平台)
}

function updateListView() {
  const listEl = document.getElementById('selected-list');
  const countEl = document.getElementById('video-count');
  const exportBtn = document.getElementById('export-json-btn');

  countEl.textContent = selectedVideos.length;

  if (selectedVideos.length === 0) {
    listEl.innerHTML = '<p class="empty-state">尚未选择任何视频</p>';
    exportBtn.classList.add('disabled');
  } else {
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


// --- 辅助函数 ---
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
    text = text.trim();
    if (text.includes('分钟前') || text.includes('小时前') || text.includes('天前')) {
        const value = parseInt(text) || 0;
        if (text.includes('分钟')) now.setMinutes(now.getMinutes() - value);
        if (text.includes('小时')) now.setHours(now.getHours() - value);
        if (text.includes('天')) now.setDate(now.getDate() - value);
        return now.toISOString();
    }
    const match = text.match(/(\d{4})-(\d{1,2})-(\d{1,2})|(\d{1,2})-(\d{1,2})/);
    if (match) {
        const year = parseInt(match[1] || now.getFullYear());
        const month = parseInt(match[2] || match[4]) - 1;
        const day = parseInt(match[3] || match[5]);
        return new Date(year, month, day).toISOString();
    }
    return now.toISOString();
}

// --- DOM 变动监听 ---
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
