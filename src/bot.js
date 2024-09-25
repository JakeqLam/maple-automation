const {GlobalKeyboardListener} = require("node-global-key-listener");

const  {robot} = require("robotjs");
//utils


//classes
const { mage } = require("./mage.js");

var toggleMovement = false

function activate() {

    console.log("Initializing robot API")

}

const v = new GlobalKeyboardListener();

//Log every key that's pressed.
v.addListener(function (e, down) {
    console.log(
        `${e.name} ${e.state == "DOWN" ? "DOWN" : "UP  "} [${e.rawKey._nameRaw}]`
    );
});

//move mouse in a smooth curve
function moveMouse() {
    // Speed up the mouse.
    robot.setMouseDelay(2);
    
    var twoPI = Math.PI * 2.0;
    var screenSize = robot.getScreenSize();
    var height = (screenSize.height / 2) - 10;
    var width = screenSize.width;
    
    for (var x = 0; x < width; x++)
    {
        y = height * Math.sin((twoPI * x) / width) + height;
        robot.moveMouse(x, y);
    }
}

module.exports = { 
    activate
}