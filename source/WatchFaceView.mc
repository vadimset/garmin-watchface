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
    private var _weatherIconMap;
    private var _weatherIcons;
    
    private var systemSettings as DeviceSettings;
    private var clockTime as ClockTime;
    private var now as Time.Moment;
    private var currentWeather as CurrentConditions?;

    // Drawables
    private var batteryReferences as Array<BitmapReference>?;
    private var personWalkin as BitmapReference?;
    private var sunriseIcon as BitmapReference?;
    private var floorsIcon as BitmapReference?;
    private var moonPhaseReferences as Array<BitmapReference>?;
    
    // Layout
    private var battDLabel as Text?;
    private var steppDLabel as Text?;
    private var floorLabel as Text?;
    private var sunriseDLabel as Text?;
    private var sunsetDLabel as Text?;
    private var feelsLikeLabel as Text?;
    private var tempLabel as Text?;

    private var currentMoonphase as Number?;
    private var moonphaseLastCalculated as Moment?;

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
        systemSettings = System.getDeviceSettings();
        clockTime = System.getClockTime();
        now = Time.now() as Time.Moment;
        _fullScreenRefresh = true;
        _screenCenterPoint = [systemSettings.screenWidth / 2, systemSettings.screenHeight / 2] as Array<Number>;
        _showWatchHands = true;
        _isAwake = true;
        _showTimeTickToggle = true;

        _weatherIcons = {
            "weatherClear" => WatchUi.loadResource($.Rez.Drawables.weatherClear),
            "partlyCloudy" => WatchUi.loadResource($.Rez.Drawables.partlyCloudy),
            "cloudy" => WatchUi.loadResource($.Rez.Drawables.cloudy),
            "rain" => WatchUi.loadResource($.Rez.Drawables.rain),
            "snow" => WatchUi.loadResource($.Rez.Drawables.snow),
            "windy" => WatchUi.loadResource($.Rez.Drawables.windy),
            "thunder" => WatchUi.loadResource($.Rez.Drawables.thunder),
            "mixed" => WatchUi.loadResource($.Rez.Drawables.mixed),
            "fog" => WatchUi.loadResource($.Rez.Drawables.fog),
            "hail" => WatchUi.loadResource($.Rez.Drawables.hail),
            "thunderRain" => WatchUi.loadResource($.Rez.Drawables.thunderRain),
            "unknown" => WatchUi.loadResource($.Rez.Drawables.unknown),
        };

        _weatherIconMap = {
            // Day icon                 Description
            0 => "weatherClear",  // CONDITION_CLEAR
            1 => "partlyCloudy",  // CONDITION_PARTLY_CLOUDY
            2 => "cloudy",        // CONDITION_MOSTLY_CLOUDY
            3 => "rain",          // CONDITION_RAIN
            4 => "snow",          // CONDITION_SNOW
            5 => "windy",         // CONDITION_WINDY
            6 => "thunder",       // CONDITION_THUNDERSTORMS
            7 => "mixed",         // CONDITION_WINTRY_MIX
            8 => "fog",           // CONDITION_FOG
            9 => "fog",           // CONDITION_HAZY
            10 => "hail",         // CONDITION_HAIL
            11 => "rain",         // CONDITION_SCATTERED_SHOWERS
            12 => "thunderRain",  // CONDITION_SCATTERED_THUNDERSTORMS
            13 => "unknown",      // CONDITION_UNKNOWN_PRECIPITATION
            14 => "rain",         // CONDITION_LIGHT_RAIN
            15 => "rain",         // CONDITION_HEAVY_RAIN
            16 => "snow",         // CONDITION_LIGHT_SNOW
            17 => "snow",         // CONDITION_HEAVY_SNOW
            18 => "mixed",        // CONDITION_LIGHT_RAIN_SNOW
            19 => "mixed",        // CONDITION_HEAVY_RAIN_SNOW
            20 => "cloudy",       // CONDITION_CLOUDY
            21 => "mixed",        // CONDITION_RAIN_SNOW
            22 => "partlyCloudy", // CONDITION_PARTLY_CLEAR
            23 => "partlyCloudy", // CONDITION_MOSTLY_CLEAR
            24 => "rain",         // CONDITION_LIGHT_SHOWERS
            25 => "rain",         // CONDITION_SHOWERS
            26 => "rain",         // CONDITION_HEAVY_SHOWERS
            27 => "rain",         // CONDITION_CHANCE_OF_SHOWERS
            28 => "thunder",      // CONDITION_CHANCE_OF_THUNDERSTORMS
            29 => "fog",          // CONDITION_MIST
            30 => "fog",          // CONDITION_DUST
            31 => "fog",          // CONDITION_DRIZZLE
            32 => "thunder",      // CONDITION_TORNADO
            33 => "fog",          // CONDITION_SMOKE
            34 => "mix",          // CONDITION_ICE
            35 => "fog",          // CONDITION_SAND
            36 => "windy",        // CONDITION_SQUALL
            37 => "fog",          // CONDITION_SANDSTORM
            38 => "fog",          // CONDITION_VOLCANIC_ASH
            39 => "fog",          // CONDITION_HAZE
            40 => "weatherClear", // CONDITION_FAIR
            41 => "windy",        // CONDITION_HURRICANE
            42 => "windy",        // CONDITION_TROPICAL_STORM
            43 => "snow",         // CONDITION_CHANCE_OF_SNOW
            44 => "mixed",        // CONDITION_CHANCE_OF_RAIN_SNOW
            45 => "rain",         // CONDITION_CLOUDY_CHANCE_OF_RAIN
            46 => "snow",         // CONDITION_CLOUDY_CHANCE_OF_SNOW
            47 => "mixed",        // CONDITION_CLOUDY_CHANCE_OF_RAIN_SNOW
            48 => "windy",        // CONDITION_FLURRIES
            49 => "rain",         // CONDITION_FREEZING_RAIN
            50 => "snow",         // CONDITION_SLEET
            51 => "snow",         // CONDITION_ICE_SNOW
            52 => "partlyCloudy", // CONDITION_THIN_CLOUDS
            53 => "unknown",      // CONDITION_UNKNOWN
        };

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
        feelsLikeLabel = View.findDrawableById("feelsLikeLabel") as Text;
        tempLabel = View.findDrawableById("tempLabel") as Text;
        
        batteryReferences = new Array<BitmapReference>[5];
        batteryReferences[0] = WatchUi.loadResource($.Rez.Drawables.batteryEmpty) as BitmapReference;
        batteryReferences[1] = WatchUi.loadResource($.Rez.Drawables.batteryQuarter) as BitmapReference;
        batteryReferences[2] = WatchUi.loadResource($.Rez.Drawables.batteryHalf) as BitmapReference;
        batteryReferences[3] = WatchUi.loadResource($.Rez.Drawables.batteryThreeQuarters) as BitmapReference;
        batteryReferences[4] = WatchUi.loadResource($.Rez.Drawables.batteryFull) as BitmapReference;

        moonPhaseReferences = new Array<BitmapReference>[8];
        moonPhaseReferences[0] = WatchUi.loadResource($.Rez.Drawables.moonphase0) as BitmapReference;
        moonPhaseReferences[1] = WatchUi.loadResource($.Rez.Drawables.moonphase1) as BitmapReference;
        moonPhaseReferences[2] = WatchUi.loadResource($.Rez.Drawables.moonphase2) as BitmapReference;
        moonPhaseReferences[3] =  WatchUi.loadResource($.Rez.Drawables.moonphase3) as BitmapReference;
        moonPhaseReferences[4] = WatchUi.loadResource($.Rez.Drawables.moonphase4) as BitmapReference;
        moonPhaseReferences[5] = WatchUi.loadResource($.Rez.Drawables.moonphase5) as BitmapReference;
        moonPhaseReferences[6] = WatchUi.loadResource($.Rez.Drawables.moonphase6) as BitmapReference;
        moonPhaseReferences[7] = WatchUi.loadResource($.Rez.Drawables.moonphase7) as BitmapReference;

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
        setWeatherData();

        View.onUpdate(dc);
        
        drawDateTimePolygon(dc);
        drawTickMarks(dc);
        drawDialNumbers(dc);
        drawTimeLabel(dc);
        drawDateLabel(dc);
        drawWeekDash(dc);
        drawIcons(dc);
        drawMoonPhase(dc);
        drawSunTriangles(dc);
        if(_showWatchHands) { drawWatchHands(dc); }
        if (_isAwake && _showWatchHands) { drawSecondHand(dc, false); }

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

    public function toggleWatchHands() as Void {
        _showWatchHands = !_showWatchHands;
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

    private function setWeatherData() as Void {
        if (currentWeather == null) {
            feelsLikeLabel.setText("--°");
            tempLabel.setText("--°");
        }

        feelsLikeLabel.setText( Lang.format("$1$°", [currentWeather.feelsLikeTemperature]));
        tempLabel.setText(Lang.format("$1$°", [currentWeather.temperature]));
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
        dc.drawBitmap2(-5, 107, personWalkin, {});
        dc.drawBitmap2(145, 86, floorsIcon, {});
        dc.drawBitmap2(120, 131, sunriseIcon, {});
        var weatherIconString = _weatherIconMap[currentWeather.condition];
        if(weatherIconString) {
            var icon = _weatherIcons[weatherIconString];
            dc.drawBitmap2(70, 99, icon, {});
        }
    }

    private function drawMoonPhase(dc as Dc) as Void {
        if (currentMoonphase == null || (moonphaseLastCalculated != null && now.compare(moonphaseLastCalculated) > 3600)) {
            // Moonphase outdated or not available
            var utcInfo = Gregorian.utcInfo(now, Time.FORMAT_SHORT);
            currentMoonphase = getMoonPhase(
                utcInfo.year,
                utcInfo.month,
                utcInfo.day,
                utcInfo.hour
            );
            moonphaseLastCalculated = now;
        }
        if (moonPhaseReferences != null) {
        var moonPhaseBitmap = moonPhaseReferences[currentMoonphase].get() as BitmapResource;
        dc.drawBitmap2(120, 107, moonPhaseBitmap, {});
        }
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
            [45, 155], [215, 155], [215, 190], [180, 217], [80, 217], [45, 190]
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

    //! Draws the clock tick marks around the outside edges of the screen.
    //! @param dc Device context
    private function drawTickMarks(dc as Dc) as Void {
        dc.setAntiAlias(true);
        var width = dc.getWidth();
        var outerRad = width / 2;
        var innerRad = outerRad - 4;
        var innerRadbig = outerRad - 10;
        for (var i = 0; i <= 118; i++) {
            var angle = (i * 3 * Math.PI) / 180;
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.setPenWidth(1);
            var tickPoints = getTickPoints(width, outerRad, innerRad, angle);
            dc.drawLine(tickPoints[0], tickPoints[1], tickPoints[2], tickPoints[3]);
        }
        for (var i = 0; i <= 59; i++) {
            var angle = (i * 6 * Math.PI) / 180;
            
            if (i == 0 || i == 15 || i  == 30 || i == 45 || i == 60) {
                
                dc.setPenWidth(8);
                var tickPoints = getTickPoints(width, outerRad, innerRadbig, angle);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
                dc.drawLine(tickPoints[0], tickPoints[1], tickPoints[2], tickPoints[3]);
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
                dc.fillPolygon(getTriangleTick(_screenCenterPoint, angle));
            } else if(i == 5 || i == 55) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
                dc.fillPolygon(getTriangLongleTick(_screenCenterPoint, angle, 100, 5));
            } else if(i == 20 || i == 40 || i == 10 || i == 50) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
                dc.fillPolygon(getTriangLongleTick(_screenCenterPoint, angle, 105, 5));
            } else if(i == 25 || i == 35) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
                dc.fillPolygon(getTriangLongleTick(_screenCenterPoint, angle, 109, 5));
            }  else {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
                dc.setPenWidth(1);
                var gap = 10;
                var tickPoints = getTickPoints(width, (outerRad - gap), (innerRad - gap), angle);
                dc.drawLine(tickPoints[0], tickPoints[1], tickPoints[2], tickPoints[3]);
            }
        }
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
        dc.fillPolygon(getTriangleTick(_screenCenterPoint, 0.0));
    }

    private function getTickPoints(width, outerRad, innerRad, angle) {
        width /= 2;
        var sY = width + innerRad * Math.cos(angle);
        var sX = width + innerRad * Math.sin(angle);
        
        var eY = width + outerRad * Math.cos(angle);
        var eX = width + outerRad * Math.sin(angle);
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
        var startPoint = 49;
        var endPoint = 210;
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
            [-(3), -105] as Array<Number>,
            [0, -115] as Array<Number>,
            [3, -105] as Array<Number>,
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
            [-(1), -75] as Array<Number>,
            [-(1), -100] as Array<Number>,
            [0, -105] as Array<Number>,
            [1, -100] as Array<Number>,
            [1, -75] as Array<Number>,
            [0, -65] as Array<Number>,
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

    private function getMoonPhase(
        year as Number,
        mon as Number,
        day as Number,
        hour as Number
    ) as Number {
        /*
        calculates the moon phase (0-7), accurate to 1 segment.
        0 = > new moon.
        4 => full moon.
        implementation from sffjunkie/astral
        */

        var jd = getJulianDay(year, mon, day, hour);
        // System.println("Julian Day: " + jd.format("%f"));

        var dt = Math.pow(jd - 2382148.0, 2) / (41048480.0 * 86400.0);
        var t = (jd + dt - 2451545.0) / 36525.0;
        var t2 = Math.pow(t, 2);
        var t3 = Math.pow(t, 3);

        var d = 297.85 + 445267.1115 * t - 0.00163 * t2 + t3 / 545868.0;
        while (d > 360.0) {
        d -= 360.0;
        }
        d = Math.toRadians(d);

        var m = 357.53 + 35999.0503 * t;
        while (m > 360.0) {
        m -= 360.0;
        }
        m = Math.toRadians(m);

        var m1 = 134.96 + 477198.8676 * t + 0.008997 * t2 + t3 / 69699.0;
        while (m1 > 360.0) {
        m1 -= 360.0;
        }
        m1 = Math.toRadians(m1);

        var elong = Math.toDegrees(d) + 6.29 * Math.sin(m1);
        elong -= 2.1 * Math.sin(m);
        elong += 1.27 * Math.sin(2.0 * d - m1);
        elong += 0.66 * Math.sin(2.0 * d);
        while (elong > 360.0) {
        elong -= 360.0;
        }

        var moon = ((elong + 6.43) / 360.0) * 28.0;
        // System.println("Moon Phase: " + moon.format("%f"));
        return Math.round(moon / 4.0).toNumber();
    }

    private function getJulianDay(
        y as Number,
        m as Number,
        d as Number,
        h as Number
    ) as Float {
        var day_fraction = h.toFloat() / 24.0;

        if (m <= 2) {
            y -= 1;
            m += 12;
        }

        var a = (y.toFloat() / 100.0).toNumber();
        var b = 2 - a + (a.toFloat() / 4).toNumber();

        return (
            (365.25 * (y + 4716)).toNumber() +
            (30.6001 * (m + 1)).toNumber() +
            d.toFloat() +
            day_fraction +
            b -
            1524.5
        );
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
