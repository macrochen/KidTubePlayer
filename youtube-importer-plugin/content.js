// --- 全局状态管理 ---
let selectionModeActive = false;
let selectedVideos = [];

// --- 主应用容器 ---
let appContainer = null;

/**
 * 主切换函数，用于开启或关闭选择模式
 */
function toggleApp() {
  selectionModeActive = !selectionModeActive;
  if (selectionModeActive) {
    console.log("YouTube Importer: 激活选择模式");
    createAppUI();
    scanForVideos();
    // 使用 MutationObserver 监听动态加载的视频
    observeDOMChanges();
  } else {
    console.log("YouTube Importer: 关闭选择模式");
    destroyAppUI();
    // 停止监听
    if (observer) {
      observer.disconnect();
    }
  }
}

// 将主切换函数暴露到 window 对象，以便 background.js 调用
window.toggleApp = toggleApp;

/**
 * 创建插件的用户界面 (右下角的面板)
 */
function createAppUI() {
  if (document.getElementById('yt-importer-panel')) return;

  appContainer = document.createElement('div');
  appContainer.id = 'yt-importer-panel';
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

  // 添加事件监听
  document.getElementById('export-json-btn').addEventListener('click', exportJSON);
  document.getElementById('close-panel-btn').addEventListener('click', toggleApp);
}

/**
 * 销毁插件的UI
 */
function destroyAppUI() {
  // 移除面板
  const panel = document.getElementById('yt-importer-panel');
  if (panel) {
    panel.remove();
  }
  // 移除所有添加按钮
  document.querySelectorAll('.yt-importer-add-btn').forEach(btn => btn.remove());
}

/**
 * 扫描页面上已存在的视频并添加“添加”按钮
 */
function scanForVideos() {
  // YouTube 使用不同的标签来渲染视频，我们需要覆盖几种常见的情况
  const videoElements = document.querySelectorAll('ytd-rich-item-renderer, ytd-video-renderer, ytd-grid-video-renderer');
  videoElements.forEach(videoEl => addPlusButton(videoEl));
}

/**
 * 为单个视频元素添加“+ 添加”按钮
 * @param {HTMLElement} videoEl - 视频的DOM元素
 */
function addPlusButton(videoEl) {
  // 防止重复添加
  if (videoEl.querySelector('.yt-importer-add-btn')) return;

  const btn = document.createElement('button');
  btn.className = 'yt-importer-add-btn';
  btn.textContent = '+ 添加';
  
  // 将按钮插入到缩略图容器中，这样它会覆盖在图片上
  const thumbnailContainer = videoEl.querySelector('#thumbnail');
  if (thumbnailContainer) {
    thumbnailContainer.style.position = 'relative'; // 确保按钮可以正确定位
    thumbnailContainer.appendChild(btn);

    btn.addEventListener('click', (e) => {
      e.preventDefault();
      e.stopPropagation(); // 阻止点击事件冒泡，防止意外跳转
      
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
 * 从视频元素中提取所需数据
 * @param {HTMLElement} videoEl 
 * @returns {object|null} 包含视频信息的对象，如果失败则返回null
 */
function extractVideoData(videoEl) {
  try {
    const titleLink = videoEl.querySelector('#video-title-link') || videoEl.querySelector('#video-title');
    const metadataBlock = videoEl.querySelector('#metadata-line');
    const channelNameEl = videoEl.querySelector('ytd-channel-name #text');
    // 关键修复：使用更稳定、更现代的选择器来抓取头像图片
    const authorAvatarEl = videoEl.querySelector('img.yt-spec-avatar-shape__image');

    // 1. 获取视频ID
    const videoId = titleLink.href.split('v=')[1].split('&')[0];

    // 2. 获取标题
    const title = titleLink.getAttribute('title');

    // 3. 获取作者
    const author = channelNameEl.textContent.trim();
    
    // 4. 获取作者头像 URL
    const authorAvatarURL = authorAvatarEl ? authorAvatarEl.src : null;

    // 5. 获取播放量和上传日期
    const metadataSpans = metadataBlock.querySelectorAll('span');
    const viewCountText = metadataSpans[0] ? metadataSpans[0].textContent : '0';
    const uploadDateText = metadataSpans[1] ? metadataSpans[1].textContent : '现在';

    const viewCount = parseViews(viewCountText);
    const uploadDate = parseDate(uploadDateText);

    // 在返回的对象中包含头像 URL
    return { id: videoId, title, author, viewCount, uploadDate, authorAvatarURL };
  } catch (error) {
    console.error("数据提取失败:", error, videoEl);
    return null;
  }
}

/**
 * 将提取的视频添加到已选列表
 * @param {object} videoData 
 */
function addVideoToList(videoData) {
  // 检查是否已存在
  if (selectedVideos.some(v => v.id === videoData.id)) return;

  selectedVideos.push(videoData);
  updateListView();
}

/**
 * 从已选列表中移除视频
 * @param {string} videoId 
 */
function removeVideoFromList(videoId) {
  selectedVideos = selectedVideos.filter(v => v.id !== videoId);
  updateListView();
  
  // 恢复页面上对应的添加按钮
  const videoLink = document.querySelector(`a[href*="/watch?v=${videoId}"]`);
  if (videoLink) {
    const videoEl = videoLink.closest('ytd-rich-item-renderer, ytd-video-renderer, ytd-grid-video-renderer');
    if (videoEl) {
      const btn = videoEl.querySelector('.yt-importer-add-btn');
      if (btn) {
        btn.textContent = '+ 添加';
        btn.classList.remove('added');
        btn.disabled = false;
      }
    }
  }
}

/**
 * 更新右下角面板的视图
 */
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
      <div class="list-item" data-id="${v.id}">
        <span>${v.title}</span>
        <button class="remove-btn">×</button>
      </div>
    `).join('');
    exportBtn.classList.remove('disabled');

    // 为新的删除按钮添加事件监听
    listEl.querySelectorAll('.remove-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        const videoId = btn.parentElement.getAttribute('data-id');
        removeVideoFromList(videoId);
      });
    });
  }
}

/**
 * 导出 JSON 文件
 */
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

/**
 * 解析观看次数字符串
 * @param {string} text e.g., "15万次观看"
 * @returns {number}
 */
function parseViews(text) {
    text = text.toLowerCase().replace(/,/g, '').replace('次观看', '').replace(' views', '').trim();
    let number = parseFloat(text);
    if (text.includes('万') || text.includes('k')) {
        number *= 10000;
    } else if (text.includes('百万') || text.includes('m')) {
        number *= 1000000;
    } else if (text.includes('亿') || text.includes('b')) {
        number *= 1000000000;
    }
    return Math.round(number);
}

/**
 * 解析相对时间或绝对时间字符串
 * @param {string} text e.g., "11小时前" or "2023年10月25日"
 * @returns {string} ISO 8601 format date string (e.g., "2024-07-21T12:30:00.000Z")
 */
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
