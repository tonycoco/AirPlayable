let currentVideoElements = new Set();

function airplay() {
  if (!window.WebKitPlaybackTargetAvailabilityEvent) return;
  if (currentVideoElements.size === 0) return;

  // Find an active video (not paused) or default to the first video in the set
  let activeVideo = null;
  for (let video of currentVideoElements) {
    if (!video.paused) {
      activeVideo = video;
      break;
    }
  }

  // If no active video is found, use the first video in the set
  activeVideo = activeVideo || currentVideoElements.values().next().value;

  // Show the AirPlay target picker
  activeVideo.webkitShowPlaybackTargetPicker();
}

function handleMessage(event) {
  if (event.name === "toolbarItemClicked") {
    airplay();
  }
}

function updateVideoElements() {
  const newVideoElements = new Set(document.getElementsByTagName("video"));
  const isDifferent =
    newVideoElements.size !== currentVideoElements.size ||
    Array.from(newVideoElements).some(
      (video) => !currentVideoElements.has(video)
    );

  if (isDifferent) {
    currentVideoElements = newVideoElements;
    safari.extension.dispatchMessage("videosChanged", {
      count: currentVideoElements.size,
    });
  }
}

safari.self.addEventListener("message", handleMessage);

window.addEventListener("focus", updateVideoElements);

const observer = new MutationObserver(updateVideoElements);
observer.observe(document, { childList: true, subtree: true });
