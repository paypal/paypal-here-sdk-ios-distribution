chrome.app.runtime.onLaunched.addListener(function() {
    chrome.app.window.create('main.html', {
        'bounds': {
            'width': 600,
            'height': 800
        }
    });
});
