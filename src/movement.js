const fs = require('fs')

async function movement(req, res) {
    console.log("Starting mvoement");

    await move();
}

async function move() {
    console.log("launching ahk script")   
}

module.exports = {
    movement
};