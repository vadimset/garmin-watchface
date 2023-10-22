import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Weather;
import Toybox.Complications;

class WatchFaceView extends WatchUi.WatchFace {

    private var _screenCenterPoint as Array<Number>;
    private var _showWatchHands as Boolean;
    private var _isAwake as Boolean;
    private var _fullScreenRefresh as Boolean;
    private var _showTimeTickToggle;
    
    private var systemSettings as DeviceSettings;
    private var clockTime as ClockTime;
    private var now as Time.Moment;
    private var currentWeather as CurrentConditions?;

    // Drawables
    private var batteryReferences as Array<BitmapReference>?;
    private var personWalkin as BitmapReference?;
    private var sunriseIcon as BitmapReference?;
    private var floorsIcon as BitmapReference?;
    
    // Layout
    private var battDLabel as Text?;
    private var steppDLabel as Text?;
    private var floorLabel as Text?;
    private var sunriseDLabel as Text?;
    private var sunsetDLabel as Text?;

    // Complications
    private var currentTemp as Number?;
    private var currentTempComplicationId as Complications.Id?;
    private var currentStep as Number?;
    private var currentStepComplicationId as Complications.Id?;
    private var nextSunrise as Number?;
    private var nextSunriseComplicationId as Complications.Id?;
    private var nextSunset as Number?;
    private var nextSunsetComplicationId as Complications.Id?;
    private var currentFloors as Number?;
    private var currentFloorComplicationId as Complications.Id?;

