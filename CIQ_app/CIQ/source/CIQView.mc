import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.Attention;

// ------------------------------ GLOBALS ------------------------------
var SOUND_THRESHOLD = 80; // max sound threshold in dB
var NOTIFICATION_DELAY = 15000; // notification delay in ms
var VIBE_DURATION = 2000; // vibration duration in ms

// ----------------------------- DELEGATES -----------------------------
class BackDelegate extends BehaviorDelegate {
    protected var back_page; // page to return to on back
    protected var back_back_page; // back page for that page

    function initialize(_page, _back_page) {
        back_page = _page;
        back_back_page = _back_page;
        BehaviorDelegate.initialize();
    }

    function onBack() {
        if (back_page != null) {
            WatchUi.switchToView(back_page, new BackDelegate(back_back_page, null), WatchUi.SLIDE_IMMEDIATE);
        } else {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }
        return true;
    }
}

// ------------------------------- VIEWS -------------------------------
class SoundDisplay extends WatchUi.View {
    var x, y;
    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
        // Load screen height and width as dynamic resources
        x = dc.getWidth();
        y = dc.getHeight();
    }

    function onShow() as Void {}

    // Update the view every time a new BLE value comes in (see CIQBLE.mc:onCharacteristicChanged)
    function onUpdate(dc as Dc) as Void {
        if (SOUND_LEVEL > SOUND_THRESHOLD) {
            // verify the threshold
            WatchUi.switchToView(new SoundNotification(), new BackDelegate(new SoundDisplay(), null), WatchUi.SLIDE_IMMEDIATE);
        }

        // set background color
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle (0, 0, x, y);

        // set foreground color
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        dc.drawText(x / 2, y / 2-30, Graphics.FONT_MEDIUM, "Current Environment\nSound Levels", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(x / 2, y / 2+80, Graphics.FONT_MEDIUM, Lang.format("$1$ dB", [SOUND_LEVEL]), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function onHide() as Void {}

}

class SensorDisconnected extends WatchUi.View {
    // Called when the sensor disconnects (See CIQBLE.mc:onConnectedStateChanged)
    var x, y;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
        // Load screen height and width as dynamic resources
        x = dc.getWidth();
        y = dc.getHeight();
    }

    function onShow() as Void {
        // Vibrate the watch
        Attention.vibrate([new Attention.VibeProfile(100, VIBE_DURATION)]);
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // set background color
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle (0, 0, x, y);

        // set foreground color
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        dc.drawText(x / 2, y / 2-50, Graphics.FONT_MEDIUM, "Sensor has\ndisconnected.", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(x / 2, y / 2 + 70, Graphics.FONT_SYSTEM_SMALL, "Check if your charge has\nwandered off.", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function onHide() as Void {}

}

class SoundNotification extends WatchUi.View {
    var x, y;
    var timer = new Timer.Timer(); // timer for notification timeout

    function initialize() {
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        // Load screen height and width as dynamic resources
        x = dc.getWidth();
        y = dc.getHeight();
    }

    function onShow() as Void {
        // Vibrate the watch
        Attention.vibrate([new Attention.VibeProfile(100, VIBE_DURATION)]);

        // Start the timer timeout method
        timer.start(method(:notificationDone), NOTIFICATION_DELAY, false);
    }

    // Update the view every time a new BLE value comes in (see CIQBLE.mc:onCharacteristicChanged)
    function onUpdate(dc as Dc) as Void {
        // set background color
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle (0, 0, x, y);

        // set foreground color
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        dc.drawText(x / 2, y / 2 - 50, Graphics.FONT_MEDIUM, Lang.format("Environment\nsound has exceeded\n$1$ dB.", [SOUND_THRESHOLD]), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(x / 2, y / 2 + 80, Graphics.FONT_MEDIUM, "Current sound is", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // change font color
        if (SOUND_LEVEL >= SOUND_THRESHOLD) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(x / 2, y / 2 + 130, Graphics.FONT_MEDIUM, Lang.format("$1$ dB", [SOUND_LEVEL]), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function onHide() as Void {
        timer.stop();
    }


    function notificationDone() {
        // notification has timed out and returning to home page.
        WatchUi.switchToView(new SoundDisplay(), new BackDelegate(null, null), WatchUi.SLIDE_IMMEDIATE);
    }

}