    function initialize() {
        WatchFace.initialize();
        _fullScreenRefresh = true;
        systemSettings = System.getDeviceSettings();
        _screenCenterPoint = [systemSettings.screenWidth / 2, systemSettings.screenHeight / 2] as Array<Number>;
        _showWatchHands = true;
        _isAwake = true;
        clockTime = System.getClockTime();
        now = Time.now() as Time.Moment;
        _showTimeTickToggle = true;

        checkComplications();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));

        battDLabel = View.findDrawableById("battDLabel") as Text;
        steppDLabel = View.findDrawableById("steppDLabel") as Text;
        floorLabel = View.findDrawableById("floorLabel") as Text;
        sunriseDLabel = View.findDrawableById("sunriseDLabel") as Text;
        sunsetDLabel = View.findDrawableById("sunsetDLabel") as Text;
        
        batteryReferences = new Array<BitmapReference>[5];
        batteryReferences[0] = WatchUi.loadResource($.Rez.Drawables.batteryEmpty) as BitmapReference;
        batteryReferences[1] = WatchUi.loadResource($.Rez.Drawables.batteryQuarter) as BitmapReference;
        batteryReferences[2] = WatchUi.loadResource($.Rez.Drawables.batteryHalf) as BitmapReference;
        batteryReferences[3] = WatchUi.loadResource($.Rez.Drawables.batteryThreeQuarters) as BitmapReference;
        batteryReferences[4] = WatchUi.loadResource($.Rez.Drawables.batteryFull) as BitmapReference;

        personWalkin = WatchUi.loadResource($.Rez.Drawables.personWalkin) as BitmapReference;
        sunriseIcon = WatchUi.loadResource($.Rez.Drawables.sunriseIcon) as BitmapReference;
        floorsIcon = WatchUi.loadResource($.Rez.Drawables.floorsIcon) as BitmapReference;
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        subscribeComplications();
        View.onShow();
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        now = Time.now() as Time.Moment;
        clockTime = System.getClockTime();
        _fullScreenRefresh = true;
        currentWeather = Weather.getCurrentConditions();
        dc.clearClip();
        // drawBackgroundPolygon(dc);
        setBatDData();
        setStepData();
        setFloorpData();
        setSunData();
        View.onUpdate(dc);
        drawDateTimePolygon(dc);
        drawTickMarks(dc);
        drawDialNumbers(dc);
        drawTimeLabel(dc);
        drawDateLabel(dc);
        drawWeekDash(dc);
        drawIcons(dc);
        drawSunTriangles(dc);
        drawWatchHands(dc);
        if (_isAwake) {
            drawSecondHand(dc, false);
        }

        _fullScreenRefresh = false;
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
        unsubscribeComplications();
        View.onHide();
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
        _isAwake = true;
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        _isAwake = false;
        WatchUi.requestUpdate();
    }

    private function setBatDData() as Void {
        var battD = System.getSystemStats().batteryInDays.format("%.0f");
        var battDString = Lang.format("$1$д", [battD]);
        battDLabel.setText(battDString);
    }

    private function setStepData() as Void {
        var currentStepString = "-----";
        var zeros = "";
        if (currentStep != null) {
            if (currentStep instanceof Float) {
                currentStepString = (currentStep * 1000).format("%.0f");
            } else {
                currentStepString = currentStep.format("%d");
            }
            // if (currentStep < 10) { zeros = "0000"; } else
            // if (currentStep < 100) { zeros = "000"; } else 
            // if (currentStep < 1000) { zeros = "00"; } else 
            // if (currentStep < 10000) { zeros = "0"; }
        }
        steppDLabel.setText(Lang.format("$1$$2$", [zeros, currentStepString]));
    }

    private function setFloorpData() as Void {
        var currentStepString = "-";
        if (currentFloors != null) {
            currentStepString = currentFloors.format("%d");
        }
        floorLabel.setText(Lang.format("$1$", [currentStepString]));
    }
    
    private function setSunData() as Void {
        if (nextSunrise != null) {
            var hours = Math.floor(nextSunrise / 3600);
            var minutes = Math.floor((nextSunrise - (hours * 3600)) / 60);
            if (minutes < 10) { minutes = Lang.format("0$1$", [minutes]); }
            sunriseDLabel.setText(Lang.format("$1$:$2$", [hours, minutes]));
        }

        if (nextSunset != null) {
            var hours = Math.floor(nextSunset / 3600);
            var minutes = Math.floor((nextSunset - (hours * 3600)) / 60);
            if (minutes < 10) { minutes = Lang.format("0$1$", [minutes]); }
            sunsetDLabel.setText(Lang.format("$1$:$2$", [hours, minutes]));
        }
    }
    
    private function drawSunTriangles(dc as Dc) as Void {
        if (nextSunrise != null) {
            var nextSunriseAngle = (nextSunrise.toFloat() / (60 * 60 * 12)) * Math.PI * 2;
            dc.setColor(0x0055aa, Graphics.COLOR_BLACK);
            dc.fillPolygon(getLeftTriangleMarker(_screenCenterPoint, nextSunriseAngle));
            dc.setColor(0xffaaaa, Graphics.COLOR_BLACK);
            dc.fillPolygon(getRightTriangleMarker(_screenCenterPoint, nextSunriseAngle));
        }

        if (nextSunset != null) {
            var nextSunsetAngle = (nextSunset.toFloat() / (60 * 60 * 12)) * Math.PI * 2;
            dc.setColor(0xff5500, Graphics.COLOR_BLACK);
            dc.fillPolygon(getLeftTriangleMarker(_screenCenterPoint, nextSunsetAngle));
            dc.setColor(0x0055aa, Graphics.COLOR_BLACK);
            dc.fillPolygon(getRightTriangleMarker(_screenCenterPoint, nextSunsetAngle));
        }
    }

    private function drawIcons(dc as Dc) as Void {
        var battD = System.getSystemStats().battery;
        var battDString = Lang.format("$1$d", [battD]);
        if (batteryReferences != null) {
            var batteryBitmap = batteryReferences[4].get() as BitmapResource;
            if(battD < 85) { batteryBitmap = batteryReferences[3].get() as BitmapResource; }
            if(battD < 50) { batteryBitmap = batteryReferences[2].get() as BitmapResource; }
            if(battD < 25) { batteryBitmap = batteryReferences[1].get() as BitmapResource; }
            if(battD < 10) { batteryBitmap = batteryReferences[0].get() as BitmapResource; }
            dc.drawBitmap2(-174, 45, batteryBitmap, {});
        }

        dc.drawBitmap2(0, 105, personWalkin, {});
        dc.drawBitmap2(120, 131, sunriseIcon, {});
        dc.drawBitmap2(50, 105, floorsIcon, {});
    }

    private function drawBackgroundPolygon(dc as Dc) as Void {
        var bcPly = [
            [0, 0], [0, 260], [260, 260], [260, 0]
        ];
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillPolygon(bcPly);
    }

    private function drawDateTimePolygon(dc as Dc) as Void {
        var digitalPoligonm = [
            [45, 158], [215, 158], [215, 190], [185, 218], [75, 218], [45, 190]
        ];
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.fillPolygon(digitalPoligonm);
    }

    private function drawTimeLabel(dc as Dc) as Void {
        var hours = clockTime.hour;
        if (!systemSettings.is24Hour && hours > 12) { hours = hours - 12; }
        var sec = clockTime.sec.format("%02d");
        var hour = Lang.format("$1$", [clockTime.hour.format("%02d")]);
        var minute = Lang.format("$1$", [clockTime.min.format("%02d")]);
        new WatchUi.Text({
            :text=>hour,
            :color=>Graphics.COLOR_BLACK, :font=>Graphics.FONT_NUMBER_MEDIUM,
            :locX=>92,
            :locY=>144, :justification=>Graphics.TEXT_JUSTIFY_CENTER
        }).draw(dc);
         new WatchUi.Text({
            :text=>minute, :color=>Graphics.COLOR_BLACK, :font=>Graphics.FONT_NUMBER_MEDIUM,
            :locX=>168,
            :locY=>144, :justification=>Graphics.TEXT_JUSTIFY_CENTER
        }).draw(dc);
        if (!_isAwake) { _showTimeTickToggle = true; }
        else {_showTimeTickToggle = !_showTimeTickToggle;}
        if(_showTimeTickToggle) {
            new WatchUi.Text({
                :text=>":", :color=>Graphics.COLOR_BLACK, :font=>Graphics.FONT_NUMBER_MEDIUM,
                :locX=>WatchUi.LAYOUT_HALIGN_CENTER,
                :locY=>144, :justification=>Graphics.TEXT_JUSTIFY_CENTER
            }).draw(dc);
        }
    }

    private function drawDateLabel(dc as Dc) as Void {
        var today = Time.today() as Time.Moment;
        var info = Gregorian.info(today, Time.FORMAT_SHORT);
        var months = ["Янв", "Фев", "Мар", "Апр", "Май", "Июн", "Июл", "Авг", "Сен", "Окт", "Ноя", "Дек"];
        var monthNr = info.month -1;
        var dateString = Lang.format("$1$ $2$", [
            info.day.format("%02d"),
            (months[monthNr] as Lang.String),
        ]);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        var text = new WatchUi.Text({
            :text=>dateString,
            :color=>Graphics.COLOR_BLACK,
            :font=>Graphics.FONT_SYSTEM_XTINY,
            :locX=>WatchUi.LAYOUT_HALIGN_CENTER,
            :locY=>198,
            :justification=>Graphics.TEXT_JUSTIFY_CENTER
        });
        text.draw(dc);
    }

    private const smallHashLength = 4;
    private const bigHashLength = 10;
    //! Draws the clock tick marks around the outside edges of the screen.
    //! @param dc Device context
    private function drawTickMarks(dc as Dc) as Void {
        dc.setAntiAlias(true);
        var width = dc.getWidth();
        for (var i = 0; i <= 59; i++) {
            var angle = (i * 6 * Math.PI) / 180;
        }
        for (var i = 0; i <= 59; i++) {
            var angle = (i * 6 * Math.PI) / 180;
            var outerRad = width / 2;
            var innerRad = outerRad - smallHashLength;
            if (i == 0 || i == 15 || i  == 30 || i == 45 || i == 60) {
                innerRad = outerRad - bigHashLength;
                dc.setPenWidth(8);
                var tickPoints = getTickPoints(outerRad, innerRad, angle);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
                dc.drawLine(tickPoints[0], tickPoints[1], tickPoints[2], tickPoints[3]);
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
                dc.fillPolygon(getTriangleTick(_screenCenterPoint, angle));
            } else if(i == 5 || i == 10 || i == 50 || i == 55) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
                dc.fillPolygon(getTriangLongleTick(_screenCenterPoint, angle, 100, 5));
            } else if(i == 20 || i == 40) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
                dc.fillPolygon(getTriangLongleTick(_screenCenterPoint, angle, 105, 5));
            } else if(i == 25 || i == 35) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
                dc.fillPolygon(getTriangLongleTick(_screenCenterPoint, angle, 111, 5));
            }  else {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
                dc.setPenWidth(1);
                var tickPoints = getTickPoints(outerRad, innerRad, angle);
                dc.drawLine(tickPoints[0], tickPoints[1], tickPoints[2], tickPoints[3]);
            }
        }
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
        dc.fillPolygon(getTriangleTick(_screenCenterPoint, 0.0));
    }

    private function getTickPoints(outerRad, innerRad, angle) {
        var sY = outerRad + innerRad * Math.cos(angle);
        var eY = outerRad + outerRad * Math.cos(angle);
        var sX = outerRad + innerRad * Math.sin(angle);
        var eX = outerRad + outerRad * Math.sin(angle);
        return [sX, sY, eX, eY];
    }
    
    private function drawDialNumbers(dc as Dc) as Void {
        var dialTop = getDialText("12", WatchUi.LAYOUT_HALIGN_CENTER, -2);
        dialTop.draw(dc);
        var dialRight = getDialText("3", 235, WatchUi.LAYOUT_VALIGN_CENTER);
        dialRight.draw(dc);
        var dialBottom = getDialText("6", WatchUi.LAYOUT_HALIGN_CENTER, 205);
        dialBottom.draw(dc);
        var dialLeft = getDialText("9", 25, WatchUi.LAYOUT_VALIGN_CENTER);
        dialLeft.draw(dc);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.setPenWidth(1);
        dc.drawLine( 45, _screenCenterPoint[1], 215, _screenCenterPoint[1]);
    }

    private function getDialText(text as String, locX as Number, locY as Number) {
        var boxText = new WatchUi.Text({
            :text=>text,
            :color=>Graphics.COLOR_WHITE,
            :font=>Graphics.FONT_SYSTEM_NUMBER_MILD,
            :locX=>locX,
            :locY=>locY,
            :justification=>Graphics.TEXT_JUSTIFY_CENTER
        });
        return boxText;
    }

    private function drawWeekDash(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.setPenWidth(1);
        var startPoint = 53;
        var endPoint = 207;
        var upperY = 66;
        var lowerY = 82;
        var gap = (endPoint - startPoint) / 7; 
        var middleY = upperY - (lowerY - upperY) / 2 + 6;
        dc.drawLine( startPoint, upperY, endPoint, upperY);
        dc.drawLine( startPoint, lowerY, endPoint, lowerY);
        var drawX = startPoint;
        do {
            dc.drawLine( drawX, upperY, drawX, lowerY);
            drawX += gap;
        }
        while( drawX <= endPoint);
        var weekNames = ["ПН", "ВТ", "СР", "ЧТ", "ПТ", "СБ", "ВС"];
        var weekMapping = [7, 1, 2, 3, 4, 5, 6];
        var weekNamesCoords = new [7];
        var weekNameCoordCalc = startPoint;
        for( var i = 0 ; i < 7 ; i++ ) {
            weekNameCoordCalc += i == 0 ? gap / 2 : gap;
            weekNamesCoords[i] = weekNameCoordCalc;
        }
        var today = Gregorian.info(Time.today(), Time.FORMAT_SHORT);
        var dayOfWeek = today.day_of_week;
        dayOfWeek = weekMapping[dayOfWeek-1];
        for( var i = 0 ; i < weekNames.size() ; i++ ) {
            var weekName = weekNames[i];
            var placeX = weekNamesCoords[i];
            var isActive = i + 1 == dayOfWeek;
            var color = Graphics.COLOR_WHITE;
            if (i >= 5) { color = Graphics.COLOR_RED; }
            if (isActive) {
                color = Graphics.COLOR_BLACK;
                var activePolygonPoints = getActiveDayPolydon(i, startPoint, gap, upperY, lowerY);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
                if (i >= 5) {
                    color = Graphics.COLOR_WHITE;
                    dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK); 
                }
                dc.fillPolygon(activePolygonPoints);
            }
            var weekTxt = getWeekText(weekName, placeX, middleY, color);
            weekTxt.draw(dc);
        }
    }

    private function getActiveDayPolydon(i, startPoint, gap, upperY, lowerY) {
        var gapX = gap * i;
        var leftX = startPoint + gapX + 1;
        var rightX = leftX + gap -1;
        upperY +=1;
        var coords = [
            [leftX, upperY],
            [rightX, upperY],
            [rightX, lowerY],
            [leftX, lowerY],
        ];
        return coords;
    }

    private function getWeekText(text as String, locX as Number, locY as Number, color) {
        var boxText = new WatchUi.Text({
            :text=>text,
            :color=>color,
            :font=>Graphics.FONT_SYSTEM_XTINY,
            :locX=>locX,
            :locY=>locY,
            :justification=>Graphics.TEXT_JUSTIFY_CENTER
        });
        return boxText;
    }

    private function getTriangleTick(
        centerPoint as Array<Number>,
        angle as Float
    ) as Array<Array<Float> > {
        var coords = [[-10, -130], [0, -120], [10, -130]] as Array<Array<Number> >;
        return rotatePoints(centerPoint, coords, angle);
    }
    private function getTriangLongleTick(
        centerPoint as Array<Number>,
        angle as Float,
        height as Number,
        width as Number
    ) as Array<Array<Float> > {
        var coords = [[-width, -130], [-width, -height], [0, -(height - 5)], [width, -height],  [width, -130]] as Array<Array<Number> >;
        return rotatePoints(centerPoint, coords, angle);
    }
      private function getLeftTriangleMarker(centerPoint as Array<Number>, angle as Float) as Array<Array<Float> > {
        var coords =
        [
            [-(16 / 2), -113] as Array<Number>,
            [0, -130] as Array<Number>,
            [0, -113] as Array<Number>,
        ] as Array<Array<Number> >;
        return rotatePoints(centerPoint, coords, angle);
    }

    private function getRightTriangleMarker(centerPoint as Array<Number>, angle as Float) as Array<Array<Float> > {
        var coords =
        [
            [0, -113] as Array<Number>,
            [0, -130] as Array<Number>,
            [16 / 2, -113] as Array<Number>,
        ] as Array<Array<Number> >;
        return rotatePoints(centerPoint, coords, angle);
    }

    // Rotate an array of points around the centerPoint
    private function rotatePoints(
        centerPoint as Array<Number>,
        points as Array<Array<Number> >,
        angle as Float
    ) as Array<Array<Float> > {
        var result = new Array<Array<Float> >[points.size()];
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < points.size(); i++) {
        var x = points[i][0] * cos - points[i][1] * sin + 0.5;
        var y = points[i][0] * sin + points[i][1] * cos + 0.5;

        result[i] = [centerPoint[0] + x, centerPoint[1] + y] as Array<Float>;
        }

        return result;
    }

    private function drawWatchHands(dc as Dc) as Void {
        dc.setAntiAlias(true);
        if (_showWatchHands) {
            var hourHandAngle = (((clockTime.hour % 12) * 60 + clockTime.min) / (12 * 60.0)) * Math.PI * 2;
            var minuteHandAngle = (clockTime.min / 60.0) * Math.PI * 2;
            var hourHandPoints = getHourHandPoints(_screenCenterPoint, hourHandAngle);
            var hourHandLinePoints = getHourHandDashPoints(_screenCenterPoint, hourHandAngle);

            dc.setPenWidth(3);
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
            dc.fillPolygon(hourHandPoints);
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_BLACK);
            dc.fillPolygon(hourHandLinePoints);

            var minuteHandPoints = getMinuteHandPoints( _screenCenterPoint, minuteHandAngle );
            var minuteHandDashPoints = getMinuteHandDashPoints( _screenCenterPoint, minuteHandAngle );
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
            dc.fillPolygon(minuteHandPoints);
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_BLACK);
            dc.fillPolygon(minuteHandDashPoints); 
        }
    }

    private function drawSecondHand(dc as Dc, setClip as Boolean) as Void {
        dc.setAntiAlias(true);
        var secondHandAngle = (clockTime.sec / 60.0) * Math.PI * 2;
        var secondHandPoints = getSecondHandPoints( _screenCenterPoint, secondHandAngle );
        if (setClip) {
            var curClip = getBoundingBox(secondHandPoints);
            var bBoxWidth = curClip[1][0] - curClip[0][0] + 1;
            var bBoxHeight = curClip[1][1] - curClip[0][1] + 1;
            dc.setClip(curClip[0][0], curClip[0][1], bBoxWidth, bBoxHeight);
        }
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_BLACK);
        dc.fillPolygon(secondHandPoints);
    }

    private function getHourHandPoints(
        centerPoint as Array<Number>,
        angle as Float
    ) as Array<Array<Float> > {
        // Map out the coordinates of the watch hand pointing down
        var coords =
        [
            [-(6), -25] as Array<Number>,
            [-(6), -85] as Array<Number>,
            [0, -95] as Array<Number>,
            [6, -85] as Array<Number>,
            [6, -25] as Array<Number>,
            [0, -30] as Array<Number>,
        ] as Array<Array<Number> >;

        return rotatePoints(centerPoint, coords, angle);
    }

    private function getHourHandDashPoints(
        centerPoint as Array<Number>,
        angle as Float
    ) as Array<Array<Float> > {
        // Map out the coordinates of the watch hand pointing down
        var coords =
        [
            [-(2), -70] as Array<Number>,
            [-(2), -80] as Array<Number>,
            [0, -85] as Array<Number>,
            [2, -80] as Array<Number>,
            [2, -70] as Array<Number>,
            [0, -65] as Array<Number>,
        ] as Array<Array<Number> >;

        return rotatePoints(centerPoint, coords, angle);
    }

    private function getMinuteHandPoints(
        centerPoint as Array<Number>,
        angle as Float
    ) as Array<Array<Float> > {
        // Map out the coordinates of the watch hand pointing down
        var coords =
        [ 
            [-(3), -25] as Array<Number>,
            [-(3), -115] as Array<Number>,
            [0, -125] as Array<Number>,
            [3, -115] as Array<Number>,
            [3, -25] as Array<Number>,
            [0, -30] as Array<Number>,
        ] as Array<Array<Number> >;
        return rotatePoints(centerPoint, coords, angle);
    }

    private function getMinuteHandDashPoints(
        centerPoint as Array<Number>,
        angle as Float
    ) as Array<Array<Float> > {
        // Map out the coordinates of the watch hand pointing down
        var coords =
        [
            [-(1), -85] as Array<Number>,
            [-(1), -110] as Array<Number>,
            [0, -115] as Array<Number>,
            [1, -110] as Array<Number>,
            [1, -85] as Array<Number>,
            [0, -90] as Array<Number>,
        ] as Array<Array<Number> >;
        return rotatePoints(centerPoint, coords, angle);
    }

    private function getSecondHandPoints(
        centerPoint as Array<Number>,
        angle as Float
    ) as Array<Array<Float> > {
        // Map out the coordinates of the watch hand pointing down
        var coords =
        [
            [-2, -30] as Array<Number>,
            // [-1, -125] as Array<Number>,
            [0, -130] as Array<Number>,
            // [1, -125] as Array<Number>,
            [2, -30] as Array<Number>,
        ] as Array<Array<Number> >;

        return rotatePoints(centerPoint, coords, angle);
    }

    private function drawPolygon(dc as Dc, points as Array<Array<Float> >) as Void {
        dc.setAntiAlias(true);
        var i;
        for (i = 1; i < points.size(); i++) {
        dc.drawLine(
            points[i - 1][0],
            points[i - 1][1],
            points[i][0],
            points[i][1]
        );
        }
        dc.drawLine(points[i - 1][0], points[i - 1][1], points[0][0], points[0][1]);
    }

    //! Compute a bounding box from the passed in points
    //! @param points Points to include in bounding box
    //! @return The bounding box points
    private function getBoundingBox( points as Array<Array<Number or Float> > ) as Array<Array<Number or Float> > {
        var min = [9999, 9999] as Array<Number>;
        var max = [0, 0] as Array<Number>;
        for (var i = 0; i < points.size(); ++i) {
            if (points[i][0] < min[0]) {min[0] = points[i][0];}
            if (points[i][1] < min[1]) {min[1] = points[i][1];}
            if (points[i][0] > max[0]) {max[0] = points[i][0];}
            if (points[i][1] > max[1]) {max[1] = points[i][1];}
        }
        return [min, max] as Array<Array<Number or Float> >;
    }

    private function checkComplications() as Void {
        var iter = Complications.getComplications();
        var complication = iter.next();
        while (complication != null) {
            if (complication.getType() == Complications.COMPLICATION_TYPE_CURRENT_TEMPERATURE) {
                currentTempComplicationId = complication.complicationId;
            }
            if (complication.getType() == Complications.COMPLICATION_TYPE_STEPS) {
                currentStepComplicationId = complication.complicationId;
            }
            if (complication.getType() == Complications.COMPLICATION_TYPE_FLOORS_CLIMBED) {
                currentFloorComplicationId = complication.complicationId;
            }
            if (complication.getType() == Complications.COMPLICATION_TYPE_SUNRISE) {
                nextSunriseComplicationId = complication.complicationId;
            }
            if (complication.getType() == Complications.COMPLICATION_TYPE_SUNSET) {
                nextSunsetComplicationId = complication.complicationId;
            }
            complication = iter.next();
        }
    }

    private function unsubscribeComplications() as Void {
        Complications.unsubscribeFromAllUpdates();
        Complications.registerComplicationChangeCallback(null);
    }
    
    private function subscribeComplications() as Void {
        Complications.registerComplicationChangeCallback(
            self.method(:onComplicationChanged)
        );
        if (currentTempComplicationId != null) {
            Complications.subscribeToUpdates(currentTempComplicationId);
        }
        if (currentStepComplicationId != null) {
            Complications.subscribeToUpdates(currentStepComplicationId);
        }
        if (currentFloorComplicationId != null) {
            Complications.subscribeToUpdates(currentFloorComplicationId);
        }
        if (nextSunriseComplicationId != null) {
            Complications.subscribeToUpdates(nextSunriseComplicationId);
        }
        if (nextSunsetComplicationId != null) {
            Complications.subscribeToUpdates(nextSunsetComplicationId);
        }
    }

    function onComplicationChanged(complicationId as Complications.Id) as Void {
        var data = Complications.getComplication(complicationId);
        var dataValue = data.value;

        if (complicationId == currentTempComplicationId) {
            if (dataValue != null) {
                currentTemp = dataValue as Lang.Number;
            }
        }
        if (complicationId == currentStepComplicationId) {
            if (dataValue != null) {
                currentStep = dataValue as Lang.Number;
            }
        }
        if (complicationId == currentFloorComplicationId) {
            if (dataValue != null) {
                currentFloors = dataValue as Lang.Number;
            }
        }
        if (complicationId == nextSunriseComplicationId) {
            if (dataValue != null) {
                nextSunrise = dataValue as Lang.Number;
            }
        }

        if (complicationId == nextSunsetComplicationId) {
            if (dataValue != null) {
                nextSunset = dataValue as Lang.Number;
            }
        }
    }
}
